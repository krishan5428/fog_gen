class FireNumber {
  final int fireId;
  final String usrId;
  final String? fire1;
  final String? fire2;
  final String? fire3;
  final String? fire4;
  final String? fire5;
  final String? fire6;
  final String? fire7;
  final String? fire8;
  final String? fire9;
  final String? fire10;
  final String createdOn;

  FireNumber({
    required this.fireId,
    required this.usrId,
    required this.fire1,
    required this.fire2,
    required this.fire3,
    required this.fire4,
    required this.fire5,
    required this.fire6,
    required this.fire7,
    required this.fire8,
    required this.fire9,
    required this.fire10,
    required this.createdOn,
  });

  factory FireNumber.fromJson(Map<String, dynamic> json) {
    return FireNumber(
      fireId: json['fire_id'],
      usrId: json['usr_id'].toString(),
      fire1: json['fire1']?.toString(),
      fire2: json['fire2']?.toString(),
      fire3: json['fire3']?.toString(),
      fire4: json['fire4']?.toString(),
      fire5: json['fire5']?.toString(),
      fire6: json['fire6']?.toString(),
      fire7: json['fire7']?.toString(),
      fire8: json['fire8']?.toString(),
      fire9: json['fire9']?.toString(),
      fire10: json['fire10']?.toString(),
      createdOn: json['c_on']['date'] ?? '',
    );
  }

  @override
  String toString() {
    return 'FireNumber(fireId: $fireId, usrId: $usrId, fire1: $fire1, fire2: $fire2, createdOn: $createdOn)';
  }
}
