import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fog_gen_new/core/data/pojo/user_data.dart';
import 'package:fog_gen_new/core/data/pojo/vendor_data.dart';
import 'package:fog_gen_new/presentation/cubit/panel/panel_cubit.dart';
import 'package:fog_gen_new/utils/auth_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('login state, user id and device type round-trip', () async {
    expect(await SharedPreferenceHelper.getLoginState(), isFalse);
    await SharedPreferenceHelper.setLoginState(true, 17, 'android');
    expect(await SharedPreferenceHelper.getLoginState(), isTrue);
    expect(await SharedPreferenceHelper.getUserId(), 17);
    expect(await SharedPreferenceHelper.getDeviceType(), 'android');
  });

  test('user, vendor, FCM token and per-SIM ids round-trip', () async {
    await SharedPreferenceHelper.saveUserData(
      UserData.fromJson({'usr_id': 17, 'name': 'A'}),
    );
    expect((await SharedPreferenceHelper.getUserData())!.name, 'A');

    await SharedPreferenceHelper.saveVendorData(
      VendorData.fromJson({'user_id': '17', 'vendor_name': 'V'}),
    );
    expect((await SharedPreferenceHelper.getVendorData())!.vendor_name, 'V');

    await SharedPreferenceHelper.saveDeviceToken('tok');
    expect(await SharedPreferenceHelper.getDeviceToken(), 'tok');

    await SharedPreferenceHelper.setFireIdForPanelSimNumber('98', 'f1');
    await SharedPreferenceHelper.setIntruIdForPanelSimNumber('98', 'i1');
    expect(await SharedPreferenceHelper.getFireIdForPanelSimNumber('98'), 'f1');
    await SharedPreferenceHelper.clearIdsForPanelSimNumber('98');
    expect(
      await SharedPreferenceHelper.getIntruIdForPanelSimNumber('98'),
      null,
    );
  });

  test('logout removes everything that belongs to the previous user', () async {
    // User A logged in, has a cached list and an unsynced offline action.
    await SharedPreferenceHelper.setLoginState(true, 17, 'android');
    await SharedPreferenceHelper.saveUserData(
      UserData.fromJson({'usr_id': 17, 'name': 'A'}),
    );
    await SharedPreferenceHelper.setPass('secret');
    await SharedPreferenceHelper.saveVendorData(
      VendorData.fromJson({'user_id': '17', 'vendor_name': 'V'}),
    );
    for (final k in [
      PanelCubit.CACHED_PANELS_KEY,
      PanelCubit.PENDING_ADDS_KEY,
      PanelCubit.PENDING_UPDATES_KEY,
      PanelCubit.PENDING_DELETES_KEY,
      'logs_cache_12',
    ]) {
      await SharedPreferenceHelper.setString(k, '[{"pnl_id":12}]');
    }
    await SharedPreferenceHelper.saveDeviceToken('tok');

    await SharedPreferenceHelper.clearLoginState();

    expect(await SharedPreferenceHelper.getLoginState(), isFalse);
    expect(await SharedPreferenceHelper.getUserId(), isNull);
    expect(await SharedPreferenceHelper.getUserData(), isNull);
    expect(await SharedPreferenceHelper.getPass(), isNull);
    expect(await SharedPreferenceHelper.getVendorData(), isNull);
    for (final k in [
      PanelCubit.CACHED_PANELS_KEY,
      PanelCubit.PENDING_ADDS_KEY,
      PanelCubit.PENDING_UPDATES_KEY,
      PanelCubit.PENDING_DELETES_KEY,
      'logs_cache_12',
    ]) {
      expect(await SharedPreferenceHelper.getString(k), isNull, reason: k);
    }
    // The device's FCM token is not the user's; it stays.
    expect(await SharedPreferenceHelper.getDeviceToken(), 'tok');
  });

  test('password is kept in secure storage, never in plain prefs', () async {
    await SharedPreferenceHelper.setPass('secret');
    expect(await SharedPreferenceHelper.getPass(), 'secret');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('user_pass'), isNull);
  });

  test(
    'an old plain-text password is moved to secure storage on first read',
    () async {
      SharedPreferences.setMockInitialValues({'user_pass': 'old'});
      expect(await SharedPreferenceHelper.getPass(), 'old');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user_pass'), isNull);
      expect(await SharedPreferenceHelper.getPass(), 'old');
    },
  );

  test('a login saved by the old app (shared backend) is not trusted: '
      'logged out on start, so its user id never reads another user\'s data',
      () async {
    // Old app version: logged in, user id from tbl_user, no backend marker.
    SharedPreferences.setMockInitialValues({
      'is_logged_in': true,
      'user_id': 1,
      'user_data': '{"usr_id":1,"name":"Old"}',
      'cached_panel_list': '[{"pnl_id":5}]',
    });
    expect(await SharedPreferenceHelper.getLoginState(), isFalse);
    expect(await SharedPreferenceHelper.getUserId(), isNull);
    expect(await SharedPreferenceHelper.getUserData(), isNull);
    expect(await SharedPreferenceHelper.getString('cached_panel_list'), isNull);
  });

  test('a login made on the FogShield backend stays logged in', () async {
    await SharedPreferenceHelper.setLoginState(true, 1, 'android');
    expect(await SharedPreferenceHelper.getLoginState(), isTrue);
    expect(await SharedPreferenceHelper.getUserId(), 1);
  });
}

