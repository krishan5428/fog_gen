import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fog_gen_new/core/repo/mqtt_repository.dart';
import 'package:fog_gen_new/features/mqtt/services/fourg_mqtt_service.dart';

class _FakeMqttRepository extends MqttRepository {
  final _messages = StreamController<String>.broadcast();
  final published = <String>[];

  @override
  Stream<String> get messageStream => _messages.stream;

  @override
  Future<bool> publish(String topic, String message) async {
    published.add(message);
    return true;
  }

  void reply(String frame) => _messages.add(frame);
}

Future<void> _settle() async {
  for (int i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  const imei = '123456789012345';
  late _FakeMqttRepository mqtt;
  late FourGMqttService service;

  setUp(() {
    mqtt = _FakeMqttRepository();
    service = FourGMqttService(mqtt);
  });

  group('request queue', () {
    test('second request waits until the panel answers the first', () async {
      service.setOutput(imei: imei, passcode: '1234', output: 1, on: false);
      service.readDashboard(imei: imei, passcode: '1234');
      await _settle();

      expect(mqtt.published, hasLength(1));
      expect(mqtt.published.single, contains('\$02\$012\$081\$0'));

      mqtt.reply('ST*$imei\$100\$04\$01\$012\$081*ED');
      await _settle();

      expect(mqtt.published, hasLength(2));
      expect(mqtt.published.last, contains('\$01\$001'));
    });

    test('a Processing (04) status does not release the queue', () async {
      service.setOutput(imei: imei, passcode: '1234', output: 1, on: true);
      service.setOutput(imei: imei, passcode: '1234', output: 1, on: false);
      await _settle();

      mqtt.reply('ST*$imei\$100\$04\$04\$012\$081*ED');
      await _settle();
      expect(mqtt.published, hasLength(1));

      mqtt.reply('ST*$imei\$100\$04\$02\$012\$081*ED');
      await _settle();
      expect(mqtt.published, hasLength(2));
    });

    test('an error frame releases the queue', () async {
      service.setOutput(imei: imei, passcode: '1234', output: 1, on: true);
      service.readDashboard(imei: imei, passcode: '1234');
      await _settle();

      mqtt.reply('ST*$imei\$100\$00\$05*ED');
      await _settle();
      expect(mqtt.published, hasLength(2));
    });
  });

  group('ensureOutputsEnabled without the dashboard', () {
    test('re-writes a disabled output with ENABLED set', () async {
      final result = service.ensureOutputsEnabled(
        imei: imei,
        passcode: '1234',
        outputs: [2],
        viaDashboard: false,
      );
      await _settle();
      expect(mqtt.published.single, contains('\$01\$011\$082'));

      mqtt.reply('ST*$imei\$100\$03\$01\$011\$082\$0\$Output 2\$1\$000*ED');
      await _settle();
      expect(
        mqtt.published.last,
        equals('ST*$imei\$001234\$02\$011\$082\$1\$Output 2\$1\$000*ED'),
      );

      mqtt.reply('ST*$imei\$100\$04\$01\$011*ED');
      expect(await result, equals([2]));
      expect(mqtt.published.where((p) => p.contains('\$01\$001')), isEmpty);
    });

    test('leaves an enabled output alone', () async {
      final result = service.ensureOutputsEnabled(
        imei: imei,
        passcode: '1234',
        outputs: [1],
        viaDashboard: false,
      );
      await _settle();
      mqtt.reply('ST*$imei\$100\$03\$01\$011\$081\$1\$Output 1\$1\$000*ED');

      expect(await result, isEmpty);
      expect(mqtt.published, hasLength(1));
    });
  });
}
