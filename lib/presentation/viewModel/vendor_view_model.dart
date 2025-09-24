import 'package:flutter/foundation.dart';
import 'package:fire_nex/data/database/app_database.dart';
import 'package:fire_nex/data/repositories/vendor_repository.dart';

class VendorViewModel {
  final VendorRepository _vendorRepository;

  VendorViewModel(this._vendorRepository);

  Future<bool> insertVendor(
    String name,
    String email,
    String mobile,
    int userId,
    String address,
  ) async {
    try {
      await _vendorRepository.insertVendor(
        name,
        email,
        mobile,
        userId,
        address,
      );
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Insert failed: $e');
      }
      return false;
    }
  }

  Future<VendorData?> getVendorByUserId(int userId) {
    return _vendorRepository.getVendorByUserId(userId);
  }
}
