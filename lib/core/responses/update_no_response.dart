class UpdateNoResponse {
  final bool status;
  final String msg;

  UpdateNoResponse({required this.status, required this.msg});

  factory UpdateNoResponse.fromJson(Map<String, dynamic> json) {
    return UpdateNoResponse(
      status: json['status'] ?? '',
      msg: json['msg'] ?? '',
    );
  }
}
