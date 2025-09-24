import 'package:fire_nex/data/database/app_database.dart';

class ComplaintRepository {
  final AppDatabase _db;

  ComplaintRepository(this._db);

  Future<void> insertComplaint(ComplaintTableCompanion companion) {
    return _db.complaintDao.insertComplaint(companion);
  }

  Future<List<ComplaintTableData>> getComplaintsByUserId(String userId) {
    return _db.complaintDao.getComplaintByUserId(userId);
  }
}
