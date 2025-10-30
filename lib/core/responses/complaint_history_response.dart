import '../data/pojo/complaint_data.dart';

class ComplaintHistoryResponse {
  final bool status;
  final List<ComplaintData> complaints;
  final String message;

  ComplaintHistoryResponse({
    required this.status,
    required this.message,
    required this.complaints,
  });

  factory ComplaintHistoryResponse.fromJson(Map<String, dynamic> json) {
    return ComplaintHistoryResponse(
      status: json['status'],
      message: json['msg'],
      complaints:
          json['complains'] != null
              ? List<ComplaintData>.from(
                json['complains'].map((e) => ComplaintData.fromJson(e)),
              )
              : [],
    );
  }
}
