import 'package:drift/drift.dart';
import 'package:fire_nex/data/database/app_database.dart';

class AutomationRepository {
  final AppDatabase _db;

  AutomationRepository(this._db);

  Future<void> accessAutoArm(String panelSimNumber, bool isActive) async {
    final entry = AutomationTableCompanion(
      panelSimNumber: Value(panelSimNumber),
      isArmToggled: Value(isActive),
    );
    await _db.automationDao.upsertAutomation(entry);
  }

  Future<void> resetAutoArm(String panelSimNumber) async {
    final entry = AutomationTableCompanion(
      panelSimNumber: Value(panelSimNumber),
      isArmToggled: Value(false),
      autoArmTime: Value(null),
    );
    await _db.automationDao.upsertAutomation(entry);
  }

  Future<void> accessAutoDisarm(String panelSimNumber, bool isActive) async {
    final entry = AutomationTableCompanion(
      panelSimNumber: Value(panelSimNumber),
      isDisarmToggled: Value(isActive),
    );
    await _db.automationDao.upsertAutomation(entry);
  }

  Future<void> resetAutoDisarm(String panelSimNumber) async {
    final entry = AutomationTableCompanion(
      panelSimNumber: Value(panelSimNumber),
      isDisarmToggled: Value(false),
      autoDisarmTime: Value(null),
    );
    await _db.automationDao.upsertAutomation(entry);
  }

  Future<void> accessHoliday(String panelSimNumber, bool isActive) async {
    final entry = AutomationTableCompanion(
      panelSimNumber: Value(panelSimNumber),
      isHolidayToggled: Value(isActive),
    );
    await _db.automationDao.upsertAutomation(entry);
  }

  Future<void> resetHoliday(String panelSimNumber) async {
    final entry = AutomationTableCompanion(
      panelSimNumber: Value(panelSimNumber),
      isHolidayToggled: Value(false),
      holidayTime: Value(null),
    );
    await _db.automationDao.upsertAutomation(entry);
  }

  Future<void> insertAutoArm(String panelSimNumber, String autoArmTime) async {
    final entry = AutomationTableCompanion(
      panelSimNumber: Value(panelSimNumber),
      autoArmTime: Value(autoArmTime),
    );
    await _db.automationDao.upsertAutomation(entry);
  }

  Future<void> insertAutoDisarm(
    String panelSimNumber,
    String autoDisarmTime,
  ) async {
    final entry = AutomationTableCompanion(
      panelSimNumber: Value(panelSimNumber),
      autoDisarmTime: Value(autoDisarmTime),
    );
    await _db.automationDao.upsertAutomation(entry);
  }

  Future<void> insertHoliday(String panelSimNumber, String holiday) async {
    final entry = AutomationTableCompanion(
      panelSimNumber: Value(panelSimNumber),
      holidayTime: Value(holiday),
    );
    await _db.automationDao.upsertAutomation(entry);
  }

  Future<List<AutomationTableData>> getAutomationBySim(String panelSimNumber) {
    return _db.automationDao.getAutomationByPanelSim(panelSimNumber);
  }
}
