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
  Future<AddPanelResponse> addPanel(
    String userId,
    String panelType,
    String panelName,
    String site,
    String panelSimNumber,
    String adminCode,
    String adminMobileNumber,
    String mobileNumberSubId,
    String mobileNumber2,
    String mobileNumber3,
    String mobileNumber4,
    String mobileNumber5,
    String mobileNumber6,
    String mobileNumber7,
    String mobileNumber8,
    String mobileNumber9,
    String mobileNumber10,
    String address,
    String cOn,
    String ip_address,
    String port_no,
    String static_ip_address,
    String static_port_no,
    String password,
    bool is_ip_panel,
    bool is_ip_gsm_panel,
  ) async {
    try {
      final response = await _dio.post(
        WebUrlConstants.addPanel,
        data: FormData.fromMap({
          'userid': userId,
          'panel_type': panelType,
          'panel_name': panelName,
          'site': site,
          'panel_sim_number': panelSimNumber,
          'admin_code': adminCode,
          'admin_mobile_number': adminMobileNumber,
          'mobile_number_sub_id': '1',
          'mobile_number2': mobileNumber2,
          'mobile_number3': mobileNumber3,
          'mobile_number4': mobileNumber4,
          'mobile_number5': mobileNumber5,
          'mobile_number6': mobileNumber5,
          'mobile_number7': mobileNumber5,
          'mobile_number8': mobileNumber5,
          'mobile_number9': mobileNumber5,
          'mobile_number10': mobileNumber5,
          'address': address,
          'c_on': cOn,
          'ip_address': ip_address,
          'port_no': port_no,
          'static_ip_address': static_ip_address,
          'static_port_no': static_port_no,
          'password': password,
          'is_ip_panel': is_ip_panel,
          'is_ip_gsm_panel': is_ip_gsm_panel,
        }),
      );
      return AddPanelResponse.fromJson(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('Error adding panels: $e');
      }
      rethrow;
    }
  }

  @override
  Future<PanelResponse> getPanels(String userId) async {
    final formData = FormData.fromMap({'userid': userId});

    try {
      final response = await _dio.post(
        WebUrlConstants.getAllPanels,
        data: formData,
      );

      return PanelResponse.fromJson(response.data);
    } catch (e) {
      if (kDebugMode) {
        print(' Error fetching panels: $e');
      }
      rethrow;
    }
  }

  @override
  Future<DeletePanelResponse> deletePanel(String userId, int panelId) async {
    final formData = FormData.fromMap({'pnl_id': panelId, 'usr_id': userId});

    try {
      final response = await _dio.post(
        WebUrlConstants.deletePanel,
        data: formData,
      );

      return DeletePanelResponse.fromJson(response.data);
    } catch (e) {
      if (kDebugMode) {
        print(' Error deleting panels: $e');
      }
      rethrow;
    }
  }

  @override
  Future<UpdatePanelResponse> updateAddress(
    String userId,
    int panelId,
    String address,
  ) async {
    final formData = FormData.fromMap({
      'pnl_id': panelId,
      'userid': userId,
      'address': address,
    });

    try {
      final response = await _dio.post(
        WebUrlConstants.updatePanel,
        data: formData,
      );

      return UpdatePanelResponse.fromJson(response.data);
    } catch (e) {
      if (kDebugMode) {
        print(' Error updateAddress : $e');
      }
      rethrow;
    }
  }

  @override
  Future<UpdatePanelResponse> updateAdminCode(
    String userId,
    int panelId,
    int adminCode,
  ) async {
    final formData = FormData.fromMap({
      'pnl_id': panelId,
      'userid': userId,
      'admin_code': adminCode,
    });

    try {
      final response = await _dio.post(
        WebUrlConstants.updatePanel,
        data: formData,
      );

      return UpdatePanelResponse.fromJson(response.data);
    } catch (e) {
      if (kDebugMode) {
        print(' Error updateAdminCode : $e');
      }
      rethrow;
    }
  }

  @override
  Future<UpdatePanelResponse> updateAdminMobileNumber(
    String userId,
    int panelId,
    String adminMobileNumber,
  ) async {
    final formData = FormData.fromMap({
      'pnl_id': panelId,
      'userid': userId,
      'admin_mobile_number': adminMobileNumber,
    });

    try {
      final response = await _dio.post(
        WebUrlConstants.updatePanel,
        data: formData,
      );

      return UpdatePanelResponse.fromJson(response.data);
    } catch (e) {
      if (kDebugMode) {
        print(' Error updateAdminMobileNumber : $e');
      }
      rethrow;
    }
  }

  @override
  Future<UpdatePanelResponse> updatePanelSimNumber(
    String userId,
    int panelId,
    String panelSimNumber,
  ) async {
    final formData = FormData.fromMap({
      'pnl_id': panelId,
      'userid': userId,
      'panel_sim_number': panelSimNumber,
    });

    try {
      final response = await _dio.post(
        WebUrlConstants.updatePanel,
        data: formData,
      );

      return UpdatePanelResponse.fromJson(response.data);
    } catch (e) {
      if (kDebugMode) {
        print(' Error updatePanelSimNumber : $e');
      }
      rethrow;
    }
  }

  @override
  Future<UpdatePanelResponse> updateSiteName(
    String userId,
    int panelId,
    String siteName,
  ) async {
    final formData = FormData.fromMap({
      'pnl_id': panelId,
      'userid': userId,
      'site': siteName,
    });

    try {
      final response = await _dio.post(
        WebUrlConstants.updatePanel,
        data: formData,
      );

      return UpdatePanelResponse.fromJson(response.data);
    } catch (e) {
      if (kDebugMode) {
        print(' Error updateSiteName : $e');
      }
      rethrow;
    }
  }

  @override
  Future<UpdatePanelResponse> updateSolitareMobileNumber(
    String userId,
    int panelId,
    String index,
    String number,
  ) async {
    final indexNumber = "mobile_number$index";

    final formData = FormData.fromMap({
      'pnl_id': panelId,
      'userid': userId,
      indexNumber: number,
    });

    try {
      final response = await _dio.post(
        WebUrlConstants.updatePanel,
        data: formData,
      );

      return UpdatePanelResponse.fromJson(response.data);
    } catch (e) {
      if (kDebugMode) {
        print(' Error updateSiteName : $e');
      }
      rethrow;
    }
  }
}
