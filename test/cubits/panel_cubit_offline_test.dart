// ignore_for_file: non_constant_identifier_names
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fog_gen_new/core/data/pojo/panel_data.dart';
import 'package:fog_gen_new/core/repo/panel_repo.dart';
import 'package:fog_gen_new/core/responses/add_panel_response.dart';
import 'package:fog_gen_new/core/responses/delete_panel_response.dart';
import 'package:fog_gen_new/core/responses/panel_response.dart';
import 'package:fog_gen_new/core/responses/update_panel_response.dart';
import 'package:fog_gen_new/presentation/cubit/panel/panel_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

PanelData panel(int id, {String site = 'S'}) =>
    PanelData.fromJson({'pnl_id': id, 'usr_id': '3', 'site_name': site});

/// Server double with an on/off "network".
class FakeServer extends Fake implements PanelRepo {
  bool online = true;
  List<PanelData> panels = [panel(1, site: 'One')];
  final List<String> calls = [];
  UpdatePanelResponse? updateReply;
  bool serverUpdatedNoData = false;

  void _net() {
    if (!online) throw Exception('SocketException: no network');
  }

  @override
  Future<PanelResponse> getPanels(String userId) async {
    calls.add('get');
    _net();
    return PanelResponse(status: true, panelsData: panels, msg: '');
  }

  @override
  Future<AddPanelResponse> addPanel({
    required String userId,
    required String panelType,
    required String panelName,
    required String site,
    required String panelSimNumber,
    required String adminCode,
    required String adminMobileNumber,
    required String mobileNumberSubId,
    required String mobileNumber1,
    required String mobileNumber2,
    required String mobileNumber3,
    required String mobileNumber4,
    required String mobileNumber5,
    required String mobileNumber6,
    required String mobileNumber7,
    required String mobileNumber8,
    required String mobileNumber9,
    required String mobileNumber10,
    required String address,
    required String cOn,
    required String ip_address,
    required String port_no,
    required String static_ip_address,
    required String static_port_no,
    required String password,
    required bool is_ip_panel,
    required bool is_ip_gsm_panel,
    required String panel_acc_no,
    required String mac_id,
    required String version,
    String imei = '',
  }) async {
    calls.add('add $site');
    _net();
    panels = [...panels, panel(panels.length + 1, site: site)];
    return AddPanelResponse(status: true, msg: 'Added');
  }

  @override
  Future<DeletePanelResponse> deletePanel(String userId, int panelId) async {
    calls.add('delete $panelId');
    _net();
    panels = panels.where((p) => p.pnlId != panelId).toList();
    return DeletePanelResponse(status: true, msg: 'ok');
  }

  @override
  Future<UpdatePanelResponse> updatePanelData(
    String userId,
    int panelId,
    String key,
    String value,
  ) async {
    calls.add('update $panelId $key=$value');
    _net();
    if (serverUpdatedNoData) {
      throw const FormatException('SERVER_UPDATED_BUT_NO_DATA');
    }
    return updateReply ??
        UpdatePanelResponse(status: true, msg: 'ok', panelData: panel(panelId));
  }
}

void addFog(PanelCubit c, String site) => c.addPanel(
  userId: '3',
  panelType: 'FOGGER PANEL',
  panelName: 'FogShield Pro',
  site: site,
  panelSimNumber: '9876543210',
  adminCode: '1234',
  adminMobileNumber: '9999999999',
  mobileNumberSubId: '0',
  mobileNumber1: '',
  mobileNumber2: '',
  mobileNumber3: '',
  mobileNumber4: '',
  mobileNumber5: '',
  mobileNumber6: '',
  mobileNumber7: '',
  mobileNumber8: '',
  mobileNumber9: '',
  mobileNumber10: '',
  address: 'A',
  cOn: '',
  is_ip_gsm_panel: false,
  is_ip_panel: true,
  ip_address: '1.2.3.4',
  port_no: '5000',
  static_ip_address: '',
  static_port_no: '',
  password: '1234',
  panel_acc_no: '999999',
  mac_id: 'mac',
  version: 'V1',
);

Future<T> next<T>(PanelCubit c) =>
    c.stream.firstWhere((s) => s is T).then((s) => s as T).timeout(
      const Duration(seconds: 3),
    );

/// Waits until the list shown contains exactly [sites].
Future<void> shows(PanelCubit c, List<String> sites) => c.stream
    .firstWhere(
      (s) =>
          s is GetPanelsSuccess &&
          s.panelsData.map((p) => p.siteName).toList().toString() ==
              sites.toString(),
    )
    .timeout(const Duration(seconds: 3));

/// Waits until the server has seen [n] list fetches (the cubit's own
/// refresh after an add/delete has then finished its sync attempt).
Future<void> fetches(FakeServer s, int n) async {
  for (var i = 0; i < 300 && s.calls.where((c) => c == 'get').length < n; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  await Future<void>.delayed(const Duration(milliseconds: 10));
}

Future<List<dynamic>> pending(String key) async {
  final s = (await SharedPreferences.getInstance()).getString(key);
  return s == null || s.isEmpty ? [] : json.decode(s) as List;
}

void main() {
  late FakeServer server;
  late PanelCubit cubit;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    server = FakeServer();
    cubit = PanelCubit(server);
  });
  tearDown(() => cubit.close());

  test('getPanel online: shows server list and caches it', () async {
    final f = shows(cubit, ['One']);
    cubit.getPanel(userId: '3');
    await f;
    final cached = (await SharedPreferences.getInstance()).getString(
      PanelCubit.CACHED_PANELS_KEY,
    );
    expect(cached, contains('One'));
  });

  test('getPanel offline: shows the cached list', () async {
    var f = shows(cubit, ['One']);
    cubit.getPanel(userId: '3');
    await f;
    server.online = false;
    server.panels = [];
    f = shows(cubit, ['One']);
    cubit.getPanel(userId: '3');
    await f;
  });

  test('add offline → "Saved Offline.", queued, sent on next online refresh',
      () async {
    server.online = false;
    final ok = next<AddPanelSuccess>(cubit);
    addFog(cubit, 'Off');
    expect((await ok).message, 'Saved Offline.');
    await fetches(server, 1);
    expect(await pending(PanelCubit.PENDING_ADDS_KEY), hasLength(1));

    server.online = true;
    final f = shows(cubit, ['One', 'Off']);
    cubit.getPanel(userId: '3');
    await f;
    // 1 offline add + 1 failed offline sync + 1 successful sync.
    expect(server.calls.where((c) => c == 'add Off'), hasLength(3));
    expect(server.panels.where((p) => p.siteName == 'Off'), hasLength(1));
    expect(await pending(PanelCubit.PENDING_ADDS_KEY), isEmpty);
  });

  test('delete offline → removed from cache, queued, sent when online',
      () async {
    var f = shows(cubit, ['One']);
    cubit.getPanel(userId: '3');
    await f;

    server.online = false;
    final ok = next<DeletePanelsSuccess>(cubit);
    cubit.deletePanel(userId: '3', panelId: 1);
    expect((await ok).msg, 'Deleted Offline');
    await fetches(server, 2);
    expect(await pending(PanelCubit.PENDING_DELETES_KEY), [
      {'id': 1},
    ]);

    server.online = true;
    cubit.getPanel(userId: '3');
    await fetches(server, 3);
    expect(server.panels, isEmpty);
    expect(await pending(PanelCubit.PENDING_DELETES_KEY), isEmpty);
  });

  test('update offline → local cache changed, queued, sent when online',
      () async {
    var f = shows(cubit, ['One']);
    cubit.getPanel(userId: '3');
    await f;

    server.online = false;
    final ok = next<UpdatePanelsSuccess>(cubit);
    cubit.updatePanelData(
      userId: '3',
      panelId: 1,
      key: 'site_name',
      value: 'Renamed',
    );
    final s = await ok;
    expect(s.msg, 'Updated Offline');
    expect(s.panelData.siteName, 'Renamed');
    expect(await pending(PanelCubit.PENDING_UPDATES_KEY), hasLength(1));

    server.online = true;
    final synced = cubit.stream.firstWhere((s) => s is GetPanelsSuccess);
    cubit.getPanel(userId: '3');
    await synced;
    await Future<void>.delayed(Duration.zero);
    expect(server.calls, contains('update 1 site_name=Renamed'));
    expect(await pending(PanelCubit.PENDING_UPDATES_KEY), isEmpty);
  });

  test('server saved but returned no data → success, not queued', () async {
    var f = shows(cubit, ['One']);
    cubit.getPanel(userId: '3');
    await f;
    server.serverUpdatedNoData = true;
    final ok = next<UpdatePanelsSuccess>(cubit);
    cubit.updatePanelData(
      userId: '3',
      panelId: 1,
      key: 'site_name',
      value: 'X',
    );
    expect((await ok).msg, 'Updated Successfully');
    expect(await pending(PanelCubit.PENDING_UPDATES_KEY), isEmpty);
  });

  test('server rejects an update → failure, not queued offline', () async {
    server.updateReply = UpdatePanelResponse(status: false, msg: 'Denied');
    final bad = next<UpdatePanelsFailure>(cubit);
    cubit.updatePanelData(
      userId: '3',
      panelId: 1,
      key: 'site_name',
      value: 'X',
    );
    expect((await bad).message, 'Denied');
    expect(await pending(PanelCubit.PENDING_UPDATES_KEY), isEmpty);
  });

  test('two refreshes at once send a queued offline add only once', () async {
    server.online = false;
    final ok = next<AddPanelSuccess>(cubit);
    addFog(cubit, 'Off');
    await ok;
    await fetches(server, 1);

    server.online = true;
    // e.g. the list screen refreshing while a pull-to-refresh runs.
    cubit.getPanel(userId: '3');
    cubit.getPanel(userId: '3');
    await fetches(server, 3);

    expect(
      server.panels.where((p) => p.siteName == 'Off'),
      hasLength(1),
      reason: 'the queued panel was added to the server twice',
    );
    expect(await pending(PanelCubit.PENDING_ADDS_KEY), isEmpty);
  });

  test('resetState forgets the list held in memory (logout)', () async {
    final f = shows(cubit, ['One']);
    cubit.getPanel(userId: '3');
    await f;
    cubit.resetState();
    expect(cubit.state, isA<PanelInitial>());
  });
}
