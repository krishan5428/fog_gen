import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../tables/intrusion_number_table.dart';

part 'intrusion_number_dao.g.dart';

@DriftAccessor(tables: [IntrusionNumbers])
class IntrusionNumberDao extends DatabaseAccessor<AppDatabase>
    with _$IntrusionNumberDaoMixin {
  IntrusionNumberDao(super.db);

  Future<List<IntrusionNumber>>? getAllIntrusionNumbers() =>
      select(intrusionNumbers).get();

  Future<int> insertIntrusionNumber(IntrusionNumbersCompanion data) =>
      into(intrusionNumbers).insert(data);

  Future<void> deleteIntrusionNumber(int id) =>
      (delete(intrusionNumbers)..where((t) => t.id.equals(id))).go();

  Future<List<IntrusionNumber>> getIntrusionNumbersByPanelSimNumber(
    String panelSim,
  ) async {
    final results =
        await (select(intrusionNumbers)
          ..where((t) => t.panelSimNumber.equals(panelSim))).get();
    print('DB Returned: ${results.map((e) => e.intrusionNumber).toList()}');
    return results;
  }
}
