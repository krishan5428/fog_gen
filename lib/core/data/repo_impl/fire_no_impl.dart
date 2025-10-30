import 'package:dio/dio.dart';

import '../../api/api_client.dart';
import '../../api/web_url_constants.dart';
import '../../repo/fire_repo.dart';
import '../../responses/add_fire_no.dart';
import '../../responses/delete_fire_response.dart';
import '../../responses/fire_list_response.dart';
import '../../responses/update_fire_no_response.dart';

class FireNoRepoImpl implements FireRepo {
  final Dio _dio = ApiClient.dio;

  @override
  Future<AddFireNo> addFireNo1(String userId, String fireNo1) async {
    print('📡 API CALL: addFireNo1 started');

    try {
      final response = await _dio.post(
        WebUrlConstants.addFireNo,
        data: FormData.fromMap({
          'usr_id': userId,
          'fire1': fireNo1,
          'fire2': '0000000000',
          'fire3': '0000000000',
          'fire4': '0000000000',
          'fire5': '0000000000',
          'fire6': '0000000000',
          'fire7': '0000000000',
          'fire8': '0000000000',
          'fire9': '0000000000',
          'fire10': '0000000000',
        }),
      );

      print('📡 API RESPONSE STATUS: ${response.statusCode}');
      print('📡 API RESPONSE DATA: ${response.data}');

      if (response.statusCode == 200) {
        return AddFireNo.fromJson(response.data);
      } else {
        print('⚠️ Unexpected response format: ${response.data.runtimeType}');
        return AddFireNo(msg: 'Invalid server response');
      }
    } catch (e) {
      print('❌ Exception in addFireNo1: $e');
      return AddFireNo(msg: 'Exception: $e');
    }
  }

  @override
  Future<FireResponse> getFireNumbers(String userId) async {
    final response = await _dio.post(
      WebUrlConstants.getFireNo,
      data: FormData.fromMap({'usr_id': userId}),
    );

    print('Raw Response Data: ${response.data}');

    final parsedResponse = FireResponse.fromJson(response.data);

    print('Parsed FireResponse: $parsedResponse');

    return parsedResponse;
  }

  @override
  Future<UpdateFireNoResponse> updateFireNo(
    String userId,
    String fireId,
    String number,
    int count,
  ) async {
    final fieldKey = 'fire$count';

    final formData = FormData.fromMap({
      'usr_id': userId,
      'fire_id': fireId,
      fieldKey: number,
    });

    final response = await _dio.post(
      WebUrlConstants.updateFireNo,
      data: formData,
    );

    print('Status code: ${response.statusCode}');
    print('Response: ${response.data}');
    if (response.statusCode == 200) {
      return UpdateFireNoResponse.fromJson(response.data);
    } else {
      throw Exception('Failed to update fire number');
    }
  }

  @override
  Future<DeleteFireResponse> deleteFireWRTFireId(
    String userId,
    String fireId,
  ) async {
    final formData = FormData.fromMap({'usr_id': userId, 'fire_id': fireId});

    try {
      final response = await _dio.post(
        WebUrlConstants.deleteFireNo,
        data: formData,
      );

      return DeleteFireResponse.fromJson(response.data);
    } catch (e) {
      print(' Error deleteFireWRTFireId : $e');
      rethrow;
    }
  }
}
