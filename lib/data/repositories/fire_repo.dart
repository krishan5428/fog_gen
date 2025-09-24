import 'package:drift/drift.dart';
import 'package:fire_nex/data/database/app_database.dart';

class FireRepository {
  final AppDatabase _db;

  FireRepository(this._db);

  // create
  Future<int> insertFireNumber(String panelSimNumber, String fireNumber) {
    final companion = FireNumbersCompanion(
      panelSimNumber: Value(panelSimNumber),
      fireNumber: Value(fireNumber),
    );
    return _db.fireNumberDao.insertFireNumber(companion);
  }

  // get
  Future<List<FireNumber>> getFireNumbersByPanelSimNumber(
    String panelSimNumber,
  ) {
    return _db.fireNumberDao.getFireNumbersByPanelSimNumber(panelSimNumber);
  }
}
