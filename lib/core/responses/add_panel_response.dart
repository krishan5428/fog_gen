class AddPanelResponse {
  final bool status;
  final String msg;

  AddPanelResponse({required this.status, required this.msg});

  factory AddPanelResponse.fromJson(Map<String, dynamic> json) {
    return AddPanelResponse(
      status: json['status'] ?? '',
      msg: json['message'] ?? '',
    );
  }
}
