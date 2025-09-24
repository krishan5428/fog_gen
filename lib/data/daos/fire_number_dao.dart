import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../tables/fire_number_table.dart';

part 'fire_number_dao.g.dart';

@DriftAccessor(tables: [FireNumbers])
class FireNumberDao extends DatabaseAccessor<AppDatabase>
    with _$FireNumberDaoMixin {
  FireNumberDao(super.db);

  //
  // Future<List<FireNumber>>? getAllFireNumbers() =>
  //     select(fireNumbers).get();
  //
  Future<int> insertFireNumber(FireNumbersCompanion data) =>
      into(fireNumbers).insert(data);

  Future<List<FireNumber>> getFireNumbersByPanelSimNumber(
    String panelSim,
  ) async {
    final results =
        await (select(fireNumbers)
          ..where((t) => t.panelSimNumber.equals(panelSim))).get();
    print('DB Returned: ${results.map((e) => e.fireNumber).toList()}');
    return results;
  }
}
