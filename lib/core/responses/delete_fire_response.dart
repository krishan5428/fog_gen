class DeleteFireResponse {
  final bool status;
  final String msg;

  DeleteFireResponse({required this.status, required this.msg});

  factory DeleteFireResponse.fromJson(Map<String, dynamic> json) {
    return DeleteFireResponse(status: json['status'] == true, msg: json['msg']);
  }
}
