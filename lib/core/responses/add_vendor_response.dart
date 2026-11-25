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
      status: json['status'] == true,
      msg: json['msg']?.toString() ?? '',
      vendorId: json['vendor_id'] is int
          ? json['vendor_id']
          : int.tryParse(json['vendor_id']?.toString() ?? '') ?? 0,
    );
  }
}
