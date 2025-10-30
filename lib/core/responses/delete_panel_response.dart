class DeletePanelResponse {
  final bool status;
  final String msg;

  DeletePanelResponse({required this.status, required this.msg});

  factory DeletePanelResponse.fromJson(Map<String, dynamic> json) {
    return DeletePanelResponse(
      status: json['status'] == true,
      msg: json['msg'],
    );
  }
}
