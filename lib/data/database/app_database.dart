import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_sqflite/drift_sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:fire_nex/data/tables/intrusion_number_table.dart';

import '../daos/automation_dao.dart';
import '../daos/complaint_dao.dart';
import '../daos/fire_number_dao.dart';
import '../daos/intrusion_number_dao.dart';
import '../daos/panel_dao.dart';
import '../daos/timer_dao.dart';
import '../daos/user_dao.dart';
import '../daos/vendor_dao.dart';
import '../tables/automation_table.dart';
import '../tables/complaint_table.dart';
import '../tables/fire_number_table.dart';
import '../tables/panel_table.dart';
import '../tables/timer_table.dart';
import '../tables/user_table.dart';
import '../tables/vendor_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    User,
    Panel,
    Vendor,
    IntrusionNumbers,
    FireNumbers,
    TimerTable,
    AutomationTable,
    ComplaintTable,
  ],
  daos: [
    UserDao,
    PanelDao,
    VendorDao,
    IntrusionNumberDao,
    FireNumberDao,
    TimerDao,
    AutomationDao,
    ComplaintDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Drift asks the schema version for migrations
  @override
  int get schemaVersion => 1;

  // You can now access: userDao.insertUser(), etc.

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from == 1) {
        await m.createTable(timerTable);
      }
      // handle the upgrades here
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db11.sqlite'));
    return SqfliteQueryExecutor(path: file.path, logStatements: true);
  });
}

// flutter clean
// flutter pub get
// flutter run
