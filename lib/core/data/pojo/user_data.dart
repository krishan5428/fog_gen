class UserData {
  final int usrId;
  final String name;
  final String email;
  final String mobile;
  final String enrolledOn;
  final String devInfo;
  final String deviceId;
  final String status;
  final String cOn;

  UserData({
    required this.usrId,
    required this.name,
    required this.email,
    required this.mobile,
    required this.enrolledOn,
    required this.devInfo,
    required this.deviceId,
    required this.status,
    required this.cOn,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      usrId: json['usr_id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      mobile: json['mobile'] ?? '',
      enrolledOn: json['enrolled_on'] ?? '',
      devInfo: json['dev_info'] ?? '',
      deviceId: json['device_id'] ?? '',
      status: json['status'] ?? '',
      cOn: json['c_on'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'usr_id': usrId,
      'name': name,
      'email': email,
      'mobile': mobile,
      'enrolled_on': enrolledOn,
      'dev_info': devInfo,
      'device_id': deviceId,
      'status': status,
      'c_on': cOn,
    };
  }
}
