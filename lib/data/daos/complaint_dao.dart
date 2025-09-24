import 'package:drift/drift.dart';
import 'package:fire_nex/data/database/app_database.dart';

import '../tables/complaint_table.dart';

part 'complaint_dao.g.dart';

@DriftAccessor(tables: [ComplaintTable])
class ComplaintDao extends DatabaseAccessor<AppDatabase>
    with _$ComplaintDaoMixin {
  ComplaintDao(super.dao);

  Future<int> insertComplaint(ComplaintTableCompanion companion) {
    return into(complaintTable).insert(companion);
  }

  Future<List<ComplaintTableData>> getComplaintByUserId(String userId) {
    return (select(complaintTable)
      ..where((tbl) => tbl.userId.equals(userId))).get();
  }
}
