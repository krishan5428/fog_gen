import 'package:dio/dio.dart';

import '../../api/api_client.dart';
import '../../api/web_url_constants.dart';
import '../../repo/user_repo.dart';
import '../../responses/del_user_response.dart';
import '../../responses/forgot_pass_response.dart';
import '../../responses/login_response.dart';
import '../../responses/signup_response.dart';
import '../../responses/update_user_response.dart';

class UserRepoImpl implements UserRepo {
  final Dio _dio = ApiClient.dio;

  @override
  Future<LoginResponse> login(
    String mobile,
    String pass,
    String fcmToken,
  ) async {
    print("Hitting URL: ${WebUrlConstants.loginUser}");
    try {
      final response = await _dio.post(
        WebUrlConstants.loginUser,
        data: FormData.fromMap({
          'mobile': mobile,
          'pass': pass,
          'lng': '',
          'lat': '',
          'tkn': '',
          'l_add': '',
          'os': '',
          'dev_id': '',
        }),
      );

      print("RAW Login Response: ${response.data}");

      if (response.data is! Map<String, dynamic>) {
        return LoginResponse(
          status: false,
          token: "",
          msg: "Invalid server response format",
        );
      }

      return LoginResponse.fromJson(response.data);
    } on DioException catch (e) {
      print("Dio Error: ${e.message}");
      print("Body: ${e.response?.data}");

      return LoginResponse(
        status: false,
        token: "",
        msg: e.response?.data?['msg'] ?? "Network error",
      );
    }
  }

  @override
  Future<SignupResponse> signUp(
    String name,
    String email,
    String mobile,
    String password,
    String dev_info,
    String device_id,
  ) async {
    final response = await _dio.post(
      WebUrlConstants.signUpUser,
      data: FormData.fromMap({
        'name': name,
        'email': email,
        'mobile': mobile,
        'password': password,
        'dev_info': dev_info,
        'device_id': device_id,
      }),
    );
    return SignupResponse.fromJson(response.data);
  }

  @override
  Future<ForgotPassResponse> forgotPass(String mobile) async {
    final response = await _dio.post(
      WebUrlConstants.forgetPass,
      data: FormData.fromMap({'mobile': mobile}),
    );
    return ForgotPassResponse.fromJson(response.data);
  }

  @override
  Future<UpdateUserResponse> updateValue(
    String userId,
    String value,
    String key,
  ) async {
    final data = FormData.fromMap({'usr_id': userId, key: value});

    final response = await _dio.post(WebUrlConstants.updateUser, data: data);

    if (response.statusCode == 200) {
      return UpdateUserResponse.fromJson(response.data);
    } else {
      return UpdateUserResponse(msg: 'Invalid server response');
    }
  }

  @override
  Future<DeleteUserResponse> deleteUser(String mobile, String password) async {
    final data = FormData.fromMap({'mobile': mobile, 'pass': password});

    final response = await _dio.post(WebUrlConstants.delUser, data: data);

    if (response.statusCode == 200) {
      return DeleteUserResponse.fromJson(response.data);
    } else {
      return DeleteUserResponse(msg: 'Invalid server response', status: false);
    }
  }
}
