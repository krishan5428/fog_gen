class UpdatePanelResponse {
  final bool status;
  final String msg;

  UpdatePanelResponse({required this.status, required this.msg});

  factory UpdatePanelResponse.fromJson(Map<String, dynamic> json) {
    return UpdatePanelResponse(
      status: json['status'] == true,
      msg: json['msg'],
    );
  }
}
