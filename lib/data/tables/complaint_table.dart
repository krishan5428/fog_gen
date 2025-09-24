import 'package:drift/drift.dart';

class ComplaintTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get subject => text()();
  TextColumn get remark => text()();
  TextColumn get cOn => text()();
  TextColumn get siteName => text()();
  TextColumn get userId => text()();
  TextColumn get image1Path => text().nullable()();
  TextColumn get image2Path => text().nullable()();
  TextColumn get image3Path => text().nullable()();
}
