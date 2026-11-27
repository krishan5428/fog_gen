import '../data/pojo/vendor_data.dart';

class GetVendorResponse {
  final bool status;
  final List<VendorData> vendorData;

  GetVendorResponse({required this.status, required this.vendorData});

  factory GetVendorResponse.fromJson(Map<String, dynamic> json) {
    return GetVendorResponse(
      status: json['status'] == true,
      // The vendor lives in the user's row: one "vendor" object, or none.
      vendorData: json['vendor'] is Map<String, dynamic>
          ? [VendorData.fromJson(json['vendor'])]
          : [],
    );
  }
}
