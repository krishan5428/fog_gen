import '../responses/del_user_response.dart';
import '../responses/forgot_pass_response.dart';
import '../responses/login_response.dart';
import '../responses/signup_response.dart';
import '../responses/update_user_response.dart';

abstract class UserRepo {
  Future<LoginResponse> login(String mobile, String password, String fcmToken);

  Future<SignupResponse> signUp(
    String name,
    String email,
    String mobile,
    String pass,
    String dev_info,
    String device_id,
  );

  Future<ForgotPassResponse> forgotPass(String mobile);

  Future<UpdateUserResponse> updateValue(
    String userId,
    String value,
    String key,
  );

  Future<DeleteUserResponse> deleteUser(String mobile, String password);
}
