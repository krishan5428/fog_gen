import 'package:fire_nex/core/api/api_service.dart';
import 'package:fire_nex/core/responses/user_response.dart';

class UserRepo {
  final ApiService _apiService = ApiService();

  Future<LoginResponse> loginUser(String mobile, String pass) async {
    return await _apiService.loginUser(mobile: mobile, pass: pass);
  }
}
