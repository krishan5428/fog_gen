import '../data/pojo/user_data.dart';

class LoginResponse {
  final bool status;
  final UserData? data;
  final String token;
  final String msg;

  LoginResponse({
    required this.status,
    this.data,
    required this.token,
    required this.msg,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      status: json['status'] ?? false,
      data: json['data'] != null ? UserData.fromJson(json['data']) : null,
      token: json['token'] ?? '',
      msg: json['msg'] ?? '',
    );
  }
}
