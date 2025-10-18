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
  int get schemaVersion => 3; // updated schema for Panel Table: added IP Panel flow

  // You can now access: userDao.insertUser(), etc.

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          // Boolean column with default 0 (false)
          await customStatement(
              'ALTER TABLE panel ADD COLUMN is_i_p_panel INTEGER NOT NULL DEFAULT 0;'
          );

          // Text columns with default empty string
          await customStatement('UPDATE panel SET is_i_p_panel = 0 WHERE is_i_p_panel IS NULL;');
          await customStatement('UPDATE panel SET ip_address = "" WHERE ip_address IS NULL;');
          await customStatement('UPDATE panel SET port = "" WHERE port IS NULL;');
          await customStatement('UPDATE panel SET static_ip_address = "" WHERE static_ip_address IS NULL;');
          await customStatement('UPDATE panel SET static_port = "" WHERE static_port IS NULL;');
          await customStatement('UPDATE panel SET ip_password = "" WHERE ip_password IS NULL;');
        }
        if(from < 3){
          await customStatement('UPDATE panel SET is_ip_gprs_panel = 0 WHERE is_ip_gprs_panel IS NULL;');
        }
      }
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db12.sqlite'));
    return SqfliteQueryExecutor(path: file.path, logStatements: true);
  });
}