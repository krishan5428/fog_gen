import 'package:drift/drift.dart';
import 'package:fire_nex/data/database/app_database.dart';

class VendorRepository {
  final AppDatabase _db;

  VendorRepository(this._db);

  // create
  Future<int> insertVendor(
    String name,
    String email,
    String mobileNumber,
    int userId,
    String address,
  ) {
    final vendor = VendorCompanion(
      name: Value(name),
      email: Value(email),
      mobileNumber: Value(mobileNumber),
      userId: Value(userId),
      address: Value(address),
    );
    return _db.vendorDao.insertVendor(vendor);
  }

  // get
  Future<VendorData?> getVendorByUserId(int userId) {
    return _db.vendorDao.getVendorByUserId(userId);
  }


  // update
  Future<void> updateVendorName(int userId, String newName) {
    return _db.vendorDao.updateVendorName(userId, newName);
  }

  Future<void> updateVendorMobile(int userId, String newMobile) {
    return _db.vendorDao.updateVendorMobile(userId, newMobile);
  }

  Future<void> updateVendorEmail(int userId, String newEmail) {
    return _db.vendorDao.updateVendorEmail(userId, newEmail);
  }

  Future<void> deleteVendor(int userId) async {
    await _db.vendorDao.deleteVendor(userId);
  }
}
