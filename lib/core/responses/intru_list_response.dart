import '../data/pojo/intru_list.dart';

class IntrusionResponse {
  final bool status;
  final List<IntrusionNumber> intrusionNumbers;
  final String msg;

  IntrusionResponse({
    required this.status,
    required this.intrusionNumbers,
    required this.msg,
  });

  factory IntrusionResponse.fromJson(Map<String, dynamic> json) {
    return IntrusionResponse(
      status: json['status'] ?? false,
      intrusionNumbers:
          (json['intrusion_numbers'] as List<dynamic>?)
              ?.map((e) => IntrusionNumber.fromJson(e))
              .toList() ??
          [],
      msg: json['msg'] ?? '',
    );
  }

  @override
  String toString() {
    return 'IntrusionResponse(status: $status, msg: $msg, intrusionNumbers: $intrusionNumbers)';
  }
}
