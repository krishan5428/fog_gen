// ignore_for_file: unused_import
import 'package:flutter/foundation.dart';
import 'dart:async';

import 'package:fog_gen_new/constants/mqtt_constants.dart';
import 'package:fog_gen_new/core/repo/mqtt_repository.dart';
import 'package:fog_gen_new/features/mqtt/models/input_settings.dart';
import 'package:fog_gen_new/features/mqtt/services/fourg_mqtt_commands.dart';
import 'package:fog_gen_new/features/mqtt/services/fourg_mqtt_parser.dart';
import 'package:logger/logger.dart';

class FourGMqttService {
  final MqttRepository mqttRepository;
  final Map<String, String> _cachedProductIds = {};
  final _logger = Logger();

  FourGMqttService(this.mqttRepository) {
    mqttRepository.messageStream.listen((response) {
      try {
        final parts = response.split('\$');
        if (parts.length >= 2 && parts[0].startsWith("ST*")) {
          final imei = parts[0].substring(3);
          final productId = parts[1];
          if (RegExp(r'^\d{3}$').hasMatch(productId)) {
            _cachedProductIds[imei] = productId;
          }
        }
      } catch (_) {}
    });
  }

  String getProductId(String imei) => _cachedProductIds[imei] ?? "103";

  // The panel answers only one request at a time and silently drops a
  // second one that arrives before it has replied, so queued requests are
  // sent strictly one after another.
  Future<void> _queueTail = Future.value();

  Future<void> get idle => _queueTail;

  ({Future<bool> sent, Future<String?> reply}) _enqueue({
    required String imei,
    required String payload,
    required bool Function(List<String> parts) isReply,
    Duration timeout = const Duration(seconds: 3),
  }) {
    final sent = Completer<bool>();
    final reply = _queueTail.then(
      (_) => _sendAndAwaitReply(imei, payload, isReply, timeout, sent),
    );
    _queueTail = reply.then((_) {}, onError: (_) {});
    return (sent: sent.future, reply: reply);
  }

  Future<String?> _sendAndAwaitReply(
    String imei,
    String payload,
    bool Function(List<String> parts) isReply,
    Duration timeout,
    Completer<bool> sent,
  ) async {
    final completer = Completer<String?>();
    final sub = mqttRepository.messageStream.listen((response) {
      final parts = response.trim().split('\$');
      if (parts.length < 3 || parts[0] != "ST*$imei") return;
      if ((parts[2] == "00" || isReply(parts)) && !completer.isCompleted) {
        completer.complete(response);
      }
    });

    try {
      final ok = await mqttRepository.publish(
        MqttConstants.publishTopic(imei),
        payload,
      );
      sent.complete(ok);
      if (!ok) return null;
      return await completer.future.timeout(timeout, onTimeout: () => null);
    } catch (e) {
      if (!sent.isCompleted) sent.complete(false);
      return null;
    } finally {
      await sub.cancel();
    }
  }

  static String _field(List<String> parts, int i) =>
      i < parts.length ? parts[i].replaceAll('*ED', '').trim() : '';

  static bool Function(List<String>) _readReply(String packetId) =>
      (parts) =>
          _field(parts, 2) == "03" &&
          _field(parts, 3) == "01" &&
          _field(parts, 4) == packetId;

  // Status 04 (Processing) is not final; keep waiting for the next frame.
  static bool Function(List<String>) _writeReply(String packetId) =>
      (parts) =>
          _field(parts, 2) == "04" &&
          _field(parts, 4) == packetId &&
          _field(parts, 3) != "04";

  static bool _isWriteSuccess(String? reply) {
    if (reply == null) return false;
    final parts = reply.trim().split('\$');
    final status = _field(parts, 3);
    return _field(parts, 2) == "04" && (status == "01" || status == "02");
  }

  /// Turns on any of [outputs] that the panel reports as disabled, by
  /// re-writing its Output Settings record with ENABLED set. Returns the
  /// outputs that were enabled.
  ///
  /// With [viaDashboard] the disabled outputs are found from one dashboard
  /// read. Without it each output's packet-011 record is read instead — the
  /// backend treats a dashboard read as an app login and alerts on it, so
  /// quick actions that don't open the dashboard use this.
  Future<List<int>> ensureOutputsEnabled({
    required String imei,
    required String passcode,
    List<int> outputs = const [1, 2, 3],
    bool viaDashboard = true,
  }) async {
    Future<String?> readRecord(int output) => _enqueue(
      imei: imei,
      payload: FourGMqttCommands.readOutputSettings(
        imei: imei,
        passcode: passcode,
        output: output,
      ),
      isReply: _readReply("011"),
    ).reply;

    List<String>? states;
    if (viaDashboard) {
      final dashboard = await _enqueue(
        imei: imei,
        payload: FourGMqttCommands.readDashboard(
          imei: imei,
          passcode: passcode,
        ),
        isReply: _readReply("001"),
      ).reply;
      states = dashboard == null
          ? null
          : FourGMqttParser.parseDashboardOutputStates(dashboard);
      if (states == null) return const [];
    }

    final enabled = <int>[];
    for (final output in outputs) {
      String? record;
      if (states != null) {
        if (output > states.length || states[output - 1] != 'D') continue;
        record = await readRecord(output);
      } else {
        record = await readRecord(output);
        if (record == null ||
            FourGMqttParser.isOutputSettingsEnabled(record) != false) {
          continue;
        }
      }

      final write = record == null
          ? null
          : FourGMqttCommands.enableOutputFromSettings(
              imei: imei,
              passcode: passcode,
              readResponse: record,
            );
      if (write == null) {
        _logger.w("ENABLE OUTPUT $output | Could not read Output Settings");
        continue;
      }

      final ack = await _enqueue(
        imei: imei,
        payload: write,
        isReply: _writeReply("011"),
      ).reply;
      if (_isWriteSuccess(ack)) {
        enabled.add(output);
      } else {
        _logger.w("ENABLE OUTPUT $output | Write not acknowledged: $ack");
      }
    }
    return enabled;
  }

  /// Per protocol Section 11: products 100/101/102/103 all key their base
  /// 4 inputs (Input 01-04, Device Tamper, Device Panic) under
  /// INPUT_OF_PRODUCT "100" — the raw PRODUCT_ID is only used as-is for
  /// every other product family. Using the raw PRODUCT_ID for these four
  /// still round-trips a read/write against the panel (it echoes back
  /// whatever key it's asked for), but it targets a different record from
  /// the one the packet-001 Dashboard summary actually reads its input
  /// names from — so writes silently never show up there.
  String _resolveInputOfProduct(String rawProductId) {
    const basicFamily = {"100", "101", "102", "103"};
    return basicFamily.contains(rawProductId) ? "100" : rawProductId;
  }

  Future<void> assignPanelId({
    required String imei,
    required String passcode,
    required String panelId,
  }) async {
    // final payload =
    //     'ST*$imei\$$passcode\$02\$013\$01\$$panelId\$000\$00*ED';
    final payload =
        "ST*$imei\$$passcode\$02\$013\$01\$"
        "$panelId\$"
        "000001\$"
        "000000*ED";

    _logger.i(
      "ASSIGN PANEL ID | IMEI: $imei | PANEL ID: $panelId | PAYLOAD: $payload",
    );

    mqttRepository.publish(MqttConstants.publishTopic(imei), payload);
  }

  Future<void> disconnectPanel({
    required String imei,
    required String passcode,
  }) async {
    final payload = FourGMqttCommands.disconnect(
      imei: imei,
      passcode: passcode,
    );

    await _enqueue(
      imei: imei,
      payload: payload,
      isReply: (parts) => _field(parts, 4) == "000",
      timeout: const Duration(seconds: 1),
    ).sent;
  }

  /// Success here means the write request actually left the client (the
  /// panel was connected at publish time) — it does NOT wait for the
  /// panel's write-response ack. A live connection is trusted to mean the
  /// command gets through.
  Future<bool> panic({required String imei, required String passcode}) async {
    final payload = FourGMqttCommands.panic(imei: imei, passcode: passcode);

    return mqttRepository.publish(MqttConstants.publishTopic(imei), payload);
  }

  Future<bool> setOutput({
    required String imei,
    required String passcode,
    required int output,
    required bool on,
  }) async {
    final payload = FourGMqttCommands.setOutput(
      imei: imei,
      passcode: passcode,
      output: output,
      on: on,
    );

    return _enqueue(
      imei: imei,
      payload: payload,
      isReply: _writeReply("012"),
    ).sent;
  }

  Future<bool> alarmAbort({
    required String imei,
    required String passcode,
  }) async {
    final payload = FourGMqttCommands.alarmAbort(
      imei: imei,
      passcode: passcode,
    );

    return mqttRepository.publish(MqttConstants.publishTopic(imei), payload);
  }

  Future<void> arm({required String imei, required String passcode}) async {
    final payload = FourGMqttCommands.arm(imei: imei, passcode: passcode);

    mqttRepository.publish(MqttConstants.publishTopic(imei), payload);
  }

  Future<void> disarm({required String imei, required String passcode}) async {
    final payload = FourGMqttCommands.disarm(imei: imei, passcode: passcode);

    mqttRepository.publish(MqttConstants.publishTopic(imei), payload);
  }

  Future<void> readDashboard({
    required String imei,
    required String passcode,
  }) async {
    final payload = FourGMqttCommands.readDashboard(
      imei: imei,
      passcode: passcode,
    );

    await _enqueue(
      imei: imei,
      payload: payload,
      isReply: _readReply("001"),
    ).sent;
  }

  /// Silently re-sends the Connect Request (packet 000) when the Settings
  /// screen opens — no loading indicator, no toast, and the result is never
  /// inspected either way. This is just a background keep-alive ping to the
  /// panel; a real connection problem will surface naturally when a
  /// specific settings sub-page's own read/write times out.
  void sendSilentConnectPing({required String imei, required String passcode}) {
    final payload = FourGMqttCommands.connect(imei: imei, passcode: passcode);

    mqttRepository.publish(MqttConstants.publishTopic(imei), payload);
  }

  Future<DashboardInputSummary?> readDashboardInputSummary({
    required String imei,
    required String passcode,
    int zoneCount = 4,
  }) async {
    final passcodePadded = passcode.padLeft(6, '0');
    final payload = FourGMqttCommands.readDashboard(
      imei: imei,
      passcode: passcodePadded,
    );

    _logger.i("READ DASHBOARD (zone mapping quick load) | PAYLOAD: $payload");

    final completer = Completer<String?>();
    late StreamSubscription sub;

    sub = mqttRepository.messageStream.listen((response) {
      final parts = response.split('\$');
      if (parts.length >= 6 &&
          parts[2] == "03" &&
          parts[3] == "01" &&
          parts[4] == "001") {
        if (!completer.isCompleted) completer.complete(response);
      }
    });

    final sent = await mqttRepository.publish(
      MqttConstants.publishTopic(imei),
      payload,
    );
    if (!sent) {
      await sub.cancel();
      _logger.w(
        "READ DASHBOARD (zone mapping) | Could not send request — not connected",
      );
      return null;
    }

    final result = await completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => null,
    );

    await sub.cancel();

    if (result == null) return null;
    return FourGMqttParser.parseDashboardInputSummary(
      result,
      zoneCount: zoneCount,
    );
  }

  Future<InputSettings?> readInputSettings({
    required String imei,
    required String passcode,
    required String inputNumber,
    String? productNumber,
  }) async {
    final passcodePadded = passcode.padLeft(6, '0');
    final pNo = productNumber ?? _resolveInputOfProduct(getProductId(imei));
    final payload = "ST*$imei\$$passcodePadded\$01\$010\$$pNo\$$inputNumber*ED";

    _logger.i("READ INPUT SETTINGS (Packet 010) | PAYLOAD: $payload");

    final completer = Completer<String?>();
    late StreamSubscription sub;

    sub = mqttRepository.messageStream.listen((response) {
      final parts = response.split('\$');
      // Require the FULL packet (header + all 31 data fields up to
      // TELE_NO_MAPPING at index 37) before accepting it — a short/partial
      // packet that only matches the header must not be treated as a
      // valid read, otherwise writeInputSettings would replay it back
      // as a truncated (corrupt) write packet.
      // Key on BOTH inputOfProduct and inputPacketId (parts[5] & parts[6])
      // — packet id alone collides between base inputs and zones on some
      // product families (see protocol doc, Section 11).
      if (parts.length >= 38 &&
          parts[2] == "03" &&
          parts[3] == "01" &&
          parts[4] == "010" &&
          parts[5] == pNo &&
          parts[6] == inputNumber) {
        _logger.d("010 READ RESPONSE: $response");
        if (!completer.isCompleted) {
          completer.complete(response);
        }
      }
    });

    final sent = await mqttRepository.publish(
      MqttConstants.publishTopic(imei),
      payload,
    );
    if (!sent) {
      await sub.cancel();
      _logger.w("READ INPUT SETTINGS | Could not send request — not connected");
      return null;
    }

    final result = await completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => null,
    );

    await sub.cancel();
    return result == null ? null : InputSettings.fromReadResponse(result);
  }

  Future<bool> writeInputSettings({
    required String imei,
    required String passcode,
    required InputSettings currentSettings,
    required String newInputName,
    required String newEnabled,
  }) async {
    final updated = currentSettings.copyWith(
      name: newInputName,
      enabled: newEnabled,
    );
    final payload = updated.buildWriteRequest(passcode: passcode);

    _logger.i("WRITE INPUT SETTINGS (Packet 010) | PAYLOAD: $payload");

    // Nullable: null means "no definitive ack arrived within the fast-path
    // window" (see below), distinct from an explicit true/false ack.
    final completer = Completer<bool?>();
    late StreamSubscription sub;

    sub = mqttRepository.messageStream.listen((response) {
      final respParts = response.trim().split('\$');
      // Write Response: ST*{IMEI}${PRODUCT_ID}$04${STATUS}$010*ED — only
      // 5 elements when split on '$'. The panel doesn't echo back which
      // input number it wrote, so this ack can only confirm that *a*
      // packet-010 write completed, not which one — mirrors the same
      // ack convention used for packets 008/013 elsewhere in this file.
      //
      // STATUS codes: 00=Nack, 01=Ack, 02=Process Success, 03=Process Fail,
      // 04=Processing (non-terminal — more messages still to come),
      // 99=Data Error. "02" was previously never checked here, so a write
      // the panel actually applied (and acked with "02") looked like a
      // failure to the app; "04" was previously treated as an immediate
      // success, when it really just means "keep waiting for the real
      // result".
      if (respParts.length < 5) return;
      final isPacket010 = respParts[4].startsWith("010");
      if (!isPacket010) return;
      if (respParts[2] != "04") return;

      final status = respParts[3];
      if (status == "01" || status == "02") {
        _logger.d("010 WRITE SUCCESS ACK ($status): $response");
        if (!completer.isCompleted) completer.complete(true);
      } else if (status == "04") {
        _logger.d("010 WRITE PROCESSING — waiting for final status: $response");
      } else {
        _logger.w("010 WRITE FAILED ACK ($status): $response");
        if (!completer.isCompleted) completer.complete(false);
      }
    });

    final sent = await mqttRepository.publish(
      MqttConstants.publishTopic(imei),
      payload,
    );
    if (!sent) {
      await sub.cancel();
      _logger.w(
        "WRITE INPUT SETTINGS | Could not send request — not connected",
      );
      return false;
    }

    // Fast path: a definitive ack ("01"/"02" success, or an explicit
    // failure status) within 3s wins outright — no need to wait further.
    final ackResult = await completer.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () => null,
    );
    await sub.cancel();

    if (ackResult != null) return ackResult;

    // No definitive ack within 3s. Rather than keep guessing at the ack
    // (STATUS codes for this packet have proven unreliable to pin down —
    // see prior debugging), verify by reading the record back: give the
    // panel a moment to persist the write, then re-fetch this exact input
    // and check whether it now reflects what we asked for.
    _logger.i(
      "010 WRITE | No ack within 3s — verifying by re-reading "
      "input ${currentSettings.inputPacketId} (product "
      "${currentSettings.inputOfProduct})",
    );

    final verified = await readInputSettings(
      imei: imei,
      passcode: passcode,
      inputNumber: currentSettings.inputPacketId,
      productNumber: currentSettings.inputOfProduct,
    );

    if (verified == null) {
      _logger.w(
        "010 WRITE | Verification read failed — could not confirm update",
      );
      return false;
    }

    final success =
        verified.name == newInputName && verified.enabled == newEnabled;
    _logger.i(
      "010 WRITE | Verification read ${success ? 'confirms' : 'does NOT confirm'} the update",
    );
    return success;
  }

  Future<void> readAlarmLogs({
    required String imei,
    required String passcode,
  }) async {
    final payload = FourGMqttCommands.readAlarmLogs(
      imei: imei,
      passcode: passcode,
    );

    mqttRepository.publish(MqttConstants.publishTopic(imei), payload);
  }

  Future<void> readEventLogs({
    required String imei,
    required String passcode,
  }) async {
    final payload = FourGMqttCommands.readEventLogs(
      imei: imei,
      passcode: passcode,
    );

    mqttRepository.publish(MqttConstants.publishTopic(imei), payload);
  }

  Future<String?> readPanelId({
    required String imei,
    required String passcode,
  }) async {
    final payload = 'ST*$imei\$$passcode\$01\$013\$01*ED';

    _logger.i("READ PANEL ID | IMEI: $imei | PAYLOAD: $payload");

    final completer = Completer<String?>();

    late StreamSubscription sub;

    sub = mqttRepository.messageStream.listen((response) {
      final parts = response.split('\$');
      if (parts.length >= 6 &&
          parts[2] == "03" &&
          parts[3] == "01" &&
          parts[4] == "013" &&
          parts[5] == "01") {
        _logger.d("READ BACK PANEL DATA: $response");
        if (!completer.isCompleted) {
          completer.complete(response);
        }
      }
    });

    final sent = await mqttRepository.publish(
      MqttConstants.publishTopic(imei),
      payload,
    );
    if (!sent) {
      await sub.cancel();
      _logger.w("READ PANEL ID | Could not send request — not connected");
      return null;
    }

    final result = await completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => null,
    );

    await sub.cancel();

    return result;
  }

  /// Returns whether the write packet actually left the client. `false`
  /// means the caller should not bother waiting for a write ack — nothing
  /// was sent for the panel to acknowledge.
  Future<bool> assignDestinationSettings({
    required String imei,
    required String passcode,
    String type = "1",
    String ip = "182.73.129.27",
    String port = "05600",
    String ip2 = "0.0.0.0",
    String port2 = "00000",
  }) async {
    final payload =
        "ST*$imei\$$passcode\$02\$013\$02\$"
        "$type\$"
        "$ip\$"
        "$port\$"
        "0\$"
        "$ip2\$"
        "$port2*ED";

    _logger.i("ASSIGN DESTINATION SETTINGS | PAYLOAD: $payload");

    return mqttRepository.publish(MqttConstants.publishTopic(imei), payload);
  }

  Future<void> assignAdminNumber({
    required String imei,
    required String passcode,
    required String adminNumber,
  }) async {
    final payload =
        "ST*$imei\$$passcode\$02\$008\$"
        "4#+91#$adminNumber\$"
        "0#+91#0\$"
        "0#+91#0\$"
        "0#+91#0\$"
        "0#+91#0\$"
        "0#+91#0\$"
        "0#+91#0\$"
        "0#+91#0\$"
        "0#+91#0\$"
        "0#+91#0\$"
        "0#+91#0*ED";

    _logger.i("ASSIGN ADMIN NUMBER | PAYLOAD: $payload");

    mqttRepository.publish(MqttConstants.publishTopic(imei), payload);
  }

  /// Returns whether the write packet actually left the client — see
  /// [assignDestinationSettings].
  Future<bool> assignAdminNumbers({
    required String imei,
    required String passcode,
    required List<String> formattedNumbers,
  }) async {
    final numbersSection = formattedNumbers.join('\$');
    final payload =
        "ST*$imei\$$passcode\$02\$008\$"
        "$numbersSection*ED";

    _logger.i("ASSIGN ADMIN NUMBERS | PAYLOAD: $payload");

    return mqttRepository.publish(MqttConstants.publishTopic(imei), payload);
  }

  Future<String?> readTelephoneSettings({
    required String imei,
    required String passcode,
  }) async {
    final payload = 'ST*$imei\$$passcode\$01\$008*ED';

    _logger.i("READ TELEPHONE SETTINGS | PAYLOAD: $payload");

    final completer = Completer<String?>();

    late StreamSubscription sub;

    sub = mqttRepository.messageStream.listen((response) {
      _logger.d("008 RESPONSE: $response");
      final parts = response.split('\$');
      if (parts.length >= 5 &&
          parts[2] == "03" &&
          parts[3] == "01" &&
          parts[4] == "008") {
        if (!completer.isCompleted) {
          completer.complete(response);
        }
      }
    });

    final sent = await mqttRepository.publish(
      MqttConstants.publishTopic(imei),
      payload,
    );
    if (!sent) {
      await sub.cancel();
      _logger.w(
        "READ TELEPHONE SETTINGS | Could not send request — not connected",
      );
      return null;
    }

    final result = await completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => null,
    );

    await sub.cancel();

    return result;
  }

  Future<String?> readDestinationSettings({
    required String imei,
    required String passcode,
  }) async {
    final payload = 'ST*$imei\$$passcode\$01\$013\$02*ED';

    final completer = Completer<String?>();

    late StreamSubscription sub;

    sub = mqttRepository.messageStream.listen((response) {
      _logger.d("013/02 RESPONSE: $response");
      final parts = response.split('\$');
      if (parts.length >= 6 &&
          parts[2] == "03" &&
          parts[3] == "01" &&
          parts[4] == "013" &&
          parts[5] == "02") {
        if (!completer.isCompleted) {
          completer.complete(response);
        }
      }
    });

    final sent = await mqttRepository.publish(
      MqttConstants.publishTopic(imei),
      payload,
    );
    if (!sent) {
      await sub.cancel();
      _logger.w(
        "READ DESTINATION SETTINGS | Could not send request — not connected",
      );
      return null;
    }

    final result = await completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => null,
    );

    await sub.cancel();

    return result;
  }

  Future<bool> connectAndHandshake({
    required String imei,
    required String passcode,
  }) async {
    _logger.i('🤝 Starting connection and handshake flow...');

    final generation = await mqttRepository.connect(imei);

    mqttRepository.subscribe(MqttConstants.subscribeTopic(imei));

    mqttRepository.listen();

    // final messageBody = Packets.buildMqttMessage(
    //   passcode: passcode,
    //   isReadPacket: true,
    //   packetId: "000",
    //   data: "00",
    // );
    //
    // final fullPayload = 'ST*$imei\$$messageBody';

    final fullPayload = FourGMqttCommands.connect(
      imei: imei,
      passcode: passcode,
    );

    final completer = Completer<bool>();

    StreamSubscription? subscription;
    Timer? timeoutTimer;

    subscription = mqttRepository.messageStream.listen((payload) {
      _logger.d("HANDSHAKE LISTENER RECEIVED: $payload");

      try {
        // final parts = payload.trim().split('\$');
        //
        // if (parts.length >= 6) {
        //   final isMqttHeader =
        //       parts[0] == "ST*$imei";
        //
        //   final isReadResponse =
        //       parts[2] == "03";
        //
        //   final isAck =
        //       parts[3] == "01";
        //
        //   final isConnectPacket =
        //       parts[4] == "000";
        //
        //   final isConnectFunc =
        //   parts[5].startsWith("00");
        //
        //   if (isMqttHeader &&
        //       isReadResponse &&
        //       isAck &&
        //       isConnectPacket &&
        //       isConnectFunc) {
        //     debugPrint(
        //       "✅ Verified handshake response from panel!",
        //     );
        //
        //     if (!completer.isCompleted) {
        //       completer.complete(true);
        //     }
        //   }
        // }
        _logger.d("MQTT RESPONSE: $payload");
        if (FourGMqttParser.isErrorResponse(payload, imei) ||
            FourGMqttParser.isHandshakeRejected(payload, imei)) {
          if (!completer.isCompleted) {
            completer.complete(false);
          }
          return;
        }

        if (FourGMqttParser.isHandshakeSuccess(payload, imei)) {
          _logger.i('Verified handshake response');

          if (!completer.isCompleted) {
            completer.complete(true);
          }
        }
      } catch (e) {
        _logger.e("❌ Error parsing handshake response: $e");
      }
    });
    _logger.i(
      "SUB TOPIC: ${MqttConstants.subscribeTopic(imei)} | "
      "PUB TOPIC: ${MqttConstants.publishTopic(imei)} | "
      "PAYLOAD SENT: $fullPayload",
    );
    mqttRepository.publish(MqttConstants.publishTopic(imei), fullPayload);

    timeoutTimer = Timer(const Duration(seconds: 20), () {
      if (!completer.isCompleted) {
        _logger.w("❌ Panel handshake timeout");

        completer.complete(false);
      }
    });

    final success = await completer.future;

    await subscription.cancel();

    timeoutTimer.cancel();

    if (!success) {
      // Only our own connection — a newer attempt may have replaced it
      // while this handshake was waiting.
      mqttRepository.disconnectIfCurrent(generation);

      throw Exception("Invalid device password or handshake failed");
    }

    _logger.i("🎉 MQTT connection and handshake completed successfully");

    return true;
  }

  Future<bool> queueAbort({
    required String imei,
    required String passcode,
  }) async {
    final payload = FourGMqttCommands.queueAbort(
      imei: imei,
      passcode: passcode,
    );

    return mqttRepository.publish(MqttConstants.publishTopic(imei), payload);
  }

  Future<bool> sounderOff({
    required String imei,
    required String passcode,
  }) async {
    final payload = FourGMqttCommands.sounderOff(
      imei: imei,
      passcode: passcode,
    );

    return mqttRepository.publish(MqttConstants.publishTopic(imei), payload);
  }

  Future<String?> readAudioStatus({
    required String imei,
    required String passcode,
  }) async {
    final payload = 'ST*$imei\$$passcode\$01\$009*ED';

    _logger.i("READ AUDIO STATUS | PAYLOAD: $payload");

    final completer = Completer<String?>();
    late StreamSubscription sub;

    sub = mqttRepository.messageStream.listen((response) {
      _logger.d("009 RESPONSE: $response");
      final parts = response.split('\$');
      if (parts.length >= 5 &&
          parts[2] == "03" &&
          parts[3] == "01" &&
          parts[4] == "009") {
        if (!completer.isCompleted) {
          completer.complete(response);
        }
      }
    });

    final sent = await mqttRepository.publish(
      MqttConstants.publishTopic(imei),
      payload,
    );
    if (!sent) {
      await sub.cancel();
      _logger.w("READ AUDIO STATUS | Could not send request — not connected");
      return null;
    }

    final result = await completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => null,
    );

    await sub.cancel();
    return result;
  }

  Future<String?> writeAudioDownload({
    required String imei,
    required String passcode,
    required String downloadMask,
  }) async {
    final payload = 'ST*$imei\$$passcode\$02\$009\$01\$$downloadMask*ED';

    _logger.i("WRITE AUDIO DOWNLOAD | PAYLOAD: $payload");

    final completer = Completer<String?>();
    late StreamSubscription sub;

    sub = mqttRepository.messageStream.listen((response) {
      _logger.d("009 WRITE RESPONSE: $response");
      final parts = response.split('\$');
      // Write ack convention (same as the 010 write handler above):
      // ST*{IMEI}${PASSCODE}$04${STATUS}$009*ED — status is at index 3, the
      // feature code ("009") is at index 4. This previously checked
      // parts[5] == "01", which is the download-mask echo field, not the
      // ack status, so a genuine success response never matched and every
      // download request timed out after 10s.
      //
      // STATUS codes: 00=Nack, 01=Ack, 02=Process Success, 03=Process Fail,
      // 04=Processing (download started in the background — non-terminal,
      // a further message is expected), 99=Data Error. "02" was previously
      // never checked; "04" was previously treated as an immediate success
      // instead of "still running".
      if (parts.length < 5 || parts[2] != "04" || parts[4] != "009") return;

      final status = parts[3];
      if (status == "01" || status == "02") {
        if (!completer.isCompleted) {
          completer.complete(response);
        }
      }
      // status == "04": processing, not terminal — keep waiting.
      // anything else (00/03/99): leave uncompleted so the caller's
      // timeout reports it as a failure rather than a false success.
    });

    final sent = await mqttRepository.publish(
      MqttConstants.publishTopic(imei),
      payload,
    );
    if (!sent) {
      await sub.cancel();
      _logger.w(
        "WRITE AUDIO DOWNLOAD | Could not send request — not connected",
      );
      return null;
    }

    final result = await completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => null,
    );

    await sub.cancel();
    return result;
  }
}
