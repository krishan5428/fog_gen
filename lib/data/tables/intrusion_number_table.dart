import 'package:drift/drift.dart';

class IntrusionNumbers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get panelSimNumber => text()();
  TextColumn get intrusionNumber => text()();
}
