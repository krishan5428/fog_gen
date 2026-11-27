import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fog_gen_new/core/data/pojo/panel_data.dart';
import 'package:fog_gen_new/core/repo/logs_service.dart';
import 'package:fog_gen_new/core/responses/socket_repository.dart';
import 'package:fog_gen_new/core/utils/application_class.dart';
import 'package:fog_gen_new/presentation/screens/logs/log_entry.dart';
import 'package:fog_gen_new/presentation/screens/logs/logs_viewmodel.dart';
import 'package:fog_gen_new/presentation/screens/main/main_viewmodel.dart';

/// Local SR1 panel on 127.0.0.1 answering by request packet id.
class Sr1Panel {
  Sr1Panel._(this._s);
  final ServerSocket _s;
  final List<String> received = [];
  String connectReply =
      'S*000#1#004145098123236254#123456789123456#0#V0.1.1C#999999*E';
  final Map<String, String> replies = {
    '009': 'S*009#01*E',
    '008': 'S*008#0000*E',
    '007': 'S*007#01#10#00#11*E',
    '011': 'S*011#08301525112026*E',
    '020': 'S*020#3*E',
    '013': 'S*013#0*E',
  };

  static Future<Sr1Panel> start() async {
    final p = Sr1Panel._(
      await ServerSocket.bind(InternetAddress.loopbackIPv4, 0),
    );
    p._s.listen((c) {
      c.done.catchError((_) => c);
      c.listen((d) {
        final req = utf8.decode(d);
        p.received.add(req);
        final id = req.split('#')[2].replaceAll('*E', '');
        final r = id == '000' ? p.connectReply : p.replies[id];
        if (r != null) c.write(r);
      }, onError: (_) {});
    });
    return p;
  }

  int get port => _s.port;
  Iterable<String> get ids =>
      received.map((r) => r.split('#')[2].replaceAll('*E', ''));
  Future<void> close() => _s.close();
}

PanelData panelAt(int port) => PanelData.fromJson({
  'pnl_id': 1,
  'site_name': 'Site',
  'ip_add': '127.0.0.1',
  'port_no': '$port',
  'pass': '1234',
});

Future<void> until(bool Function() ok, {int seconds = 8}) async {
  for (var i = 0; i < seconds * 50 && !ok(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

class FakeLogs extends Fake implements LogsService {
  FakeLogs(this.result);
  final Object result; // List or Exception

  @override
  Future<List<Map<String, dynamic>>> fetchLogs({
    required String pnlId,
    required String usrId,
    required String ipAdd,
    required String port,
    required String rcvrNo,
    required String accNo,
    required String lineNo,
    required String mac,
    required String ver,
  }) async {
    if (result is Exception) throw result;
    return result as List<Map<String, dynamic>>;
  }
}

void main() {
  group('MainViewModel (SR1 session)', () {
    late Sr1Panel panel;
    setUp(() async => panel = await Sr1Panel.start());
    tearDown(() => panel.close());

    test('connect: handshake stores MAC/version/id, loads the dashboard, '
        'then disconnect sends 013', () async {
      final vm = MainViewModel(
        panel: panelAt(panel.port),
        socketRepository: SocketRepository(),
      );
      await vm.connect();
      expect(vm.isConnected, isTrue);
      expect(Application().macAddress, '004145098123236254');
      expect(Application().firmware, 'V0.1.1C');
      expect(Application().panelId, '999999');

      await until(() => !vm.isInitializing);
      expect(vm.isInitializing, isFalse);
      expect(vm.panelSR1ViewModel!.adminStatus, 'ARMED');

      await vm.disconnect();
      expect(panel.ids, contains('013'));
      expect(vm.isConnected, isFalse);
      expect(vm.event, MainViewEvent.showDisconnectedToast);
      vm.dispose();
    }, timeout: const Timeout(Duration(seconds: 20)));

    test('busy panel: kills the ghost session, retries once, then asks the '
        'user', () async {
      panel.connectReply = 'S*000#3#*E';
      final vm = MainViewModel(
        panel: panelAt(panel.port),
        socketRepository: SocketRepository(),
      );
      unawaited(vm.connect());
      await until(
        () => vm.event == MainViewEvent.showAlreadyConnectedDialog,
        seconds: 10,
      );
      expect(vm.event, MainViewEvent.showAlreadyConnectedDialog);
      expect(panel.ids.where((i) => i == '000'), hasLength(2));
      expect(panel.ids, contains('013'));
      expect(vm.isConnected, isFalse);
      expect(vm.isConnecting, isFalse);
      vm.dispose();
    }, timeout: const Timeout(Duration(seconds: 20)));

    test('unknown handshake reply → connection failed', () async {
      panel.connectReply = 'S*000#0#*E';
      final vm = MainViewModel(
        panel: panelAt(panel.port),
        socketRepository: SocketRepository(),
      );
      await vm.connect();
      expect(vm.isConnected, isFalse);
      expect(vm.event, MainViewEvent.showConnectionFailedToast);
      vm.dispose();
    });

    test('panel unreachable → connection failed', () async {
      final port = panel.port;
      await panel.close();
      final vm = MainViewModel(
        panel: panelAt(port),
        socketRepository: SocketRepository(),
      );
      await vm.connect();
      expect(vm.event, MainViewEvent.showConnectionFailedToast);
      expect(vm.isConnecting, isFalse);
      vm.dispose();
    });
  });

  group('LogsViewModel / LogEntry', () {
    final p = PanelData.fromJson({'pnl_id': 1});

    test('logs → success, parsed in order', () async {
      final vm = LogsViewModel(
        logsService: FakeLogs([
          {'event_name': 'Fire', 'event_time': '25-11-2026 10:09:15'},
        ]),
        panelData: p,
      );
      await until(() => vm.state != LogsState.loading);
      expect(vm.state, LogsState.success);
      expect(vm.logs.single.message, 'Fire');
      expect(vm.logs.single.timestamp, DateTime(2026, 11, 25, 10, 9, 15));
    });

    test('no logs → empty; service error → error', () async {
      final empty = LogsViewModel(
        logsService: FakeLogs(<Map<String, dynamic>>[]),
        panelData: p,
      );
      final err = LogsViewModel(
        logsService: FakeLogs(Exception('x')),
        panelData: p,
      );
      await until(
        () =>
            empty.state != LogsState.loading && err.state != LogsState.loading,
      );
      expect(empty.state, LogsState.empty);
      expect(err.state, LogsState.error);
    });

    test('LogEntry round-trips; missing name → "Unknown Event"', () {
      final e = LogEntry.fromJson({'event_time': '01-02-2026 03:04:05'});
      expect(e.message, 'Unknown Event');
      expect(LogEntry.fromJson(e.toJson()).timestamp, e.timestamp);
    });
  });
}
