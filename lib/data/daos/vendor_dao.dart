import 'package:drift/drift.dart';
import 'package:fire_nex/data/database/app_database.dart';

import '../tables/vendor_table.dart';

part 'vendor_dao.g.dart';

@DriftAccessor(tables: [Vendor])
class VendorDao extends DatabaseAccessor<AppDatabase> with _$VendorDaoMixin {
  VendorDao(super.db);

  // Insert User
  Future<int> insertVendor(VendorCompanion vendorCompanion) =>
      into(vendor).insert(vendorCompanion);

  Future<VendorData?> getVendorByUserId(int userId) {
    return (select(vendor)
          ..where((u) => u.userId.equals(userId))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> updateVendorName(int userId, String newName) {
    return (update(vendor)..where(
          (u) => u.id.equals(userId),
    )).write(VendorCompanion(name: Value(newName)));
  }

  Future<void> updateVendorMobile(int userId, String newMobile) {
    return (update(vendor)..where(
          (u) => u.id.equals(userId),
    )).write(VendorCompanion(mobileNumber: Value(newMobile)));
  }

  Future<void> updateVendorEmail(int userId, String newEmail) {
    return (update(vendor)..where(
          (u) => u.id.equals(userId),
    )).write(VendorCompanion(email: Value(newEmail)));
  }

  Future<int> deleteVendor(int userId) {
    return (delete(vendor)..where((u) => u.id.equals(userId))).go();
  }
}
