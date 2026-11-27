import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/data/pojo/user_data.dart';
import '../core/data/pojo/vendor_data.dart';
import 'package:fog_gen_new/core/logging/app_logger.dart';

class SharedPreferenceHelper {
  static const _keyIsLoggedIn = 'is_logged_in';
  static const _keyUserId = 'user_id';
  static const _keyDeviceType = 'device';
  static const _keyIsDialogShown = 'smsPermissionDialogShown';
  static const _keyUser = "user_data";
  static const _keyPass = 'user_pass';
  static const _keyVendor = "vendor_data";
  static const String userTokenKey = "fcm_device_token";
  static const _intruKeyPrefix = 'intruId_';
  static const _fireKeyPrefix = 'fireId_';

  // Cache keys
  static const String _keyCachedPanels = "cached_panel_list";

  // --- Login State ---
  static Future<void> setLoginState(
    bool isLoggedIn,
    int userId,
    String deviceType,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, isLoggedIn);
    await prefs.setInt(_keyUserId, userId);
    await prefs.setString(_keyDeviceType, deviceType);
  }

  static Future<bool> getLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyIsLoggedIn) ?? false;
    } catch (e) {
      if (kDebugMode) {
        AppLogger.d("Error reading login state: $e");
      }
      return false;
    }
  }

  // --- SMS Dialog ---
  static Future<bool> setSmsDialogShown(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(_keyIsDialogShown, value);
    } catch (e) {
      if (kDebugMode) {
        AppLogger.d("Error setting SMS DIALOG: $e");
      }
      return false;
    }
  }

  static Future<bool> getSmsDialogShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyIsDialogShown) ?? false;
    } catch (e) {
      if (kDebugMode) {
        AppLogger.d("Error getting SMS DIALOG: $e");
      }
      return false;
    }
  }

  static Future<String> getDeviceType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyDeviceType) ?? '';
    } catch (e) {
      if (kDebugMode) {
        AppLogger.d("Error reading login state: $e");
      }
      return '';
    }
  }

  // --- User ID ---
  static Future<int?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_keyUserId);
    } catch (e) {
      AppLogger.d("Error reading userId: $e");
    }
    return null;
  }

  // --- Clear State ---
  // Removes everything that belongs to the user who is logging out, so the
  // next user on this device never sees their profile, password or panel
  // list, and their unsynced offline actions are never replayed under the
  // next user's id. (Unsynced offline actions of the old user are dropped.)
  // The FCM device token stays: it belongs to the device, not the user.
  static Future<void> clearLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyDeviceType);
    await prefs.remove(_keyIsDialogShown);
    await prefs.remove(_keyUser);
    await prefs.remove(_keyPass);
    await _deletePass();
    await prefs.remove(_keyVendor);
    for (final key in prefs.getKeys().toList()) {
      if (_userCacheKeys.contains(key) || key.startsWith('logs_cache_')) {
        await prefs.remove(key);
      }
    }
  }

  // Panel list cache + offline queues (PanelCubit keys).
  static const _userCacheKeys = {
    _keyCachedPanels,
    'pending_panels_list',
    'pending_updates_list',
    'pending_deletes_list',
  };

  // --- User Data ---
  static Future<void> saveUserData(UserData user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = jsonEncode(user.toJson());
    await prefs.setString(_keyUser, userJson);
  }

  static Future<UserData?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyUser);
    if (jsonString != null) {
      final jsonMap = jsonDecode(jsonString);
      return UserData.fromJson(jsonMap);
    }
    return null;
  }

  // The login password is needed later (profile: change password / delete
  // account), so it is kept — in the Keychain/Keystore, not plain prefs.
  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static Future<void> setPass(String pass) async {
    await _secure.write(key: _keyPass, value: pass);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPass); // plain copy from older app versions
  }

  static Future<String?> getPass() async {
    try {
      final stored = await _secure.read(key: _keyPass);
      if (stored != null) return stored;

      // Older versions kept it in plain SharedPreferences: move it.
      final prefs = await SharedPreferences.getInstance();
      final legacy = prefs.getString(_keyPass);
      if (legacy != null) {
        await _secure.write(key: _keyPass, value: legacy);
        await prefs.remove(_keyPass);
      }
      return legacy;
    } catch (e) {
      AppLogger.d("Error reading pass: $e");
    }
    return null;
  }

  static Future<void> _deletePass() async {
    try {
      await _secure.delete(key: _keyPass);
    } catch (e) {
      AppLogger.d("Error deleting pass: $e");
    }
  }

  // --- Vendor Data ---
  static Future<VendorData?> getVendorData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyVendor);
    if (jsonString != null) {
      final jsonMap = jsonDecode(jsonString);
      return VendorData.fromJson(jsonMap);
    }
    return null;
  }

  static Future<void> saveVendorData(VendorData vendorData) async {
    final prefs = await SharedPreferences.getInstance();
    final vendorJson = jsonEncode(vendorData.toJson());
    await prefs.setString(_keyVendor, vendorJson);
  }

  static Future<void> clearVendorData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyVendor);
  }

  // --- Intrusion / Fire IDs ---
  static Future<void> setIntruIdForPanelSimNumber(
    String simNumber,
    String intruId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_intruKeyPrefix$simNumber', intruId);
  }

  static Future<void> setFireIdForPanelSimNumber(
    String simNumber,
    String fireId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_fireKeyPrefix$simNumber', fireId);
  }

  static Future<String?> getIntruIdForPanelSimNumber(String simNumber) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_intruKeyPrefix$simNumber');
  }

  static Future<String?> getFireIdForPanelSimNumber(String simNumber) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_fireKeyPrefix$simNumber');
  }

  static Future<void> clearIdsForPanelSimNumber(String simNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_intruKeyPrefix$simNumber');
    await prefs.remove('$_fireKeyPrefix$simNumber');
  }

  // --- Specific Cached Panel Methods ---
  static Future<void> setCachedPanels(String jsonString) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCachedPanels, jsonString);
  }

  static Future<String?> getCachedPanels() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCachedPanels);
  }

  // =========================================================
  //  NEW GENERIC METHODS (Fixes "getString" errors in Cubit)
  // =========================================================

  /// Generic getter for any String key
  static Future<String?> getString(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (e) {
      if (kDebugMode) {
        AppLogger.d("Error getting string for key $key: $e");
      }
      return null;
    }
  }

  /// Generic setter for any String key
  static Future<void> setString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (e) {
      if (kDebugMode) {
        AppLogger.d("Error setting string for key $key: $e");
      }
    }
  }

  static Future<bool> saveDeviceToken(String token) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return await prefs.setString(userTokenKey, token);
  }

  /// 3. Get the saved FCM Token (to compare)
  static Future<String?> getDeviceToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(userTokenKey);
  }
}
