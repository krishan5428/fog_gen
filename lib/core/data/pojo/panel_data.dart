class PanelData {
  final int pnlId;
  final String usrId;
  final String appType;
  final String pnlAccNo;
  final String panelName;
  final String panelType;
  final String siteName;
  final String siteAddress;
  final String pnlMac;
  final String pnlVer;
  final String pnlLineNo;
  final String pnlRcvrNo;
  final String ipAdd;
  final String portNo;
  final String staticIp;
  final String staticPort;
  final String pass;
  final String adminCode;
  final String cOn;
  final String usr1;
  final String usr2;
  final String usr3;
  final String usr4;
  final String panelSimNumber;
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
  final bool isIpPanel;
  final bool isIpGsmPanel;

  PanelData({
    required this.pnlId,
    required this.usrId,
    required this.appType,
    required this.pnlAccNo,
    required this.panelName,
    required this.panelType,
    required this.siteName,
    required this.siteAddress,
    required this.pnlMac,
    required this.pnlVer,
    required this.pnlLineNo,
    required this.pnlRcvrNo,
    required this.ipAdd,
    required this.portNo,
    required this.staticIp,
    required this.staticPort,
    required this.pass,
    required this.adminCode,
    required this.cOn,
    required this.usr1,
    required this.usr2,
    required this.usr3,
    required this.usr4,
    required this.panelSimNumber,
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
    required this.isIpPanel,
    required this.isIpGsmPanel,
  });

  factory PanelData.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic value) {
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) return value == '1' || value.toLowerCase() == 'true';
      return false;
    }

    return PanelData(
      pnlId: json['pnl_id'] is int
          ? json['pnl_id']
          : int.tryParse(json['pnl_id'].toString()) ?? 0,
      usrId: json['usr_id']?.toString() ?? '',
      appType: json['app_type']?.toString() ?? '',
      pnlAccNo: json['pnl_acc_no']?.toString() ?? '',
      panelName: json['panel_name']?.toString() ?? '',
      panelType: json['pnl_type']?.toString() ?? '',
      siteName: json['site_name']?.toString() ?? '',
      siteAddress: json['site_address']?.toString() ?? '',
      pnlMac: json['pnl_mac']?.toString() ?? '',
      pnlVer: json['pnl_ver']?.toString() ?? '',
      pnlLineNo: json['pnl_line_no']?.toString() ?? '',
      pnlRcvrNo: json['pnl_rcvr_no']?.toString() ?? '',
      ipAdd: json['ip_add']?.toString() ?? '',
      portNo: json['port_no']?.toString() ?? '',
      staticIp: json['static_ip']?.toString() ?? '',
      staticPort: json['static_port']?.toString() ?? '',
      pass: json['pass']?.toString() ?? '',
      adminCode: json['admin_code']?.toString() ?? '',
      cOn: json['c_on']?.toString() ?? '',
      usr1: json['usr_1']?.toString() ?? '',
      usr2: json['usr_2']?.toString() ?? '',
      usr3: json['usr_3']?.toString() ?? '',
      usr4: json['usr_4']?.toString() ?? '',
      panelSimNumber: json['panel_sim_number']?.toString() ?? '',
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
      isIpPanel: parseBool(json['is_ip_panel']),
      isIpGsmPanel: parseBool(json['is_ip_gsm_panel']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pnl_id': pnlId,
      'usr_id': usrId,
      'app_type': appType,
      'pnl_acc_no': pnlAccNo,
      'panel_name': panelName,
      'pnl_type': panelType,
      'site_name': siteName,
      'site_address': siteAddress,
      'pnl_mac': pnlMac,
      'pnl_ver': pnlVer,
      'pnl_line_no': pnlLineNo,
      'pnl_rcvr_no': pnlRcvrNo,
      'ip_add': ipAdd,
      'port_no': portNo,
      'static_ip': staticIp,
      'static_port': staticPort,
      'pass': pass,
      'admin_code': adminCode,
      'c_on': cOn,
      'usr_1': usr1,
      'usr_2': usr2,
      'usr_3': usr3,
      'usr_4': usr4,
      'panel_sim_number': panelSimNumber,
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
      'is_ip_panel': isIpPanel,
      'is_ip_gsm_panel': isIpGsmPanel,
    };
  }
}