import 'package:drift/drift.dart';

class Panel extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get panelSimNumber => text().customConstraint('NOT NULL UNIQUE')();
  IntColumn get userId => integer()();
  TextColumn get siteName => text().customConstraint('NOT NULL UNIQUE')();
  TextColumn get panelName => text()();
  TextColumn get adminCode => text()();
  TextColumn get adminMobileNumber => text()();
  TextColumn get panelType => text()();
  TextColumn get address => text()();
  TextColumn get mobileNumber1 =>
      text().withDefault(const Constant("0000000000"))();
  TextColumn get mobileNumber2 =>
      text().withDefault(const Constant("0000000000"))();
  TextColumn get mobileNumber3 =>
      text().withDefault(const Constant("0000000000"))();
  TextColumn get mobileNumber4 =>
      text().withDefault(const Constant("0000000000"))();
  TextColumn get mobileNumber5 =>
      text().withDefault(const Constant("0000000000"))();
  TextColumn get mobileNumber6 =>
      text().withDefault(const Constant("0000000000"))();
  TextColumn get mobileNumber7 =>
      text().withDefault(const Constant("0000000000"))();
  TextColumn get mobileNumber8 =>
      text().withDefault(const Constant("0000000000"))();
  TextColumn get mobileNumber9 =>
      text().withDefault(const Constant("0000000000"))();
  TextColumn get mobileNumber10 =>
      text().withDefault(const Constant("0000000000"))();
  BoolColumn get isIPPanel => boolean()();
  BoolColumn get isIPGPRSPanel => boolean()();
  TextColumn get ipAddress => text()();
  TextColumn get port => text()();
  TextColumn get staticIPAddress => text()();
  TextColumn get staticPort => text()();
  TextColumn get ipPassword => text()();
}
