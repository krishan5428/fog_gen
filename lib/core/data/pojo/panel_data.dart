class PanelData {
  final int pnlId;
  final String userId;
  final String panelType;
  final String panelName;
  final String site;
  final String panelSimNumber;
  final String adminCode;
  final String adminMobileNumber;
  final String mobileNumberSubId;
  final String mobileNumber2;
  final String mobileNumber3;
  final String mobileNumber4;
  final String mobileNumber5;
  final String mobileNumber6;
  final String mobileNumber7;
  final String mobileNumber8;
  final String mobileNumber9;
  final String mobileNumber10;
  final String address;
  final String message;
  final String status;
  final String createdAt;
  final String armDisarmSound;
  final String otherSound;
  final String lastTimestamp;

  PanelData({
    required this.pnlId,
    required this.userId,
    required this.panelType,
    required this.panelName,
    required this.site,
    required this.panelSimNumber,
    required this.adminCode,
    required this.adminMobileNumber,
    required this.mobileNumberSubId,
    required this.mobileNumber2,
    required this.mobileNumber3,
    required this.mobileNumber4,
    required this.mobileNumber5,
    required this.mobileNumber6,
    required this.mobileNumber7,
    required this.mobileNumber8,
    required this.mobileNumber9,
    required this.mobileNumber10,
    required this.address,
    required this.message,
    required this.status,
    required this.createdAt,
    required this.armDisarmSound,
    required this.otherSound,
    required this.lastTimestamp,
  });

  factory PanelData.fromJson(Map<String, dynamic> json) {
    return PanelData(
      pnlId: json['pnl_id'] ?? 0,
      userId: json['userid'].toString(),
      panelType: json['panel_type'] ?? '',
      panelName: json['panel_name'] ?? '',
      site: json['site'] ?? '',
      panelSimNumber: json['panel_sim_number'].toString(),
      adminCode: json['admin_code'].toString(),
      adminMobileNumber: json['admin_mobile_number'].toString(),
      mobileNumberSubId: json['mobile_number_sub_id'].toString(),
      mobileNumber2: json['mobile_number2'].toString(),
      mobileNumber3: json['mobile_number3'].toString(),
      mobileNumber4: json['mobile_number4'].toString(),
      mobileNumber5: json['mobile_number5'].toString(),
      mobileNumber6: json['mobile_number6'].toString(),
      mobileNumber7: json['mobile_number7'].toString(),
      mobileNumber8: json['mobile_number8'].toString(),
      mobileNumber9: json['mobile_number9'].toString(),
      mobileNumber10: json['mobile_number10'].toString(),
      address: json['address'] ?? '',
      message: json['message'] ?? '',
      status: json['status'] ?? '',
      createdAt: json['created_at']['date'] ?? '',
      armDisarmSound: json['arm_disarm_sound'].toString(),
      otherSound: json['other_sound'].toString(),
      lastTimestamp: json['last_timestamp'] ?? '',
    );
  }
}
