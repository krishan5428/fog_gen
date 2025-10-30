class AddPanelResponse {
  final String status;
  final String msg;

  AddPanelResponse({required this.status, required this.msg});

  factory AddPanelResponse.fromJson(Map<String, dynamic> json) {
    return AddPanelResponse(
      status: json['status'] ?? '',
      msg: json['message'] ?? '',
    );
  }

  bool get isSuccess => status.toLowerCase() == 'success';
}
