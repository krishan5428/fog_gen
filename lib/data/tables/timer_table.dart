import 'package:drift/drift.dart';

class TimerTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get panelSimNumber => text()();
  TextColumn get entryTime => text().nullable()();
  TextColumn get exitTime => text().nullable()();
  TextColumn get sounderTime => text().nullable()();
}
