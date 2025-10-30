class IntrusionNumber {
  final int intruId;
  final String usrId;
  final String? intru1;
  final String? intru2;
  final String? intru3;
  final String? intru4;
  final String? intru5;
  final String? intru6;
  final String? intru7;
  final String? intru8;
  final String? intru9;
  final String? intru10;
  final String createdOn;

  IntrusionNumber({
    required this.intruId,
    required this.usrId,
    required this.intru1,
    required this.intru2,
    required this.intru3,
    required this.intru4,
    required this.intru5,
    required this.intru6,
    required this.intru7,
    required this.intru8,
    required this.intru9,
    required this.intru10,
    required this.createdOn,
  });

  factory IntrusionNumber.fromJson(Map<String, dynamic> json) {
    return IntrusionNumber(
      intruId: json['intru_id'],
      usrId: json['usr_id'].toString(),
      intru1: json['intru1']?.toString(),
      intru2: json['intru2']?.toString(),
      intru3: json['intru3']?.toString(),
      intru4: json['intru4']?.toString(),
      intru5: json['intru5']?.toString(),
      intru6: json['intru6']?.toString(),
      intru7: json['intru7']?.toString(),
      intru8: json['intru8']?.toString(),
      intru9: json['intru9']?.toString(),
      intru10: json['intru10']?.toString(),
      createdOn: json['c_on']['date'] ?? '',
    );
  }

  @override
  String toString() {
    return 'IntrusionNumber(intruId: $intruId, usrId: $usrId, intru1: $intru1, intru2: $intru2, createdOn: $createdOn)';
  }
}
