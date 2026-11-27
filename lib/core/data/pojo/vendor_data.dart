class VendorData {
  // final String vendor_id;
  final String user_id;
  final String vendor_name;
  final String vendor_email;
  final String vendor_mobile;
  final String vendor_address;

  VendorData({
    // required this.vendor_id,
    required this.user_id,
    required this.vendor_name,
    required this.vendor_email,
    required this.vendor_mobile,
    required this.vendor_address,
  });

  factory VendorData.fromJson(Map<String, dynamic> json) {
    return VendorData(
      // vendor_id: json['vendor_id'],
      user_id: (json['user_id'] ?? json['usr_id'])?.toString() ?? '',
      vendor_name: json['vendor_name'] ?? '',
      vendor_email: json['vendor_email'] ?? '',
      // Server: vendor_mob_no. Copy saved on the phone (toJson): vendor_mobile.
      vendor_mobile:
          (json['vendor_mobile'] ?? json['vendor_mob_no'])?.toString() ?? '',
      vendor_address: json['vendor_address'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // 'vendor_id': vendor_id,
      'user_id': user_id,
      'vendor_name': vendor_name,
      'vendor_email': vendor_email,
      'vendor_mobile': vendor_mobile,
      'vendor_address': vendor_address,
    };
  }
}
