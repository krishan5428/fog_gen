import '../data/pojo/fire_list.dart';

class FireResponse {
  final bool status;
  final List<FireNumber> fireNumbers;
  final String msg;

  FireResponse({
    required this.status,
    required this.fireNumbers,
    required this.msg,
  });

  factory FireResponse.fromJson(Map<String, dynamic> json) {
    return FireResponse(
      status: json['status'] ?? false,
      fireNumbers:
          (json['fire_numbers'] as List<dynamic>?)
              ?.map((e) => FireNumber.fromJson(e))
              .toList() ??
          [],
      msg: json['msg'] ?? '',
    );
  }

  @override
  String toString() {
    return 'FireResponse(status: $status, msg: $msg, FireResponse: $fireNumbers)';
  }
}
