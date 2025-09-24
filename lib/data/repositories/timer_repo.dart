import 'package:drift/drift.dart';
import 'package:fire_nex/data/database/app_database.dart';

class TimerRepository {
  final AppDatabase _db;

  TimerRepository(this._db);

  // Insert Entry Time
  Future<void> insertEntryTime(String panelSimNumber, String entryTime) async {
    print(
      '[insertEntryTime] Called with: panelSimNumber=$panelSimNumber, entryTime=$entryTime',
    );

    final existing = await _db.timerDao.getTimersByPanelSim(panelSimNumber);
    print('[insertEntryTime] Existing timers found: ${existing.length}');

    if (existing.isEmpty) {
      final entry = TimerTableCompanion(
        panelSimNumber: Value(panelSimNumber),
        entryTime: Value(entryTime),
      );
      await _db.timerDao.insertTimer(entry);
      print('[insertEntryTime] Inserted new timer row');
    } else {
      final updated = existing.first.copyWith(entryTime: Value(entryTime));
      await _db.timerDao.updateTimer(updated);
      print('[insertEntryTime] Updated existing timer row with new entry time');
    }
  }

  // Insert Exit Time
  Future<void> insertExitTime(String panelSimNumber, String exitTime) async {
    print(
      '[insertExitTime] Called with: panelSimNumber=$panelSimNumber, exitTime=$exitTime',
    );

    final existing = await _db.timerDao.getTimersByPanelSim(panelSimNumber);
    print('[insertExitTime] Existing timers found: ${existing.length}');

    if (existing.isEmpty) {
      final entry = TimerTableCompanion(
        panelSimNumber: Value(panelSimNumber),
        exitTime: Value(exitTime),
      );
      await _db.timerDao.insertTimer(entry);
      print('[insertExitTime] Inserted new timer row');
    } else {
      final updated = existing.first.copyWith(exitTime: Value(exitTime));
      await _db.timerDao.updateTimer(updated);
      print('[insertExitTime] Updated existing timer row with new exit time');
    }
  }

  // Insert Sounder Time
  Future<void> insertSounderTime(
    String panelSimNumber,
    String sounderTime,
  ) async {
    print(
      '[insertSounderTime] Called with: panelSimNumber=$panelSimNumber, sounderTime=$sounderTime',
    );

    final existing = await _db.timerDao.getTimersByPanelSim(panelSimNumber);
    print('[insertSounderTime] Existing timers found: ${existing.length}');

    if (existing.isEmpty) {
      final entry = TimerTableCompanion(
        panelSimNumber: Value(panelSimNumber),
        sounderTime: Value(sounderTime),
      );
      await _db.timerDao.insertTimer(entry);
      print('[insertSounderTime] Inserted new timer row');
    } else {
      final updated = existing.first.copyWith(sounderTime: Value(sounderTime));
      await _db.timerDao.updateTimer(updated);
      print(
        '[insertSounderTime] Updated existing timer row with new sounder time',
      );
    }
  }

  // Get all timers for a SIM
  Future<List<TimerTableData>> getTimersByPanelSim(String panelSimNumber) {
    return _db.timerDao.getTimersByPanelSim(panelSimNumber);
  }
}
