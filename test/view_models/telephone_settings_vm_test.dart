import 'package:flutter_test/flutter_test.dart';
import 'package:fog_gen_new/core/data/pojo/panel_data.dart';
import 'package:fog_gen_new/core/responses/socket_repository.dart';
import 'package:fog_gen_new/presentation/screens/more_settings/telephone_no_settings_viewmodel.dart';

class FakeSr1 extends Fake implements SocketRepository {
  String readReply = full;
  String writeReply = 'S*018#0*E';
  bool offline = false;
  final List<String> writes = [];

  static String get full {
    final parts = <String>[];
    for (var i = 0; i < 10; i++) {
      parts
        ..add(i == 0 ? '9876543210' : 'DISABLED')
        ..add(i == 0 ? '3' : '0');
    }
    return 'S*018#${parts.join('#')}*E';
  }

  @override
  Future<String> sendPacketSR1(String packet, {bool isPriority = false}) async {
    if (offline) throw Exception('All connection attempts failed');
    if (packet.contains('#W#')) {
      writes.add(packet);
      return writeReply;
    }
    return readReply;
  }
}

final panel = PanelData.fromJson({
  'pnl_id': 1,
  'ip_add': '1.2.3.4',
  'port_no': '5000',
  'pass': '1234',
});

Future<TelephoneNoSettingsViewModel> load(FakeSr1 repo) async {
  final vm = TelephoneNoSettingsViewModel(
    panelData: panel,
    socketRepository: repo,
  );
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  return vm;
}

void main() {
  test('reads 10 numbers with their alert type', () async {
    final vm = await load(FakeSr1());
    expect(vm.isLoading, isFalse);
    expect(vm.settings[0].number, '9876543210');
    expect(vm.settings[0].type, AlertType.smsAndCall);
    expect(vm.settings[1].number, '');
    expect(vm.settings[1].type, AlertType.disabled);
  });

  test('edit + save writes all 10 slots, then re-reads', () async {
    final repo = FakeSr1();
    final vm = await load(repo);
    vm.updateLocalSetting(1, number: '9999999999', type: AlertType.sms);
    await vm.submitAllChanges();
    expect(
      repo.writes.single,
      'S*1234#W#018#9876543210#3#9999999999#1'
      '${'#DISABLED#0' * 8}*E',
    );
    expect(vm.event, TelephoneSettingsEvent.showUpdateSuccessToast);
  });

  test('cancel restores what the panel holds', () async {
    final vm = await load(FakeSr1());
    vm.updateLocalSetting(0, number: '1');
    vm.cancelChanges();
    expect(vm.settings[0].number, '9876543210');
    expect(vm.event, TelephoneSettingsEvent.settingsReverted);
  });

  test('panel rejects the write → failure event', () async {
    final repo = FakeSr1()..writeReply = 'S*018#1*E';
    final vm = await load(repo);
    await vm.submitAllChanges();
    expect(vm.event, TelephoneSettingsEvent.showUpdateFailedToast);
  });

  test('offline → fetch failure event', () async {
    final vm = await load(FakeSr1()..offline = true);
    expect(vm.event, TelephoneSettingsEvent.showFetchFailedToast);
  });

  for (final bad in ['S*018#1*E', 'S*018#9876543210#3*E', 'garbage']) {
    test('bad read reply "$bad" → fetch failure, and save is refused '
        '(would wipe the panel\'s numbers)', () async {
      final repo = FakeSr1()..readReply = bad;
      final vm = await load(repo);
      expect(vm.event, TelephoneSettingsEvent.showFetchFailedToast);

      await vm.submitAllChanges();
      expect(repo.writes, isEmpty);
      expect(vm.event, TelephoneSettingsEvent.showUpdateFailedToast);
    });
  }

  test('leaving the screen during the read does not throw', () async {
    final vm = TelephoneNoSettingsViewModel(
      panelData: panel,
      socketRepository: FakeSr1(),
    );
    vm.dispose(); // read still in flight
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  });
}
