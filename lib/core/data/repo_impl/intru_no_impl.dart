import 'package:dio/dio.dart';

import '../../api/api_client.dart';
import '../../api/web_url_constants.dart';
import '../../repo/intru_repo.dart';
import '../../responses/add_intru_no.dart';
import '../../responses/delete_intru_response.dart';
import '../../responses/intru_list_response.dart';
import '../../responses/update_no_response.dart';

class IntruNoRepoImpl implements IntruRepo {
  final Dio _dio = ApiClient.dio;
  @override
  Future<AddIntruNo> addIntruNo1(String userId, String intruNo1) async {
    final response = await _dio.post(
      WebUrlConstants.addIntruNo,
      data: FormData.fromMap({
        'usr_id': userId,
        'intru1': intruNo1,
        'intru2': '0000000000',
        'intru3': '0000000000',
        'intru4': '0000000000',
        'intru5': '0000000000',
        'intru6': '0000000000',
        'intru7': '0000000000',
        'intru8': '0000000000',
        'intru9': '0000000000',
        'intru10': '0000000000',
      }),
    );
    return AddIntruNo.fromJson(response.data);
  }

  @override
  Future<IntrusionResponse> getIntrusionNumbers(String userId) async {
    final response = await _dio.post(
      WebUrlConstants.getIntruNo,
      data: FormData.fromMap({'usr_id': userId}),
    );

    print('Raw Response Data: ${response.data}');

    final parsedResponse = IntrusionResponse.fromJson(response.data);

    print('Parsed IntrusionResponse: $parsedResponse');

    return parsedResponse;
  }

  @override
  Future<UpdateNoResponse> updateIntruNo(
    String userId,
    String intruId,
    String number,
    int count,
  ) async {
    final fieldKey = 'intru$count';

    final formData = FormData.fromMap({
      'usr_id': userId,
      'intru_id': intruId,
      fieldKey: number,
    });

    final response = await _dio.post(
      WebUrlConstants.updateIntruNo,
      data: formData,
    );

    print('Raw Response Data: ${response.data}');

    final parsedResponse = UpdateNoResponse.fromJson(response.data);

    print('Parsed IntrusionResponse: $parsedResponse');

    return parsedResponse;
  }

  @override
  Future<DeleteIntruResponse> deleteIntruWRTIntruId(
    String userId,
    String intruId,
  ) async {
    final formData = FormData.fromMap({'usr_id': userId, 'intru_id': intruId});

    try {
      final response = await _dio.post(
        WebUrlConstants.deleteIntruNo,
        data: formData,
      );

      return DeleteIntruResponse.fromJson(response.data);
    } catch (e) {
      print(' Error deleteIntruWRTIntruId : $e');
      rethrow;
    }
  }
}
