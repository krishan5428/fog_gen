import '../data/pojo/vendor_data.dart';

class GetVendorResponse {
  final bool status;
  final List<VendorData> vendorData;

  GetVendorResponse({required this.status, required this.vendorData});

  factory GetVendorResponse.fromJson(Map<String, dynamic> json) {
    return GetVendorResponse(
      status: json['status'],
      vendorData:
          json['vendors'] != null
              ? List<VendorData>.from(
                json['vendors'].map((e) => VendorData.fromJson(e)),
              )
              : [],
    );
  }
}
