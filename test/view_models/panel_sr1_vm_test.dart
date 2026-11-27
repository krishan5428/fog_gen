import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fog_gen_new/core/responses/socket_repository.dart';
import 'package:fog_gen_new/core/utils/application_class.dart';
import 'package:fog_gen_new/presentation/screens/main/panel_sr1/panel_sr1_viewmodel.dart';

/// Answers SR1 reads by packet id ("S*1234#R#008*E" → replies['008']).
class FakeSr1 extends Fake implements SocketRepository {
  FakeSr1(this.replies);
  final Map<String, String> replies;
  final List<String> sent = [];

  @override
  Future<String> sendPacketSR1(String packet, {bool isPriority = false}) async {
    sent.add(packet);
    final id = packet.split('#')[2].replaceAll('*E', '');
    final r = replies[id];
    if (r == null) throw TimeoutException('Response Timeout');
    return r;
  }
}

Map<String, String> panel({
  String users = '01',
  String inputs = '0000',
  String outputs = '01#10#00#11',
  String time = '08301525112026', // 08:30:15 25-11-2026
  String signal = '3',
}) => {
  '009': 'S*009#$users*E',
  '008': 'S*008#$inputs*E',
  '007': 'S*007#$outputs*E',
  '011': 'S*011#$time*E',
  '020': 'S*020#$signal*E',
};

/// Builds the view model and waits for its initial 5 reads.
Future<PanelSR1ViewModel> load(FakeSr1 repo) async {
  final vm = PanelSR1ViewModel(socketRepository: repo);
  for (var i = 0; i < 100 && repo.sent.length < 5; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  await Future<void>.delayed(const Duration(milliseconds: 5));
  return vm;
}

void main() {
  setUp(() => Application().mPassword = '1234');

  test('initial load reads 009, 008, 007, 011, 020 and parses them', () async {
    final repo = FakeSr1(panel());
    final vm = await load(repo);

    expect(repo.sent.map((p) => p.split('#')[2].replaceAll('*E', '')), [
      '009',
      '008',
      '007',
      '011',
      '020',
    ]);
    expect(vm.adminStatus, 'ARMED');
    expect(vm.userStatus, 'DISARMED');
    expect(vm.inputStatuses.take(4), ['NORMAL', 'NORMAL', 'NORMAL', 'NORMAL']);
    expect(vm.outputSounderStatus, 'ON');
    expect(vm.outputAuto1Status, 'OFF');
    expect(vm.outputAuto2Status, 'OFF');
    expect(vm.outputAuto3Status, 'ON');
    expect(vm.signalStrengthLevel, 3);
    expect(vm.isPanelStatusLoading, isFalse);
    expect(vm.isZoneStatusLoading, isFalse);
    expect(vm.isConnectionHealthy, isTrue);
    vm.dispose();
  });

  test('input statuses, system error and mains flags', () async {
    final vm = await load(FakeSr1(panel(inputs: '134911')));
    expect(vm.inputStatuses.take(4), [
      'ARM ALERT',
      'DISARM ALERT',
      'LONG OPEN',
      'DISABLE',
    ]);
    expect(vm.isSystemErrorDetected, isTrue);
    expect(vm.isMainsOk, isTrue);
    vm.dispose();
  });

  test('mains code 9 in the 008 reply is still read as zones, not as '
      'user status (reply contains "009")', () async {
    final vm = await load(FakeSr1(panel(users: '10', inputs: '000009')));
    expect(vm.isMainsOk, isTrue, reason: '008 reply was not parsed');
    expect(vm.inputStatuses.take(4), ['NORMAL', 'NORMAL', 'NORMAL', 'NORMAL']);
    expect(vm.adminStatus, 'DISARMED', reason: '008 data overwrote 009 status');
    vm.dispose();
  });

  test('a panel time of 10:09 does not overwrite the arm status '
      '(011 reply contains "009")', () async {
    final vm = await load(FakeSr1(panel(users: '11', time: '10091525112026')));
    expect(vm.adminStatus, 'DISARMED');
    expect(vm.userStatus, 'DISARMED');
    vm.dispose();
  });

  test(
    'signal level is clamped to 0..4; garbage replies are ignored',
    () async {
      final repo = FakeSr1(panel(signal: '9'));
      repo.replies['007'] = 'noise';
      final vm = await load(repo);
      expect(vm.signalStrengthLevel, 4);
      expect(vm.outputSounderStatus, 'OFF'); // default, noise ignored
      vm.dispose();
    },
  );

  test('panel not answering → connection unhealthy + failure event', () async {
    final vm = PanelSR1ViewModel(socketRepository: FakeSr1({}));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(vm.isConnectionHealthy, isFalse);
    expect(vm.event, PanelSR1ViewEvent.showCommandFailedToast);
    expect(vm.isPanelStatusLoading, isFalse);
    vm.dispose();
  });
}
