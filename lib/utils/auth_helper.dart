import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceHelper {
  static const _keyIsLoggedIn = 'is_logged_in';
  static const _keyUserId = 'user_id';
  static const _keyDeviceType = 'device';
  static const _keyIsDialogShown = 'smsPermissionDialogShown';

  //save login state
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

  // get login state
  static Future<bool> getLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyIsLoggedIn) ?? false;
    } catch (e) {
      if (kDebugMode) {
        print("Error reading login state: $e");
      }
      return false;
    }
  }

  static Future<bool> setSmsDialogShown(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.setBool(_keyIsDialogShown, value);
    } catch (e) {
      if (kDebugMode) {
        print("Error setting SMS DIALOG: $e");
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
        print("Error getting SMS DIALOG: $e");
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
        print("Error reading login state: $e");
      }
      return '';
    }
  }

  // get user id
  static Future<int?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_keyUserId);
    } catch (e) {
      print("Error reading userId: $e");
    }
    return null;
  }

  // clear login state
  static Future<void> clearLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyDeviceType);
    await prefs.remove(_keyIsDialogShown);
  }
}
