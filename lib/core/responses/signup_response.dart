class SignupResponse {
  final bool status;
  final String msg;

  SignupResponse({required this.status, required this.msg});

  factory SignupResponse.fromJson(Map<String, dynamic> json) {
    return SignupResponse(
      status: json['status'] ?? false,
      msg: json['msg'] ?? '',
    );
  }
}
