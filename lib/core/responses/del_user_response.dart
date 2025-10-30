class DeleteUserResponse {
  final bool status;
  final String msg;

  DeleteUserResponse({required this.status, required this.msg});

  factory DeleteUserResponse.fromJson(Map<String, dynamic> json) {
    return DeleteUserResponse(
      status: json['status'] ?? false,
      msg: json['msg'] ?? '',
    );
  }
}
