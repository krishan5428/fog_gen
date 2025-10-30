class ForgotPassResponse {
  final bool status;
  final String msg;

  ForgotPassResponse({required this.status, required this.msg});

  factory ForgotPassResponse.fromJson(Map<String, dynamic> json) {
    return ForgotPassResponse(status: json['status'], msg: json['msg']);
  }
}
