import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:collection';
import 'package:flutter/cupertino.dart';
import 'package:fog_gen_new/core/utils/packets.dart';
import 'package:logger/logger.dart';

import '../../core/utils/application_class.dart';

class SocketRepository {
  final _app = Application();
  final _logger = Logger();

  // Stop flag for shutdown
  bool _isStopped = false;

  // Main queue
  final Queue<_QueuedRequest> _requestQueue = Queue();
  bool _isProcessingQueue = false;

  // Connection health tracking
  int _consecutiveFailures = 0;

  // ================================
  // QUEUE REQUEST
  // ================================
  Future<String> _queueRequest(String packet, {bool isPriority = false}) async {
    if (_isStopped) {
      // If stopped, just return null or empty to avoid crashing UI logic expecting a future
      return Future.error(Exception("SocketRepository is stopped"));
    }

    final completer = Completer<String>();
    final request = _QueuedRequest(
      packet: packet,
      completer: completer,
      isPriority: isPriority,
      timestamp: DateTime.now(),
    );

    final packetId = Packets.getPacketId(packet);

    _logger.i(
      "📥 QUEUED → packetId=$packetId | priority=$isPriority | queueSize=${_requestQueue.length + 1}",
    );

    if (isPriority) {
      // Insert priority packets at the front of the line (after other priority packets)
      final index = _requestQueue.toList().indexWhere((r) => !r.isPriority);
      if (index == -1) {
        _requestQueue.addLast(request);
      } else {
        final list = _requestQueue.toList();
        list.insert(index, request);
        _requestQueue
          ..clear()
          ..addAll(list);
      }
    } else {
      _requestQueue.addLast(request);
    }

    if (!_isProcessingQueue) _processQueue();

    return completer.future;
  }

  // ================================
  // PROCESS QUEUE
  // ================================
  Future<void> _processQueue() async {
    if (_isProcessingQueue) return;
    _isProcessingQueue = true;

    while (_requestQueue.isNotEmpty) {
      if (_isStopped) {
        _logger.w("⛔ Queue stopped by user/system");
        break;
      }

      final request = _requestQueue.removeFirst();
      final packetId = Packets.getPacketId(request.packet);

      try {
        _logger.d(
          "▶️ PROCESSING → packetId=$packetId | remaining=${_requestQueue.length}",
        );

        // Execute the transaction
        final response = await _executeTransaction(request.packet);

        _consecutiveFailures = 0;

        if (!request.completer.isCompleted) {
          request.completer.complete(response);
        }

        _logger.i("✅ RESPONSE OK → packetId=$packetId");

        // Small delay between packets to prevent flooding the hardware
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        _consecutiveFailures++;
        _logger.e("❌ RESPONSE FAILED → packetId=$packetId | error=$e");

        if (!request.completer.isCompleted) {
          request.completer.completeError(e);
        }

        // On error, wait a bit longer before trying the next item in queue
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }

    _isProcessingQueue = false;
    _logger.d("✅ Queue empty");
  }

  // ================================
  // EXECUTE SOCKET TRANSACTION
  // ================================
  Future<String> _executeTransaction(String packet) async {
    if (_isStopped) throw Exception("SocketRepository is stopped");

    final packetId = Packets.getPacketId(packet);
    Socket? socket;
    Timer? timeoutTimer;
    final completer = Completer<String>();

    // Prepare connection targets (Static IP first, then Local IP)
    final targets = <_ConnectionTarget>[
      if (_app.mStaticIPAddress?.isNotEmpty == true &&
          (_app.mStaticPortNumber ?? 0) > 0)
        _ConnectionTarget(
          _app.mStaticIPAddress!,
          _app.mStaticPortNumber!,
          isStatic: true,
        ),
      if (_app.mIPAddress?.isNotEmpty == true && (_app.mPortNumber ?? 0) > 0)
        _ConnectionTarget(_app.mIPAddress!, _app.mPortNumber!, isStatic: false),
    ];

    for (final t in targets) {
      try {
        _logger.i("🌐 CONNECT → ${t.ip}:${t.port} | packetId=$packetId");

        socket = await Socket.connect(
          t.ip,
          t.port,
          timeout: const Duration(seconds: 4),
        );

        // --- FIX: BROKEN PIPE HANDLING ---
        try {
          _logger.d("📤 SEND → $packet");
          socket.write(packet);
          await socket.flush();
        } catch (e) {
          _logger.e("⚠️ WRITE FAILED (Broken Pipe?) → $e");
          socket.destroy();
          continue; // Try next target if write fails
        }

        // Setup Timeout
        timeoutTimer = Timer(const Duration(seconds: 4), () {
          if (!completer.isCompleted) {
            _logger.w("⏱️ TIMEOUT → packetId=$packetId | ${t.ip}:${t.port}");
            completer.completeError(TimeoutException("Response Timeout"));
            socket?.destroy();
          }
        });

        // Listen for data
        socket.listen(
              (data) {
            final response = utf8.decode(data).trim();
            _logger.i("📥 RECEIVE ← ${t.ip}:${t.port} | response=$response");

            if (!completer.isCompleted) {
              timeoutTimer?.cancel();
              completer.complete(response);
            }
            // We got our answer, we can close the socket now
            socket?.destroy();
          },
          onError: (e) {
            _logger.e("🔴 SOCKET ERROR → $e");
            if (!completer.isCompleted) {
              // Don't fail immediately, maybe the other target works?
              // But for this specific socket connection, it's done.
            }
          },
          onDone: () {
            // _logger.d("🔌 SOCKET CLOSED → ${t.ip}:${t.port}");
          },
        );

        return await completer.future;
      } catch (e) {
        socket?.destroy();
        timeoutTimer?.cancel();
        _logger.w("⚠️ CONNECT FAILED → ${t.ip}:${t.port} | $e");
        // Loop to next target
      }
    }

    throw Exception("All connection attempts failed");
  }

  // ================================
  // PUBLIC APIS
  // ================================
  Future<String> sendPacketSR1(String packet, {bool isPriority = false}) {
    return _queueRequest(packet, isPriority: isPriority);
  }

  Future<String> sendPacketSB2(String packet, {bool isPriority = false}) {
    return _queueRequest(packet, isPriority: isPriority);
  }

  /// Sends a disconnect packet immediately, bypassing the main queue to ensure
  /// it goes out even if the queue is busy or paused.
  Future<void> sendDisconnectPacket() async {
    // 1. Prepare targets
    final targets = <_ConnectionTarget>[];
    if (_app.mStaticIPAddress?.isNotEmpty == true &&
        (_app.mStaticPortNumber ?? 0) > 0) {
      targets.add(
        _ConnectionTarget(
          _app.mStaticIPAddress!,
          _app.mStaticPortNumber!,
          isStatic: true,
        ),
      );
    }
    if (_app.mIPAddress?.isNotEmpty == true && (_app.mPortNumber ?? 0) > 0) {
      targets.add(
        _ConnectionTarget(_app.mIPAddress!, _app.mPortNumber!, isStatic: false),
      );
    }

    debugPrint(
      "[Disconnect] Initiating disconnect sequence. Targets=${targets.length}",
    );

    // 2. Iterate and try to send
    for (final t in targets) {
      Socket? socket;
      try {
        debugPrint(
          "[Disconnect] Attempting → ${t.isStatic ? 'STATIC' : 'LOCAL'} (${t.ip}:${t.port})",
        );

        socket = await Socket.connect(
          t.ip,
          t.port,
          timeout: const Duration(seconds: 2),
        );

        final packet = Packets.disconnectPacket();
        debugPrint("[Disconnect] Sending packet → $packet");

        // FIX: Wrap write in try-catch to prevent crash if socket closes immediately
        try {
          socket.write(packet);
          await socket.flush();
        } catch (writeError) {
          debugPrint("[Disconnect] Write failed (Broken Pipe?): $writeError");
          socket.destroy();
          continue; // Try next target
        }

        // FIX: Give a tiny delay for bytes to hit the wire before destroying
        await Future.delayed(const Duration(milliseconds: 50));

        debugPrint(
          "[Disconnect] Disconnect packet sent successfully → ${t.ip}:${t.port}",
        );
        socket.destroy();
        return; // Success, exit
      } catch (e) {
        debugPrint(
          "[Disconnect] Failed for ${t.isStatic ? 'STATIC' : 'LOCAL'} (${t.ip}:${t.port}) → $e",
        );
        socket?.destroy();
      }
    }

    debugPrint("[Disconnect] All disconnect attempts failed.");
  }

  // ================================
  // STOP EVERYTHING (USED ON BACK PRESS)
  // ================================
  void stopAllActivity() {
    _logger.w("🛑 STOPPING ALL SOCKET ACTIVITY");

    _isStopped = true;
    _isProcessingQueue = false;

    // Cancel all queued pending responses
    clearQueue();

    _consecutiveFailures = 0;
  }

  void clearQueue() {
    while (_requestQueue.isNotEmpty) {
      final req = _requestQueue.removeFirst();
      if (!req.completer.isCompleted) {
        // FIX: Don't throw exception, just complete with null or custom message
        // to prevent red screen errors in logs during navigation
        req.completer.completeError("Request cancelled: Socket Stopped");
      }
    }
  }

  // ================================
  // STATUS HELPERS
  // ================================
  int get queueSize => _requestQueue.length;
  bool get isProcessing => _isProcessingQueue;
  int get consecutiveFailures => _consecutiveFailures;
}

// ================================
// INTERNAL MODELS
// ================================
class _QueuedRequest {
  final String packet;
  final Completer<String> completer;
  final bool isPriority;
  final DateTime timestamp;

  _QueuedRequest({
    required this.packet,
    required this.completer,
    required this.isPriority,
    required this.timestamp,
  });
}

class _ConnectionTarget {
  final String ip;
  final int port;
  final bool isStatic;

  _ConnectionTarget(this.ip, this.port, {required this.isStatic});
}