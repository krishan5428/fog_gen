import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../api/api_client.dart';
import '../../api/web_url_constants.dart';
import '../../repo/panel_repo.dart';
import '../../responses/add_panel_response.dart';
import '../../responses/delete_panel_response.dart';
import '../../responses/panel_response.dart';
import '../../responses/update_panel_response.dart';

class PanelRepositoryImpl implements PanelRepo {
  final Dio _dio = ApiClient.dio;

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
    required bool is_ip_gsm_panel,
    required bool is_ip_panel,
    required String ip_address,
    required String port_no,
    required String static_ip_address,
    required String static_port_no,
    required String password,
    required String panel_acc_no,
    required String mac_id,
    required String version,
  }) async {
    try {
      final formData = FormData.fromMap({
        'usr_id': userId,
        'app_type': 'FogShield',
        'pnl_type': panelType,
        'panel_name': panelName,
        'site_name': site,
        'site_address': address,
        'panel_sim_number': panelSimNumber,
        'admin_code': adminCode,
        'admin_mobile_number': adminMobileNumber,
        'mobile_number_sub_id': mobileNumberSubId,
        'mobile_number1': mobileNumber1,
        'mobile_number2': mobileNumber2,
        'mobile_number3': mobileNumber3,
        'mobile_number4': mobileNumber4,
        'mobile_number5': mobileNumber5,
        'mobile_number6': mobileNumber6,
        'mobile_number7': mobileNumber7,
        'mobile_number8': mobileNumber8,
        'mobile_number9': mobileNumber9,
        'mobile_number10': mobileNumber10,
        'c_on': cOn,
        'ip_add': ip_address,
        'port_no': port_no,
        'static_ip': static_ip_address,
        'static_port': static_port_no,
        'pass': password,
        'is_ip_panel': is_ip_panel ? 1 : 0,
        'is_ip_gsm_panel': is_ip_gsm_panel ? 1 : 0,
        'pnl_acc_no' :panel_acc_no,
        'pnl_mac': mac_id,
        'pnl_ver': version,
      });

      final response = await _dio.post(
        WebUrlConstants.addPanel,
        data: formData,
      );

      return AddPanelResponse.fromJson(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in addPanel: $e');
      }
      rethrow;
    }
  }

  @override
  Future<PanelResponse> getPanels(
      String userId, {
        String appType = 'FogShield',
      }) async {
    final formData = FormData.fromMap({
      'usr_id': userId,
      'app_type': appType,
    });

    try {
      final response = await _dio.post(
        WebUrlConstants.getAllPanels,
        data: formData,
      );

      return PanelResponse.fromJson(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in getPanels: $e');
      }
      rethrow;
    }
  }

  @override
  Future<DeletePanelResponse> deletePanel(String userId, int panelId) async {
    final formData = FormData.fromMap({
      'pnl_id': panelId,
      'usr_id': userId,
    });

    try {
      final response = await _dio.post(
        WebUrlConstants.deletePanel,
        data: formData,
      );

      return DeletePanelResponse.fromJson(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in deletePanel: $e');
      }
      rethrow;
    }
  }

  @override
  Future<UpdatePanelResponse> updatePanelData(
      String userId,
      int panelId,
      String key,
      String value,
      ) async {
    // Standard key directly as provided (must match API server keys)
    final formData = FormData.fromMap({
      'pnl_id': panelId,
      'usr_id': userId,
      key: value,
    });

    try {
      final response = await _dio.post(
        WebUrlConstants.updatePanel,
        data: formData,
      );

      return UpdatePanelResponse.fromJson(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in updatePanelData: $e');
      }
      rethrow;
    }
  }

  @override
  Future<UpdatePanelResponse> updatePanelDataInList(
      String userId,
      int panelId,
      List<String> keys,
      List<dynamic> values,
      ) async {
    final Map<String, dynamic> formMap = {
      'pnl_id': panelId,
      'usr_id': userId,
    };

    for (int i = 0; i < keys.length; i++) {
      // Keys are used directly as provided (must match API server keys)
      formMap[keys[i]] = values[i];
    }

    final formData = FormData.fromMap(formMap);

    try {
      final response = await _dio.post(
        WebUrlConstants.updatePanel,
        data: formData,
      );

      return UpdatePanelResponse.fromJson(response.data);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error in updatePanelDataInList: $e');
      }
      rethrow;
    }
  }

  @override
  Future<UpdatePanelResponse> updateAddress(
      String userId,
      int panelId,
      String address,
      ) async =>
      updatePanelData(userId, panelId, 'site_address', address);

  @override
  Future<UpdatePanelResponse> updateAdminCode(
      String userId,
      int panelId,
      int adminCode,
      ) async =>
      updatePanelData(userId, panelId, 'admin_code', adminCode.toString());

  @override
  Future<UpdatePanelResponse> updateAdminMobileNumber(
      String userId,
      int panelId,
      String adminMobileNumber,
      ) async =>
      updatePanelData(userId, panelId, 'admin_mobile_number', adminMobileNumber);

  @override
  Future<UpdatePanelResponse> updatePanelSimNumber(
      String userId,
      int panelId,
      String panelSimNumber,
      ) async =>
      updatePanelData(userId, panelId, 'panel_sim_number', panelSimNumber);

  @override
  Future<UpdatePanelResponse> updateSiteName(
      String userId,
      int panelId,
      String siteName,
      ) async =>
      updatePanelData(userId, panelId, 'site_name', siteName);

  @override
  Future<UpdatePanelResponse> updateSolitareMobileNumber(
      String userId,
      int panelId,
      String index,
      String number,
      ) async {
    final key = "mobile_number$index";
    return updatePanelData(userId, panelId, key, number);
  }
}