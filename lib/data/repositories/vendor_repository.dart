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
}
