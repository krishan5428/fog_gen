import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/data/pojo/user_data.dart';
import '../core/data/pojo/vendor_data.dart';

class SharedPreferenceHelper {
  static const _keyIsLoggedIn = 'is_logged_in';
  static const _keyUserId = 'user_id';
  static const _keyDeviceType = 'device';
  static const _keyIsDialogShown = 'smsPermissionDialogShown';
  static const _keyUser = "user_data";
  static const _keyPass = 'user_pass';
  static const _keyVendor = "vendor_data";

  static const _intruKeyPrefix = 'intruId_';
  static const _fireKeyPrefix = 'fireId_';

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

  static Future<void> setPass(String pass) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPass, pass);
  }

  static Future<String?> getPass() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyPass);
    } catch (e) {
      print("Error reading pass: $e");
    }
    return null;
  }

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
}
