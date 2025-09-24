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
}
