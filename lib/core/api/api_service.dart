import 'package:dio/dio.dart';
import 'package:fire_nex/core/api/api_client.dart';
import 'package:fire_nex/core/responses/user_response.dart';

class ApiService {
  final _dio = ApiClient.dio;

  Future<LoginResponse> loginUser({
    required String mobile,
    required String pass,
    String lng = '',
    String lat = '',
    String tkn = '',
    String lAdd = '',
    String os = '',
    String devId = '',
  }) async {
    try {
      final formData = FormData.fromMap({
        'lng': lng,
        'lat': lat,
        'tkn': tkn,
        'mobile': mobile,
        'pass': pass,
        'l_add': lAdd,
        'os': os,
        'dev_id': devId,
      });

      final response = await _dio.post('login.php', data: formData);

      return LoginResponse.fromJson(response.data);
    } catch (e) {
      // Optionally: throw custom error or log
      rethrow;
    }
  }
}
