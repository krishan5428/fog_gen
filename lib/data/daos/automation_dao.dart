import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../tables/automation_table.dart';

part 'automation_dao.g.dart';

@DriftAccessor(tables: [AutomationTable])
class AutomationDao extends DatabaseAccessor<AppDatabase>
    with _$AutomationDaoMixin {
  AutomationDao(super.db);

  Future<int> insertAutomation(AutomationTableCompanion companion) {
    return into(automationTable).insert(companion);
  }

  Future<List<AutomationTableData>> getAutomationByPanelSim(
    String panelSimNumber,
  ) {
    return (select(automationTable)
      ..where((tbl) => tbl.panelSimNumber.equals(panelSimNumber))).get();
  }

  Future<void> upsertAutomation(AutomationTableCompanion companion) async {
    final sim = companion.panelSimNumber.value;

    final existing = await getAutomationByPanelSim(sim);
    if (existing.isEmpty) {
      await insertAutomation(companion);
      print('[upsertAutomation] Inserted new record for SIM $sim');
    } else {
      final updateQuery = update(automationTable)
        ..where((tbl) => tbl.panelSimNumber.equals(sim));
      await updateQuery.write(companion); // This is fine now.
      print('[upsertAutomation] Updated existing record for SIM $sim');
    }
  }
}
