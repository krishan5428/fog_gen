// ignore_for_file: non_constant_identifier_names

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fog_gen_new/app/app_theme.dart';
import 'package:fog_gen_new/core/api/api_client.dart';
import 'package:fog_gen_new/core/data/pojo/panel_data.dart';
import 'package:fog_gen_new/core/repo/panel_repo.dart';
import 'package:fog_gen_new/core/repo/user_repo.dart';
import 'package:fog_gen_new/core/repo/vendor_repo.dart';
import 'package:fog_gen_new/core/responses/panel_response.dart';
import 'package:fog_gen_new/presentation/cubit/mappings/panel_sim_number_cubit.dart';
import 'package:fog_gen_new/presentation/cubit/mappings/site_cubit.dart';
import 'package:fog_gen_new/presentation/cubit/panel/panel_cubit.dart';
import 'package:fog_gen_new/presentation/cubit/user/user_cubit.dart';
import 'package:fog_gen_new/presentation/cubit/vendor/vendor_cubit.dart';
import 'package:fog_gen_new/utils/app_info.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';

/// Every HTTP call fails at once: no test may reach the real backend.
class NoNetworkAdapter implements HttpClientAdapter {
  final List<String> attempted = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    attempted.add(options.path);
    throw DioException.connectionError(
      requestOptions: options,
      reason: 'network disabled in tests',
    );
  }

  @override
  void close({bool force = false}) {}
}

class OfflinePanelRepo extends Fake implements PanelRepo {
  OfflinePanelRepo(this.panels);
  final List<PanelData> panels;

  @override
  Future<PanelResponse> getPanels(String userId) async =>
      PanelResponse(status: true, panelsData: panels, msg: '');
}

class NoUserRepo extends Fake implements UserRepo {}

class NoVendorRepo extends Fake implements VendorRepo {}

/// A panel pointing at a closed local port, so screens that open a TCP
/// session fail fast instead of reaching a real device.
PanelData testPanel({
  String name = 'FogShield Pro',
  String type = 'FOGGER PANEL',
  String imei = '',
  bool ipGsm = true,
}) => PanelData.fromJson({
  'pnl_id': 1,
  'usr_id': '3',
  'site_name': 'Test Site',
  'site_address': 'Addr',
  'panel_name': name,
  'pnl_type': type,
  'panel_sim_number': '9876543210',
  'admin_mobile_number': '9999999999',
  'ip_add': '127.0.0.1',
  'port_no': '1',
  'pass': '1234',
  'is_ip_gsm_panel': ipGsm,
  'panel_imei': imei,
});

bool _appInfoReady = false;
bool _fontsReady = false;

/// Real Montserrat instead of the test font (Ahem draws every glyph as a
/// full square, so text looks far wider than on a phone).
Future<void> _loadFonts() async {
  if (_fontsReady) return;
  final loader = FontLoader('Montserrat');
  for (final w in ['regular', 'medium', 'semibold', 'bold']) {
    final bytes = File('assets/fonts/montserrat_$w.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
  _fontsReady = true;
}

Future<void> setUpHarness() async {
  SharedPreferences.setMockInitialValues({
    'is_logged_in': true,
    'login_backend': 'fogshield',
    'user_id': 3,
    'user_data':
        '{"usr_id":3,"name":"Tester","email":"t@t.t","mobile":"9999999999"}',
  });
  FlutterSecureStorage.setMockInitialValues({'user_pass': 'secret'});
  PackageInfo.setMockInitialValues(
    appName: 'FogShield',
    packageName: 'com.securico.fogshield',
    version: '1.1.0',
    buildNumber: '14',
    buildSignature: '',
  );
  await _loadFonts();
  if (!_appInfoReady) {
    await AppInfo.instance.init(); // late final: once per test run
    _appInfoReady = true;
  }
  ApiClient.dio.httpClientAdapter = NoNetworkAdapter();
}

/// The app's providers + ScreenUtil around [screen].
Widget harness(
  Widget screen, {
  List<PanelData> panels = const [],
  UserRepo? userRepo,
}) {
  final users = userRepo ?? NoUserRepo();
  return MultiProvider(
    providers: [Provider<UserRepo>(create: (_) => users)],
    child: MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => UserCubit(users)),
        BlocProvider(create: (_) => PanelCubit(OfflinePanelRepo(panels))),
        BlocProvider(create: (_) => VendorCubit(NoVendorRepo())),
        BlocProvider(create: (_) => SiteCubit()),
        BlocProvider(create: (_) => PanelSimNumberCubit()),
      ],
      child: ToastificationWrapper(
        child: ScreenUtilInit(
          designSize: const Size(400, 850),
          builder: (_, __) =>
              MaterialApp(theme: AppTheme.lightTheme, home: screen),
        ),
      ),
    ),
  );
}
