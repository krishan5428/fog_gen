import 'package:drift/drift.dart';
import 'package:fire_nex/data/database/app_database.dart';

class IntrusionRepository {
  final AppDatabase _db;

  IntrusionRepository(this._db);

  // create
  Future<int> insertIntrusionNumber(
    String panelSimNumber,
    String intrusionNumber,
  ) {
    final companion = IntrusionNumbersCompanion(
      panelSimNumber: Value(panelSimNumber),
      intrusionNumber: Value(intrusionNumber),
    );
    return _db.intrusionNumberDao.insertIntrusionNumber(companion);
  }

  // get
  Future<List<IntrusionNumber>> getIntrusionNumbersByPanelSimNumber(
    String panelSimNumber,
  ) {
    return _db.intrusionNumberDao.getIntrusionNumbersByPanelSimNumber(
      panelSimNumber,
    );
  }
}
