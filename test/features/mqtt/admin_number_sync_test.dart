import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fog_gen_new/core/repo/mqtt_repository.dart';
import 'package:fog_gen_new/features/mqtt/repository/fourg_repository.dart';
import 'package:fog_gen_new/features/mqtt/services/admin_number_sync.dart';
import 'package:fog_gen_new/features/mqtt/services/fourg_mqtt_service.dart';

const imei = '865510082043789';

/// Stands in for the broker + a 4GCOM panel: answers packet-008 reads with
/// its current slots and applies packet-008 writes.
class _FakePanelRepository extends MqttRepository {
  _FakePanelRepository(this.slots);

  List<String> slots;
  String writeAckStatus = "01";
  bool applyWrites = true;
  final List<String> published = [];
  final _replies = StreamController<String>.broadcast();

  @override
  Stream<String> get messageStream => _replies.stream;

  @override
  bool get isConnected => true;

  @override
  Future<bool> publish(String topic, String message) async {
    published.add(message);
    final parts = message.split('\$');
    if (parts[2] == "01" && parts[3].startsWith("008")) {
      _reply("ST*$imei\$100\$03\$01\$008\$${slots.join('\$')}*ED");
    } else if (parts[2] == "02" && parts[3] == "008") {
      if (applyWrites && writeAckStatus == "01") {
        slots = [for (final s in parts.sublist(4)) s.replaceAll('*ED', '')];
      }
      _reply("ST*$imei\$100\$04\$$writeAckStatus\$008*ED");
    }
    return true;
  }

  void _reply(String frame) => Future.microtask(() => _replies.add(frame));
}

FourGRepository _repoFor(_FakePanelRepository fake) =>
    FourGRepository(FourGMqttService(fake));

List<String> _emptySlots() => List.filled(11, "0#+91#0");

void main() {
  group('AdminNumberSync parsing', () {
    test('parseSlots reads the 11 entries of a real 008 response', () {
      const frame =
          'ST*$imei\$100\$03\$01\$008\$4#+91#9833422307\$0#+91#0\$0#+91#0'
          '\$0#+91#0\$0#+91#0\$0#+91#0\$0#+91#0\$0#+91#0\$0#+91#0\$0#+91#0'
          '\$0#+91#0*ED';
      final slots = AdminNumberSync.parseSlots(frame)!;
      expect(slots, hasLength(11));
      expect(AdminNumberSync.numberOf(slots[0]), '9833422307');
      expect(AdminNumberSync.numberOf(slots[10]), '');
    });

    test('parseSlots rejects a truncated frame', () {
      expect(
        AdminNumberSync.parseSlots('ST*$imei\$100\$03\$01\$008\$4#+91#1*ED'),
        isNull,
      );
    });
  });

  group('AdminNumberSync.writeToPanel', () {
    test('sets only the admin slot and keeps Tel. No. 1-10', () async {
      final fake = _FakePanelRepository(_emptySlots())
        ..slots[2] = "2#-#9876543210"; // panel echoes "-" for blank cc
      final result = await AdminNumberSync.writeToPanel(
        fourGRepository: _repoFor(fake),
        imei: imei,
        passcode: '001234',
        adminNumber: '9991945637',
      );

      expect(result.isSuccess, isTrue);
      expect(fake.slots[0], '4#+91#9991945637');
      // "-" is rewritten (panel rejects it on write); number kept.
      expect(fake.slots[2], '2#+91#9876543210');
      expect(fake.slots.where((s) => s == "0#+91#0"), hasLength(9));
    });

    test('keeps the panel\'s existing alert mode for the admin slot', () async {
      final fake = _FakePanelRepository(_emptySlots())..slots[0] = "3#+91#0";
      final result = await AdminNumberSync.writeToPanel(
        fourGRepository: _repoFor(fake),
        imei: imei,
        passcode: '001234',
        adminNumber: '9991945637',
      );
      expect(result.isSuccess, isTrue);
      expect(fake.slots[0], '3#+91#9991945637');
    });

    test('refuses a number already used in another slot', () async {
      final fake = _FakePanelRepository(_emptySlots())
        ..slots[4] = "4#+91#9991945637";
      final result = await AdminNumberSync.writeToPanel(
        fourGRepository: _repoFor(fake),
        imei: imei,
        passcode: '001234',
        adminNumber: '9991945637',
      );
      expect(result.isSuccess, isFalse);
      expect(result.failureReason, contains('Tel. No. 04'));
      expect(fake.published.where((p) => p.contains('\$02\$008')), isEmpty);
    });

    test('fails when the panel rejects the write', () async {
      final fake = _FakePanelRepository(_emptySlots())..writeAckStatus = "00";
      final result = await AdminNumberSync.writeToPanel(
        fourGRepository: _repoFor(fake),
        imei: imei,
        passcode: '001234',
        adminNumber: '9991945637',
      );
      expect(result.isSuccess, isFalse);
    });

    test(
      'fails when the ack is positive but the read-back disagrees',
      () async {
        final fake = _FakePanelRepository(_emptySlots())..applyWrites = false;
        final result = await AdminNumberSync.writeToPanel(
          fourGRepository: _repoFor(fake),
          imei: imei,
          passcode: '001234',
          adminNumber: '9991945637',
        );
        expect(result.isSuccess, isFalse);
      },
    );

    test('pads a 4-digit passcode on the wire', () async {
      final fake = _FakePanelRepository(_emptySlots());
      await AdminNumberSync.writeToPanel(
        fourGRepository: _repoFor(fake),
        imei: imei,
        passcode: '1234',
        adminNumber: '9991945637',
      );
      expect(fake.published, everyElement(contains('\$001234\$')));
    });
  });
}
