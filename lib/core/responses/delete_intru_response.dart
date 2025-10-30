class DeleteIntruResponse {
  final bool status;
  final String msg;

  DeleteIntruResponse({required this.status, required this.msg});

  factory DeleteIntruResponse.fromJson(Map<String, dynamic> json) {
    return DeleteIntruResponse(
      status: json['status'] == true,
      msg: json['msg'],
    );
  }
}
