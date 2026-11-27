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
  final String role;

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
    this.role = 'customer',
  });

  /// 'tester' and 'factory_worker' are the same operational role — some
  /// accounts are seeded with one literal, some with the other — so any
  /// check gating factory-worker-only behavior must treat both as equal.
  static bool isFactoryWorkerRole(String role) =>
      role == 'factory_worker' || role == 'tester';

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      usrId: json['usr_id'] is int
          ? json['usr_id']
          : int.tryParse(json['usr_id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      enrolledOn: json['enrolled_on']?.toString() ?? '',
      devInfo: json['dev_info']?.toString() ?? '',
      deviceId: json['device_id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      cOn: json['c_on']?.toString() ?? '',
      role: json['role'] ?? 'customer',
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
      'role': role,
    };
  }
}
