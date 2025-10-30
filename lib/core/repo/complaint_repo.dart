import '../responses/add_complaint_response.dart';
import '../responses/complaint_history_response.dart';

abstract class ComplaintRepo {
  Future<AddComplaintResponse> addComplaint({
    required String remark,
    required String subject,
    required String userId,
    required String siteName,
    String? image1Path,
    String? image2Path,
    String? image3Path,
  });

  Future<ComplaintHistoryResponse> getComplaintHistory({
    required String userId,
  });
}
