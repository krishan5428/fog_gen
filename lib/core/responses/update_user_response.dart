class UpdateUserResponse {
  final String msg;

  UpdateUserResponse({required this.msg});

  factory UpdateUserResponse.fromJson(Map<String, dynamic> json) {
    return UpdateUserResponse(msg: json['message'] ?? 'Unknown error');
  }
}
