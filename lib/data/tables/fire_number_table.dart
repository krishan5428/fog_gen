import 'package:drift/drift.dart';

class FireNumbers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get panelSimNumber => text()();
  TextColumn get fireNumber => text()();
}
