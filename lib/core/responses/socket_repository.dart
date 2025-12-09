import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:logger/logger.dart';

import '../utils/application_class.dart';

/// Manages communication with the panel using a stateless, transactional socket model.
/// Each command performs a full connect -> send -> receive -> disconnect cycle.
class SocketRepository {
  final _app = Application();
  final _logger = Logger();

  /// Executes a full send/receive transaction with the panel.
  /// Returns the panel's string response. Throws an exception on timeout or connection error.
  Future<String> _executeTransaction(String packet) async {
    final completer = Completer<String>();
    Socket? socket;

    try {
      final ip = _app.mIPAddress;
      final port = _app.mPortNumber ?? 0;
      if (ip == null || port == 0) throw Exception("IP/Port not set.");

      _logger.i("Connecting to $ip:$port for new transaction...");
      socket = await Socket.connect(
        ip,
        port,
        timeout: const Duration(seconds: 20),
      );
      _logger.d("Connected. Sending: $packet");

      socket.listen(
            (data) {
          final response = utf8.decode(data).trim();
          _logger.d("Received: $response");
          if (!completer.isCompleted) completer.complete(response);
        },
        onError: (error) {
          if (!completer.isCompleted) completer.completeError(error);
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.completeError(
              Exception("Connection closed before response."),
            );
          }
        },
        cancelOnError: true,
      );

      socket.write(packet);
      await socket.flush();

      // Wait for the response
      final response = await completer.future;
      return response;
    } catch (e) {
      _logger.e("Socket transaction failed: $e");
      throw Exception("Panel connection failed: $e");
    } finally {
      // Always close socket
      socket?.destroy();
    }
  }

  /// Send packet for SR1 panel
  Future<String> sendPacketSR1(String packet) {
    debugPrint('reconnectResponse');
    return _executeTransaction(packet);
  }

  /// Send disconnect packet (fire and forget)
  Future<void> sendDisconnectPacket() async {
    debugPrint("sendDisconnectPacket: send");
    try {
      final ip = _app.mIPAddress;
      final port = _app.mPortNumber ?? 0;
      if (ip == null || port == 0) return;
      final socket = await Socket.connect(
        ip,
        port,
        timeout: const Duration(seconds: 5),
      );
      socket.write("S*1234#W#013*E");
      await socket.flush();
      socket.destroy();
    } catch (e) {
      _logger.w('Could not send disconnect packet: $e');
    }
  }
}
