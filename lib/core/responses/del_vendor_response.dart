class DeleteVendorResponse {
  final bool status;
  final String msg;

  DeleteVendorResponse({
    required this.status,
    required this.msg,
  });

  factory DeleteVendorResponse.fromJson(Map<String, dynamic> json) {
    return DeleteVendorResponse(
      status: json['status'] ?? false,
      msg: json['msg'] ?? '',
    );
  }
}
