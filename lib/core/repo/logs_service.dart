import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../api/web_url_constants.dart';

class LogsService {
  final Dio _dio = ApiClient.dio;

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
    final String cacheKey = "logs_cache_$pnlId";

    try {
      // 1. Prepare Payload
      final Map<String, String> payload = {
        "pnl_id": pnlId,
        "usr_id": usrId,
        "ip_add": ipAdd,
        "port_no": port,
        "pnl_rcvr_no": rcvrNo,
        "pnl_acc_no": accNo,
        "pnl_line_no": lineNo,
        "pnl_mac": mac,
        "pnl_ver": ver,
      };

      final formData = FormData.fromMap(payload);

      final headers = {"Usr": usrId, "Usr_type": "USER"};

      final response = await _dio.post(
        WebUrlConstants.fetchLogs,
        data: formData,
        options: Options(headers: headers),
      );

      // 3. Handle Response
      if (response.statusCode == 200 && response.data["status"] == true) {
        final List raw = response.data["logs"] ?? [];
        final List<Map<String, dynamic>> logs = raw
            .cast<Map<String, dynamic>>();

        // Cache on success
        _cacheLogs(cacheKey, logs);
        return logs;
      } else {
        debugPrint(
          "⚠️ API returned status false or error: ${response.data['msg']}",
        );
        return [];
      }
    } catch (e) {
      if (e is DioException) {
        debugPrint("❌ DIO ERROR: ${e.response?.statusCode} - ${e.message}");
        debugPrint("❌ RESPONSE: ${e.response?.data}");
      } else {
        debugPrint("❌ UNKNOWN ERROR: $e");
      }

      debugPrint("⚠️ Loading cached logs due to error...");
      return await _getCachedLogs(cacheKey);
    }
  }

  // ... (Keep your _cacheLogs and _getCachedLogs methods same as before)
  Future<void> _cacheLogs(String key, List<Map<String, dynamic>> logs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(logs));
    } catch (e) {
      debugPrint("Cache Error: $e");
    }
  }

  Future<List<Map<String, dynamic>>> _getCachedLogs(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(key);
      if (jsonString != null) {
        final List decoded = jsonDecode(jsonString);
        return decoded.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }
}
