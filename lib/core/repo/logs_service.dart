import 'dart:convert';
import 'package:dio/dio.dart';
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
    // Unique cache key for this specific panel's logs
    final String cacheKey = "logs_cache_$pnlId";

    try {
      final formData = FormData.fromMap({
        "pnl_id": pnlId,
        "usr_id": usrId,
        "ip_add": ipAdd,
        "port_no": port,
        "pnl_rcvr_no": rcvrNo,
        "pnl_acc_no": accNo,
        "pnl_line_no": lineNo,
        "pnl_mac": mac,
        "pnl_ver": ver,
      });

      // 🔥 LOG FULL REQUEST DETAILS
      print("=======================================");
      print("📡 FETCH LOGS REQUEST");
      print("URL: ${WebUrlConstants.baseUrl}${WebUrlConstants.fetchLogs}");
      print("Headers: {Usr: $usrId, Usr_type: USER}");
      print("=======================================");

      // 1. ATTEMPT NETWORK CALL
      final response = await _dio.post(
        WebUrlConstants.fetchLogs,
        data: formData,
        options: Options(
          headers: {
            "Usr": usrId,
            "Usr_type": "USER",
          },
        ),
      );

      // 🔥 LOG RAW RESPONSE
      print("=== RAW LOGS RESPONSE ===");
      print(response.data);

      if (response.data["status"] == true) {
        final List raw = response.data["logs"] ?? [];
        final List<Map<String, dynamic>> logs = raw.cast<Map<String, dynamic>>();

        // 2. SUCCESS: CACHE DATA LOCALLY
        _cacheLogs(cacheKey, logs);

        return logs;
      }

      return [];
    } catch (e) {
      print("❌ Logs API Error: $e");
      print("⚠️ Attempting to load cached logs...");

      // 3. FAILURE: LOAD FROM CACHE
      return await _getCachedLogs(cacheKey);
    }
  }

  // ---------------------------------------------------------------------------
  // PRIVATE CACHE HELPERS
  // ---------------------------------------------------------------------------

  Future<void> _cacheLogs(String key, List<Map<String, dynamic>> logs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(logs);
      await prefs.setString(key, encoded);
      print("✅ Cached ${logs.length} log entries for Panel $key");
    } catch (e) {
      print("❌ Failed to cache logs: $e");
    }
  }

  Future<List<Map<String, dynamic>>> _getCachedLogs(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(key);

      if (jsonString != null && jsonString.isNotEmpty) {
        final List decoded = jsonDecode(jsonString);
        print("✅ Loaded ${decoded.length} logs from offline cache");
        return decoded.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print("❌ Failed to load cached logs: $e");
    }
    return [];
  }
}