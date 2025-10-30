import '../responses/add_vendor_response.dart';
import '../responses/del_vendor_response.dart';
import '../responses/get_vendor_response.dart';

abstract class VendorRepo {
  Future<AddVendorResponse> addVendor(
    String userId,
    String vendorName,
    String vendorEmail,
    String vendorMobile,
    String vendorAddress,
    String createdAt,
  );

  Future<GetVendorResponse> getVendor(String userId);

  Future<DeleteVendorResponse> deleteVendor(String vendorMobile);
}
