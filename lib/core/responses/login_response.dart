import '../data/pojo/user_data.dart';

class LoginResponse {
  final bool status;
  final UserData? data;
  final String token;
  final String msg;

  /// Whether the user already has vendor details (login.php, as FireNex).
  final bool vendorAdded;

  LoginResponse({
    required this.status,
    this.data,
    required this.token,
    required this.msg,
    this.vendorAdded = false,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      status: json['status'] ?? false,
      data: json['data'] != null ? UserData.fromJson(json['data']) : null,
      token: json['token'] ?? '',
      msg: json['msg'] ?? '',
      vendorAdded: json['vendor_added'] == true,
    );
  }
}
