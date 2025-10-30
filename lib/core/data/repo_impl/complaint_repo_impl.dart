import 'package:dio/dio.dart';

import '../../api/api_client.dart';
import '../../repo/complaint_repo.dart';
import '../../responses/add_complaint_response.dart';
import '../../responses/complaint_history_response.dart';

class ComplaintRepoImpl implements ComplaintRepo {
  final Dio dio = ApiClient.dio;

  @override
  Future<AddComplaintResponse> addComplaint({
    required String remark,
    required String subject,
    required String userId,
    required String siteName,
    String? image1Path,
    String? image2Path,
    String? image3Path,
  }) async {
    final formData = FormData.fromMap({
      'remark': remark,
      'subject': subject,
      'userId': userId,
      'siteName': siteName,
      if (image1Path != null)
        'image1Path': await MultipartFile.fromFile(image1Path),
      if (image2Path != null)
        'image2Path': await MultipartFile.fromFile(image2Path),
      if (image3Path != null)
        'image3Path': await MultipartFile.fromFile(image3Path),
    });

    final response = await dio.post('add_complain.php', data: formData);

    return AddComplaintResponse.fromJson(response.data);
  }

  @override
  Future<ComplaintHistoryResponse> getComplaintHistory({
    required String userId,
  }) async {
    final formData = FormData.fromMap({'userId': userId});

    final response = await dio.post('get_complain_list.php', data: formData);

    return ComplaintHistoryResponse.fromJson(response.data);
  }
}
