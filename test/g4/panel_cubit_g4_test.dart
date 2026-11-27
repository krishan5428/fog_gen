// ignore_for_file: non_constant_identifier_names

import 'package:flutter_test/flutter_test.dart';
import 'package:fog_gen_new/constants/strings.dart';
import 'package:fog_gen_new/core/repo/panel_repo.dart';
import 'package:fog_gen_new/core/responses/add_panel_response.dart';
import 'package:fog_gen_new/core/responses/delete_panel_response.dart';
import 'package:fog_gen_new/core/responses/panel_response.dart';
import 'package:fog_gen_new/features/mqtt/repository/fourg_repository.dart';
import 'package:fog_gen_new/presentation/cubit/panel/panel_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Server double: records add/delete calls.
class FakePanelRepo extends Fake implements PanelRepo {
  AddPanelResponse addResponse = AddPanelResponse(
    status: true,
    msg: 'Added',
    panelAccNo: '004521',
    pnlId: 200333,
  );
  bool throwOnAdd = false;
  final List<Map<String, Object?>> added = [];
  final List<int> deleted = [];

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
    if (throwOnAdd) throw Exception('network down');
    added.add({
      'panelType': panelType,
      'imei': imei,
      'password': password,
      'panel_acc_no': panel_acc_no,
    });
    return addResponse;
  }

  @override
  Future<DeletePanelResponse> deletePanel(String userId, int panelId) async {
    deleted.add(panelId);
    return DeletePanelResponse(status: true, msg: 'ok');
  }

  @override
  Future<PanelResponse> getPanels(String userId) async =>
      PanelResponse(status: true, panelsData: const [], msg: '');
}

/// Panel double: answers like a real G4 panel unless told otherwise.
class FakeFourG extends Fake implements FourGRepository {
  bool handshakeOk = true;
  String? deviceIdReply; // null → echo the written ID
  String? telephoneReply; // null → echo the written admin number
  String? destinationReply =
      r'ST*861919084418721$100$03$01$013$02$1$182.73.129.27$05600$0$0.0.0.0$00000*ED';
  final List<String> calls = [];
  String? _writtenId;
  String? _writtenAdmin;

  @override
  Future<bool> connectPanel({
    required String imei,
    required String passcode,
  }) async {
    calls.add('connect $imei $passcode');
    return handshakeOk;
  }

  @override
  Future<void> assignPanelId({
    required String imei,
    required String passcode,
    required String panelId,
  }) async {
    calls.add('writeId $panelId');
    _writtenId = panelId;
  }

  @override
  Future<String?> readPanelId({
    required String imei,
    required String passcode,
  }) async {
    calls.add('readId');
    return deviceIdReply ??
        'ST*$imei\$100\$03\$01\$013\$01\$$_writtenId\$000001\$000000*ED';
  }

  @override
  Future<void> assignAdminNumber({
    required String imei,
    required String passcode,
    required String adminNumber,
  }) async {
    calls.add('writeAdmin $adminNumber');
    _writtenAdmin = adminNumber;
  }

  @override
  Future<String?> readTelephoneSettings({
    required String imei,
    required String passcode,
  }) async {
    calls.add('readAdmin');
    return telephoneReply ??
        'ST*$imei\$100\$03\$01\$008\$4#+91#$_writtenAdmin\$0#+91#0*ED';
  }

  @override
  Future<bool> assignDestinationSettings({
    required String imei,
    required String passcode,
    String type = "1",
    String ip = "182.73.129.27",
    String port = "05600",
    String ip2 = "0.0.0.0",
    String port2 = "00000",
  }) async {
    calls.add('writeDest');
    return true;
  }

  @override
  Future<String?> readDestinationSettings({
    required String imei,
    required String passcode,
  }) async {
    calls.add('readDest');
    return destinationReply;
  }
}

const imei = '861919084418721';
final g4Name = fourGComPanels.first;

void add(PanelCubit cubit, {String panelName = '', String imeiValue = imei}) {
  cubit.addPanel(
    userId: '3',
    panelType: fourGComPanelType,
    panelName: panelName.isEmpty ? g4Name : panelName,
    site: 'Site A',
    panelSimNumber: '9876543210',
    adminCode: '1234',
    adminMobileNumber: '9991945637',
    mobileNumberSubId: '0',
    mobileNumber1: '0000000000',
    mobileNumber2: '0000000000',
    mobileNumber3: '0000000000',
    mobileNumber4: '0000000000',
    mobileNumber5: '0000000000',
    mobileNumber6: '0000000000',
    mobileNumber7: '0000000000',
    mobileNumber8: '0000000000',
    mobileNumber9: '0000000000',
    mobileNumber10: '0000000000',
    address: 'Addr',
    cOn: '2026-11-25',
    is_ip_gsm_panel: false,
    is_ip_panel: false,
    ip_address: '',
    port_no: '',
    static_ip_address: '',
    static_port_no: '',
    password: '1234',
    panel_acc_no: '',
    mac_id: '',
    version: '',
    imei: imeiValue,
  );
}

/// First AddPanelSuccess / AddPanelFailure the cubit emits.
Future<PanelState> addResult(PanelCubit cubit) => cubit.stream
    .firstWhere((s) => s is AddPanelSuccess || s is AddPanelFailure)
    .timeout(const Duration(seconds: 5));

/// After a success the cubit refreshes the list; let it finish before close.
Future<void> listRefreshed(PanelCubit cubit) => cubit.stream
    .firstWhere((s) => s is GetPanelsSuccess || s is GetPanelsFailure)
    .timeout(const Duration(seconds: 5));

void main() {
  late FakePanelRepo server;
  late FakeFourG panel;
  late PanelCubit cubit;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    server = FakePanelRepo();
    panel = FakeFourG();
    cubit = PanelCubit(server, panel)..fourGWriteSettle = Duration.zero;
  });

  tearDown(() => cubit.close());

  test(
    'all checks pass → success, saved as 4GCOM with IMEI, nothing deleted',
    () async {
      final result = addResult(cubit);
      add(cubit);
      final s = await result;
      await listRefreshed(cubit);

      expect(s, isA<AddPanelSuccess>());
      expect((s as AddPanelSuccess).panelAccNo, '004521');
      expect(server.added.single['panelType'], '4GCOM');
      expect(server.added.single['imei'], imei);
      expect(server.added.single['password'], '001234');
      expect(server.deleted, isEmpty);
      expect(panel.calls, [
        'connect $imei 001234',
        'writeId 004521',
        'readId',
        'writeAdmin 9991945637',
        'readAdmin',
        'writeDest',
        'readDest',
      ]);
    },
  );

  test('handshake fails → nothing saved on the server', () async {
    panel.handshakeOk = false;
    final result = addResult(cubit);
    add(cubit);
    final s = await result;

    expect((s as AddPanelFailure).message, 'Device MQTT handshake failed');
    expect(server.added, isEmpty);
    expect(server.deleted, isEmpty);
  });

  test('server add throws → failure, not saved offline', () async {
    server.throwOnAdd = true;
    final result = addResult(cubit);
    add(cubit);
    final s = await result;

    expect(s, isA<AddPanelFailure>());
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(PanelCubit.PENDING_ADDS_KEY), isNull);
  });

  test(
    'server returns no account number → rollback, no device writes',
    () async {
      server.addResponse = AddPanelResponse(status: true, msg: 'ok', pnlId: 9);
      final result = addResult(cubit);
      add(cubit);
      final s = await result;

      expect((s as AddPanelFailure).message, contains('Device removed'));
      expect(server.deleted, [9]);
      expect(panel.calls.where((c) => c.startsWith('write')), isEmpty);
    },
  );

  test('Device ID read-back mismatch → rollback', () async {
    panel.deviceIdReply =
        r'ST*861919084418721$100$03$01$013$01$999999$000001$000000*ED';
    final result = addResult(cubit);
    add(cubit);
    final s = await result;

    expect(
      (s as AddPanelFailure).message,
      'Device ID verification failed. Device removed.',
    );
    expect(server.deleted, [200333]);
    expect(panel.calls, isNot(contains('writeAdmin 9991945637')));
  });

  test('admin number not on the panel → rollback', () async {
    panel.telephoneReply = r'ST*861919084418721$100$03$01$008$0#+91#0*ED';
    final result = addResult(cubit);
    add(cubit);
    final s = await result;

    expect(
      (s as AddPanelFailure).message,
      'Admin Number verification failed. Device removed.',
    );
    expect(server.deleted, [200333]);
  });

  test('destination read times out (null) → rollback', () async {
    panel.destinationReply = null;
    final result = addResult(cubit);
    add(cubit);
    final s = await result;

    expect((s as AddPanelFailure).message, contains('destination'));
    expect(server.deleted, [200333]);
  });

  test('wrong destination IP → rollback', () async {
    panel.destinationReply =
        r'ST*861919084418721$100$03$01$013$02$1$10.0.0.1$05600*ED';
    final result = addResult(cubit);
    add(cubit);
    final s = await result;

    expect(
      (s as AddPanelFailure).message,
      'Destination verification failed. Device removed.',
    );
    expect(server.deleted, [200333]);
  });

  test('non-G4 panel never touches MQTT and sends no IMEI', () async {
    server.addResponse = AddPanelResponse(status: true, msg: 'Added');
    final result = addResult(cubit);
    add(cubit, panelName: 'FogShield Pro', imeiValue: '');
    final s = await result;
    await listRefreshed(cubit);

    expect(s, isA<AddPanelSuccess>());
    expect(panel.calls, isEmpty);
    expect(server.added.single['imei'], '');
  });
}
