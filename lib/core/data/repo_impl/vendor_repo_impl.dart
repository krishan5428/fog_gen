import 'package:dio/dio.dart';

import '../../../utils/auth_helper.dart';
import '../../api/api_client.dart';
import '../../api/web_url_constants.dart';
import '../../repo/vendor_repo.dart';
import '../../responses/add_vendor_response.dart';
import '../../responses/del_vendor_response.dart';
import '../../responses/get_vendor_response.dart';

class VendorRepoImpl implements VendorRepo {
  final Dio _dio = ApiClient.dio;
  @override
  Future<AddVendorResponse> addVendor(
    String userId,
    String vendorName,
    String vendorEmail,
    String vendorMobile,
    String vendorAddress,
    String createdAt,
  ) async {
    final response = await _dio.post(
      WebUrlConstants.addVendor,
      data: FormData.fromMap({
        'usr_id': userId,
        'vendor_name': vendorName,
        'vendor_email': vendorEmail,
        'vendor_mob_no': vendorMobile,
        'vendor_address': vendorAddress,
      }),
    );
    return AddVendorResponse.fromJson(response.data);
  }

  @override
  Future<GetVendorResponse> getVendor(String userId) async {
    try {
      final response = await _dio.post(
        WebUrlConstants.getVendor,
        data: FormData.fromMap({'usr_id': userId}),
      );
      return GetVendorResponse.fromJson(response.data);
    } on DioException {
      throw Exception("Failed to fetch vendor list. Please try again.");
    } catch (e) {
      throw Exception("Unexpected error while fetching vendors.");
    }
  }

  @override
  Future<DeleteVendorResponse> deleteVendor(String vendorMobile) async {
    try {
      // del_vendor.php clears the vendor stored in the logged-in user's row.
      final userId = await SharedPreferenceHelper.getUserId();
      final response = await _dio.post(
        WebUrlConstants.delVendor,
        data: FormData.fromMap({'usr_id': userId?.toString() ?? ''}),
      );
      return DeleteVendorResponse.fromJson(response.data);
    } on DioException {
      throw Exception("Failed to fetch vendor list. Please try again.");
    } catch (e) {
      throw Exception("Unexpected error while fetching vendors.");
    }
  }
}
