import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import 'package:fog_gen_new/constants/mqtt_constants.dart';
import 'package:fog_gen_new/core/mqtt/certificate_store.dart';
import 'package:fog_gen_new/core/logging/app_logger.dart';

class MqttRepository {
  MqttServerClient? _client;
  bool _isListening = false;
  bool _manualDisconnect = false;
  int _connectGeneration = 0;

  final StreamController<String> _messageController =
      StreamController<String>.broadcast();
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  Stream<String> get messageStream => _messageController.stream;

  // true = broker connected, false = dropped (manual disconnects don't fire this).
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  bool get isConnected =>
      _client?.connectionStatus?.state == MqttConnectionState.connected;

  /// Closes the current client before a new one replaces it, so a stale
  /// connection never stays subscribed to the panel topic alongside the new
  /// one.
  void _discardClient() {
    final old = _client;
    if (old == null) return;
    old.onConnected = null;
    old.onDisconnected = null;
    try {
      old.disconnect();
    } catch (e) {
      AppLogger.d('Discarding old MQTT client failed: $e');
    }
    _client = null;
  }

  /// Disconnects only if no newer [connect] has replaced the client since
  /// [generation] was returned — an abandoned handshake timing out must not
  /// tear down the connection a later attempt just made.
  void disconnectIfCurrent(int generation) {
    if (generation == _connectGeneration) disconnect();
  }

  /// Returns this connection's generation, for [disconnectIfCurrent].
  Future<int> connect(String imei) async {
    final generation = ++_connectGeneration;
    final ts = DateTime.now().millisecondsSinceEpoch;
    _discardClient();
    _isListening = false;
    _manualDisconnect = false;
    final client = MqttServerClient(
      MqttConstants.brokerUrl,
      'FOURG_${imei}_$ts',
    );
    _client = client;

    client.port = MqttConstants.port;
    client.secure = true;
    client.keepAlivePeriod = MqttConstants.keepAlivePeriod;
    // No library auto-reconnect: it reconnects the broker link but not the
    // panel session (packet-000 handshake), and it suppresses onDisconnected.
    // Callers own reconnection instead — see MqttControlScreen.
    client.autoReconnect = false;
    // Without this a silently dead link (network switch, NAT timeout) is
    // never detected — the default of 0 disables the ping-response check.
    client.disconnectOnNoResponsePeriod = 10;
    client.logging(on: true);

    client.securityContext = await _getSecurityContext();

    client.onConnected = () {
      AppLogger.d('MQTT Connected Successfully');
      _connectionStatusController.add(true);
    };

    client.onDisconnected = () {
      AppLogger.d('MQTT Disconnected');
      if (!_manualDisconnect) _connectionStatusController.add(false);
    };

    client.onSubscribed = (topic) {
      AppLogger.d('SUBSCRIBED SUCCESSFULLY: $topic');
    };

    client.onSubscribeFail = (topic) {
      AppLogger.d('SUBSCRIBE FAILED: $topic');
    };

    try {
      AppLogger.d('Connecting to AWS IoT Core...');

      await client.connect();

      if (client.connectionStatus?.state != MqttConnectionState.connected) {
        AppLogger.d(
          'MQTT Connection Failed: '
          '${client.connectionStatus}',
        );
        throw Exception(
          'MQTT Connection Failed: ${client.connectionStatus?.state}',
        );
      }
    } catch (e) {
      AppLogger.d('MQTT Exception: $e');
      client.disconnect();
      rethrow;
    }
    return generation;
  }

  // Future<bool> connectAndHandshake(String imei, String passcode) async {
  //   AppLogger.d('🤝 Starting connection and handshake flow...');
  //
  //   // 1. Establish broker connection
  //   await connect();
  //
  //   // 2. Subscribe to the panel's response topic
  //   final subTopic = MqttConstants.subscribeTopic(imei);
  //   subscribe(subTopic);
  //
  //   // 3. Start routing updates to messageStream
  //   listen();
  //
  //   // 4. Prepare handshake packet Connect (000), Connect Function (00)
  //   final messageBody = Packets.buildMqttMessage(
  //     passcode: passcode,
  //     isReadPacket: true,
  //     packetId: "000",
  //     data: "00",
  //   );
  //   final fullPayload = 'ST*$imei\$$messageBody';
  //
  //   final completer = Completer<bool>();
  //   StreamSubscription? subscription;
  //   Timer? timeoutTimer;
  //
  //   // 5. Listen for response
  //   subscription = messageStream.listen((payload) {
  //     try {
  //       final cleanPayload = payload.trim();
  //       final parts = cleanPayload.split('\$');
  //       if (parts.length >= 6) {
  //         final isMqttHeader = parts[0] == "ST*$imei";
  //         final isReadResponse = parts[2] == "03";
  //         final isAck = parts[3] == "01";
  //         final isConnectPacket = parts[4] == "000";
  //         final isConnectFunc = parts[5].startsWith("00");
  //
  //         if (isMqttHeader && isReadResponse && isAck && isConnectPacket && isConnectFunc) {
  //           AppLogger.d(" Verified handshake response from panel!");
  //           if (!completer.isCompleted) {
  //             completer.complete(true);
  //           }
  //         }
  //       }
  //     } catch (e) {
  //       AppLogger.d(" Error parsing message during handshake: $e");
  //     }
  //   });
  //
  //   // 6. Send the handshake packet
  //   final pubTopic = MqttConstants.publishTopic(imei);
  //   AppLogger.d(" Publishing connection handshake request to panel...");
  //   publish(pubTopic, fullPayload);
  //
  //   // 7. Start timeout watchdog
  //   timeoutTimer = Timer(const Duration(seconds: 20), () {
  //     if (!completer.isCompleted) {
  //       AppLogger.d("Panel handshake timed out after 20s");
  //       completer.complete(false);
  //     }
  //   });
  //
  //   final success = await completer.future;
  //   await subscription.cancel();
  //   timeoutTimer.cancel();
  //
  //   if (!success) {
  //     disconnect();
  //     throw Exception("Panel handshake failed or timed out.");
  //   }
  //
  //   AppLogger.d("🎉 Connection and handshake completed successfully!");
  //   return true;
  // }

  Future<SecurityContext> _getSecurityContext() async {
    final certsReady =
        await CertificateStore.instance.ensureCertificatesAvailable();
    if (!certsReady) {
      throw Exception('MQTT certificates unavailable');
    }

    final context = SecurityContext(withTrustedRoots: false);

    context.setTrustedCertificatesBytes(
      utf8.encode(CertificateStore.instance.rootCa),
    );

    context.useCertificateChainBytes(
      utf8.encode(CertificateStore.instance.clientCert),
    );

    context.usePrivateKeyBytes(
      utf8.encode(CertificateStore.instance.privateKey),
    );

    return context;
  }

  void subscribe(String topic) {
    if (!isConnected) {
      AppLogger.d('Cannot subscribe: client is not connected ($topic)');
      return;
    }
    _client!.subscribe(topic, MqttQos.atMostOnce);

    AppLogger.d('Subscribed to: $topic');
  }

  /// Returns false without sending when the link is down. Reconnecting is
  /// left to the caller on purpose: a bare broker reconnect here would skip
  /// the panel handshake and leave a session the panel may not accept.
  Future<bool> publish(String topic, String message) async {
    if (!isConnected) {
      AppLogger.d('Not connected — cannot publish message: $message');
      return false;
    }
    final builder = MqttClientPayloadBuilder();

    builder.addString(message);

    _client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);

    AppLogger.d('Published: $message');
    return true;
  }

  void listen() {
    if (_isListening) {
      AppLogger.d(
        'Already listening to updates, ignoring duplicate listen() call',
      );
      return;
    }
    _isListening = true;
    _client?.updates?.listen((events) {
      AppLogger.d('RAW EVENT COUNT: ${events.length}');

      for (final event in events) {
        AppLogger.d('TOPIC: ${event.topic}');

        final recMess = event.payload as MqttPublishMessage;

        final payload = MqttPublishPayload.bytesToStringAsString(
          recMess.payload.message,
        );

        AppLogger.d('PAYLOAD: $payload');
        AppLogger.d('STREAM HAS LISTENER: ${_messageController.hasListener}');

        _messageController.add(payload);
      }
    });
  }

  void disconnect() {
    _isListening = false;
    _manualDisconnect = true;
    _client?.disconnect();
  }

  void dispose() {
    _messageController.close();
    _connectionStatusController.close();
  }
}
