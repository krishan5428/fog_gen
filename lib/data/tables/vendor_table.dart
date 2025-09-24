import 'package:drift/drift.dart';

class Vendor extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get email => text()();
  IntColumn get userId => integer()();
  TextColumn get mobileNumber => text()();
  TextColumn get address => text()();
}
