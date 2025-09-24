import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../tables/panel_table.dart';

part 'panel_dao.g.dart';

@DriftAccessor(tables: [Panel])
class PanelDao extends DatabaseAccessor<AppDatabase> with _$PanelDaoMixin {
  PanelDao(super.db);

  // insert panel
  Future<int> insertPanel(PanelCompanion companion) =>
      into(panel).insert(companion);

  Future<PanelData?> getPanelBySiteName(String siteName) {
    final normalizedSiteName = siteName.trim().toLowerCase();
    return (select(panel)
          ..where((tbl) => tbl.siteName.lower().equals(normalizedSiteName))
          ..limit(1))
        .getSingleOrNull();
  }

  // get panel data with panel sim number
  Future<PanelData?> getPanelByPanelSimNumber(String panelSimNumber) {
    return (select(panel)
          ..where((u) => u.panelSimNumber.equals(panelSimNumber))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<PanelData>> getAllPanelWithUserId(int userId) {
    final query = select(panel);

    // since userId is an int, just check > 0 (or nullable if needed)
    if (userId > 0) {
      query.where((tbl) => tbl.userId.equals(userId));
    }

    return query.get();
  }

  Future<List<PanelData>> getFilteredPanels({
    int? userId,
    String panelType = 'ALL',
  }) {
    final query = select(panel);

    if (panelType != 'ALL') {
      query.where((tbl) => tbl.panelType.equals(panelType));
    }

    if (userId != null && userId > 0) {
      query.where((tbl) => tbl.userId.equals(userId));
    }

    return query.get();
  }

  Future<List<PanelData>> getPanelData() {
    return select(panel).get();
  }

  Future<int> updateAdminCode(String panelSimNumber, String newAdminCode) {
    return (update(panel)..where(
      (tbl) => tbl.panelSimNumber.equals(panelSimNumber),
    )).write(PanelCompanion(adminCode: Value(newAdminCode)));
  }

  Future<int> updateAddress(String panelSimNumber, String newAddress) {
    return (update(panel)..where(
      (tbl) => tbl.panelSimNumber.equals(panelSimNumber),
    )).write(PanelCompanion(address: Value(newAddress)));
  }

  Future<int> updateAdminMobileNumber(
    String panelSimNumber,
    String newAdminMobileNumber,
  ) {
    return (update(panel)
      ..where((tbl) => tbl.panelSimNumber.equals(panelSimNumber))).write(
      PanelCompanion(adminMobileNumber: Value(newAdminMobileNumber)),
    ); // ✅ fixed
  }

  Future<int> deletePanelByPanelSimNumber(String panelSimNumber) {
    return (delete(panel)
      ..where((tbl) => tbl.panelSimNumber.equals(panelSimNumber))).go();
  }

  Future<int> updateMobileNumber(
    String panelSimNumber,
    String newMobileNumber,
    int index,
  ) async {
    late final PanelCompanion companion;

    switch (index) {
      case 1:
        companion = PanelCompanion(mobileNumber1: Value(newMobileNumber));
        break;
      case 2:
        companion = PanelCompanion(mobileNumber2: Value(newMobileNumber));
        break;
      case 3:
        companion = PanelCompanion(mobileNumber3: Value(newMobileNumber));
        break;
      case 4:
        companion = PanelCompanion(mobileNumber4: Value(newMobileNumber));
        break;
      case 5:
        companion = PanelCompanion(mobileNumber5: Value(newMobileNumber));
        break;
      case 6:
        companion = PanelCompanion(mobileNumber6: Value(newMobileNumber));
        break;
      case 7:
        companion = PanelCompanion(mobileNumber7: Value(newMobileNumber));
        break;
      case 8:
        companion = PanelCompanion(mobileNumber8: Value(newMobileNumber));
        break;
      case 9:
        companion = PanelCompanion(mobileNumber9: Value(newMobileNumber));
        break;
      case 10:
        companion = PanelCompanion(mobileNumber10: Value(newMobileNumber));
        break;
      default:
        throw Exception("Invalid index $index");
    }

    // await ensures the update completes before returning
    return await (update(panel)..where(
      (tbl) => tbl.panelSimNumber.equals(panelSimNumber),
    )).write(companion);
  }
}
