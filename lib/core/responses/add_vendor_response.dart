class AddVendorResponse {
  final bool status;
  final String msg;
  final int vendorId;

  AddVendorResponse({
    required this.status,
    required this.msg,
    required this.vendorId,
  });

  factory AddVendorResponse.fromJson(Map<String, dynamic> json) {
    return AddVendorResponse(
      status: json['status'],
      msg: json['msg'],
      vendorId: json['vendor_id'],
    );
  }
}
