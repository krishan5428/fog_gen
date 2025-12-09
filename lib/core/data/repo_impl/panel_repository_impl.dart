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
  }) async {
    try {
      final formData = FormData.fromMap({
        'userid': userId,
        'panel_type': panelType,
        'panel_name': panelName,
        'site': site,
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
        'address': address,
        'c_on': cOn,
        'ip_address': ip_address,
        'port_no': port_no,
        'static_ip_address': static_ip_address,
        'static_port_no': static_port_no,
        'password': password,
        'is_ip_panel': is_ip_panel,
        'is_ip_gsm_panel': is_ip_gsm_panel,
      });

      final response = await _dio.post(
        WebUrlConstants.addPanel,
        data: formData,
      );

      print("✅ Request URL: ${response.requestOptions.uri}");
      print("✅ Request Headers: ${response.requestOptions.headers}");
      print("✅ Request Data: ${response.requestOptions.data}");
      print("✅ Response Status: ${response.statusCode}");
      print("✅ Response Data: ${response.data}");

      return AddPanelResponse.fromJson(response.data);
    } on DioException catch (e) {
      print('❌ Error adding panels: ${e.message}');
      if (e.response != null) {
        print('❌ Status Code: ${e.response?.statusCode}');
        print('❌ Response Data: ${e.response?.data}');
        print('❌ Request URL: ${e.requestOptions.uri}');
        print('❌ Request Data: ${e.requestOptions.data}');
      }
      rethrow;
    } catch (e) {
      print('⚠️ Unexpected error: $e');
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
    final formData = FormData.fromMap({'pnl_id': panelId, 'userid': userId});

    try {
      final response = await _dio.post(
        WebUrlConstants.deletePanel,
        data: formData,
        options: Options(contentType: Headers.jsonContentType),
      );

      if (response.statusCode == 200) {
        return DeletePanelResponse.fromJson(response.data);
      } else {
        print('Server returned ${response.statusCode}: ${response.data}');
        throw Exception('Failed to delete panel');
      }
    } catch (e) {
      print('Delete Panel error: $e');
      rethrow;
    }
  }

  @override
  Future<UpdatePanelResponse> updateAddress(String userId,
      int panelId,
      String address,) async {
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
  Future<UpdatePanelResponse> updateAdminCode(String userId,
      int panelId,
      int adminCode,) async {
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
  Future<UpdatePanelResponse> updateAdminMobileNumber(String userId,
      int panelId,
      String adminMobileNumber,) async {
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
  Future<UpdatePanelResponse> updatePanelSimNumber(String userId,
      int panelId,
      String panelSimNumber,) async {
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
  Future<UpdatePanelResponse> updateSiteName(String userId,
      int panelId,
      String siteName,) async {
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
  Future<UpdatePanelResponse> updateSolitareMobileNumber(String userId,
      int panelId,
      String index,
      String number,) async {
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

  @override
  Future<UpdatePanelResponse> updatePanelData(String userId,
      int panelId,
      String key,
      String value,) async {
    final formData = FormData.fromMap({
      'pnl_id': panelId,
      'userid': userId,
      key: value,
    });

    if (kDebugMode) {
      debugPrint('📡 updatePanelData called with:');
      debugPrint('User ID: $userId');
      debugPrint('Panel ID: $panelId');
      debugPrint('Key: $key');
      debugPrint('Value: $value');
      debugPrint('FormData: ${formData.fields}');
    }

    try {
      final response = await _dio.post(
        WebUrlConstants.updatePanel,
        data: formData,
      );

      if (kDebugMode) {
        debugPrint('✅ updatePanelData response: ${response.data}');
      }

      return UpdatePanelResponse.fromJson(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('Error updatePanelData : $e');
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
      'userid': userId,
    };

    for (int i = 0; i < keys.length; i++) {
      formMap[keys[i]] = values[i];
    }

    final formData = FormData.fromMap(formMap);

    if (kDebugMode) {
      debugPrint('📡 updatePanelDataInList called with:');
      debugPrint('User ID: $userId');
      debugPrint('Panel ID: $panelId');
      debugPrint('Keys: $keys');
      debugPrint('Values: $values');
      debugPrint('FormData: ${formData.fields}');
    }

    try {
      final response = await _dio.post(
        WebUrlConstants.updatePanel,
        data: formData,
      );

      if (kDebugMode) {
        debugPrint('✅ updatePanelDataInList response: ${response.data}');
      }

      return UpdatePanelResponse.fromJson(response.data);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updatePanelDataInList : $e');
      }
      rethrow;
    }
  }
}
