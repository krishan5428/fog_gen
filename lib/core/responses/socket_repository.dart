import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:collection';
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
  bool _isInCooldown = false;

  // ================================
  // QUEUE REQUEST
  // ================================
  Future<String> _queueRequest(String packet, {bool isPriority = false}) async {
    if (_isStopped) {
      return Future.error(Exception("SocketRepository is stopped"));
    }

    final completer = Completer<String>();
    final request = _QueuedRequest(
      packet: packet,
      completer: completer,
      isPriority: isPriority,
      timestamp: DateTime.now(),
    );

    if (isPriority) {
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

    _logger.d("🐛 Request queued | Size=${_requestQueue.length} | Priority=$isPriority");

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

      // ✔ IMPORTANT: STOP EVERYTHING if stop flag is true
      if (_isStopped) {
        _logger.w("⛔ Queue processor stopped — exiting loop");
        _isProcessingQueue = false;
        return;
      }

      if (_isInCooldown) {
        _logger.w("⚠️ Cooling down after repeated failures...");
        await Future.delayed(const Duration(milliseconds: 500));
        _isInCooldown = false;
      }

      final request = _requestQueue.removeFirst();

      try {
        _logger.d("▶️ Processing request (${_requestQueue.length} left)");

        final response = await _executeTransaction(request.packet);

        _consecutiveFailures = 0;

        if (!request.completer.isCompleted) {
          request.completer.complete(response);
        }

        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        _consecutiveFailures++;
        _logger.e("❌ Request failed ($e) | Failure count: $_consecutiveFailures");

        if (!request.completer.isCompleted) {
          request.completer.completeError(e);
        }

        if (_consecutiveFailures >= 3) {
          _isInCooldown = true;
          _logger.w("🕒 Entering cooldown mode");
          await Future.delayed(const Duration(milliseconds: 500));
        } else {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }
    }

    _isProcessingQueue = false;
    _logger.d("✅ Queue processing complete");
  }

  // ================================
  // EXECUTE SOCKET TRANSACTION
  // ================================
  Future<String> _executeTransaction(String packet) async {
    if (_isStopped) throw Exception("SocketRepository is stopped");

    final completer = Completer<String>();
    Socket? socket;
    Timer? timeoutTimer;

    final staticIp = _app.mStaticIPAddress;
    final staticPort = _app.mStaticPortNumber ?? 0;

    final localIp = _app.mIPAddress;
    final localPort = _app.mPortNumber ?? 0;

    final List<_ConnectionTarget> tryTargets = [];

    if (staticIp != null && staticIp.isNotEmpty && staticPort > 0) {
      tryTargets.add(_ConnectionTarget(staticIp, staticPort, isStatic: true));
    }
    if (localIp != null && localIp.isNotEmpty && localPort > 0) {
      tryTargets.add(_ConnectionTarget(localIp, localPort, isStatic: false));
    }

    if (tryTargets.isEmpty) {
      throw Exception("No IP/Port available");
    }

    for (final target in tryTargets) {

      // ✔ STOP CHECK
      if (_isStopped) throw Exception("SocketRepository is stopped");

      try {
        _logger.i("🌐 Connecting to ${target.ip}:${target.port}");

        socket = await Socket.connect(
          target.ip,
          target.port,
          timeout: const Duration(seconds: 5),
        );

        socket.setOption(SocketOption.tcpNoDelay, true);

        timeoutTimer = Timer(const Duration(seconds: 4), () {
          if (!completer.isCompleted) {
            completer.completeError(TimeoutException("Timeout waiting for panel"));
            socket?.destroy();
          }
        });

        socket.listen(
              (data) {
            if (_isStopped) {
              if (!completer.isCompleted) {
                completer.completeError(Exception("Stopped — response ignored"));
              }
              socket?.destroy();
              return;
            }

            final response = utf8.decode(data).trim();
            if (!completer.isCompleted) {
              timeoutTimer?.cancel();
              completer.complete(response);
            }
          },
          onError: (err) {
            if (!completer.isCompleted) completer.completeError(err);
          },
          onDone: () {
            if (!completer.isCompleted) {
              completer.completeError(Exception("Connection closed early"));
            }
          },
          cancelOnError: true,
        );

        socket.write(packet);
        await socket.flush();

        return await completer.future;
      } catch (e) {
        timeoutTimer?.cancel();
        socket?.destroy();
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

  Future<void> sendDisconnectPacket() async {
    final staticIp = _app.mStaticIPAddress;
    final staticPort = _app.mStaticPortNumber ?? 0;

    final localIp = _app.mIPAddress;
    final localPort = _app.mPortNumber ?? 0;

    final targets = <_ConnectionTarget>[];

    if (staticIp != null && staticIp.isNotEmpty && staticPort > 0) {
      targets.add(_ConnectionTarget(staticIp, staticPort, isStatic: true));
    }
    if (localIp != null && localIp.isNotEmpty && localPort > 0) {
      targets.add(_ConnectionTarget(localIp, localPort, isStatic: false));
    }

    for (final t in targets) {
      try {
        final socket = await Socket.connect(
          t.ip,
          t.port,
          timeout: const Duration(seconds: 2),
        );
        socket.write("S*1234#W#013*E");
        await socket.flush();
        socket.destroy();
        return;
      } catch (_) {}
    }
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

    _isInCooldown = false;
    _consecutiveFailures = 0;
  }

  void clearQueue() {
    while (_requestQueue.isNotEmpty) {
      final req = _requestQueue.removeFirst();
      if (!req.completer.isCompleted) {
        req.completer.completeError(Exception("Queue cleared"));
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
