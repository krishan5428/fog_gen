class PanelData {
  final int pnlId;
  final String userId;
  final String panelType;
  final String panelName;
  final String site;
  final String address;
  final String panelSimNumber;
  final String adminCode;
  final String adminMobileNumber;
  final String mobileNumberSubId;
  final String mobileNumber1;
  final String mobileNumber2;
  final String mobileNumber3;
  final String mobileNumber4;
  final String mobileNumber5;
  final String mobileNumber6;
  final String mobileNumber7;
  final String mobileNumber8;
  final String mobileNumber9;
  final String mobileNumber10;
  final String status;
  final String createdAt;
  final String ip_address;
  final String port_no;
  final String static_ip_address;
  final String static_port_no;
  final String password;
  final bool is_ip_panel;
  final bool is_ip_gsm_panel;

  PanelData({
    required this.pnlId,
    required this.userId,
    required this.panelType,
    required this.panelName,
    required this.site,
    required this.address,
    required this.panelSimNumber,
    required this.adminCode,
    required this.adminMobileNumber,
    required this.mobileNumberSubId,
    required this.mobileNumber1,
    required this.mobileNumber2,
    required this.mobileNumber3,
    required this.mobileNumber4,
    required this.mobileNumber5,
    required this.mobileNumber6,
    required this.mobileNumber7,
    required this.mobileNumber8,
    required this.mobileNumber9,
    required this.mobileNumber10,
    required this.status,
    required this.createdAt,
    required this.ip_address,
    required this.port_no,
    required this.static_ip_address,
    required this.static_port_no,
    required this.password,
    required this.is_ip_panel,
    required this.is_ip_gsm_panel,
  });

  factory PanelData.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic value) {
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) return value == '1' || value.toLowerCase() == 'true';
      return false;
    }

    return PanelData(
      pnlId: json['pnl_id'] ?? 0,
      userId: json['userid']?.toString() ?? '',
      panelType: json['panel_type']?.toString() ?? '',
      panelName: json['panel_name']?.toString() ?? '',
      site: json['site']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      panelSimNumber: json['panel_sim_number']?.toString() ?? '',
      adminCode: json['admin_code']?.toString() ?? '',
      adminMobileNumber: json['admin_mobile_number']?.toString() ?? '',
      mobileNumberSubId: json['mobile_number_sub_id']?.toString() ?? '',
      mobileNumber1: json['mobile_number1']?.toString() ?? '',
      mobileNumber2: json['mobile_number2']?.toString() ?? '',
      mobileNumber3: json['mobile_number3']?.toString() ?? '',
      mobileNumber4: json['mobile_number4']?.toString() ?? '',
      mobileNumber5: json['mobile_number5']?.toString() ?? '',
      mobileNumber6: json['mobile_number6']?.toString() ?? '',
      mobileNumber7: json['mobile_number7']?.toString() ?? '',
      mobileNumber8: json['mobile_number8']?.toString() ?? '',
      mobileNumber9: json['mobile_number9']?.toString() ?? '',
      mobileNumber10: json['mobile_number10']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdAt: json['created_at'] is Map
          ? (json['created_at']['date'] ?? '')
          : json['created_at']?.toString() ?? '',
      ip_address: json['ip_address']?.toString() ?? '',
      port_no: json['port_no']?.toString() ?? '',
      static_ip_address: json['static_ip_address']?.toString() ?? '',
      static_port_no: json['static_port_no']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      is_ip_panel: parseBool(json['is_ip_panel']),
      is_ip_gsm_panel: parseBool(json['is_ip_gsm_panel']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pnl_id': pnlId,
      'userid': userId,
      'panel_type': panelType,
      'panel_name': panelName,
      'site': site,
      'address': address,
      'panel_sim_number': panelSimNumber,
      'admin_code': adminCode,
      'admin_mobile_number': adminMobileNumber,
      'mobile_number_sub_id': mobileNumberSubId,
      'mobile_number1': mobileNumber1,
      'mobile_number2': mobileNumber2,
      'mobile_number3': mobileNumber3,
      'mobile_number4': mobileNumber4,
      'mobile_number5': mobileNumber5,
      'mobile_number6': mobileNumber6,
      'mobile_number7': mobileNumber7,
      'mobile_number8': mobileNumber8,
      'mobile_number9': mobileNumber9,
      'mobile_number10': mobileNumber10,
      'status': status,
      'created_at': createdAt,
      'ip_address': ip_address,
      'port_no': port_no,
      'static_ip_address': static_ip_address,
      'static_port_no': static_port_no,
      'password': password,
      'is_ip_panel': is_ip_panel,
      'is_ip_gsm_panel': is_ip_gsm_panel,
    };
  }
}
