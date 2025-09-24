import 'package:drift/drift.dart';
import 'package:fire_nex/data/database/app_database.dart';
import 'package:fire_nex/data/tables/timer_table.dart';

part 'timer_dao.g.dart';

@DriftAccessor(tables: [TimerTable])
class TimerDao extends DatabaseAccessor<AppDatabase> with _$TimerDaoMixin {
  TimerDao(super.db);

  Future<int> insertTimer(TimerTableCompanion companion) {
    return into(timerTable).insert(companion);
  }

  Future updateTimer(TimerTableData timer) {
    return update(timerTable).replace(timer);
  }

  Future<List<TimerTableData>> getTimersByPanelSim(String panelSimNumber) {
    return (select(timerTable)
      ..where((tbl) => tbl.panelSimNumber.equals(panelSimNumber))).get();
  }
}
