import 'package:drift/drift.dart';

class AutomationTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get panelSimNumber => text()();
  TextColumn get autoArmTime => text().nullable()();
  TextColumn get autoDisarmTime => text().nullable()();
  TextColumn get holidayTime => text().nullable()();
  BoolColumn get isArmToggled => boolean().withDefault(Constant(false))();
  BoolColumn get isDisarmToggled => boolean().withDefault(Constant(false))();
  BoolColumn get isHolidayToggled => boolean().withDefault(Constant(false))();
}
