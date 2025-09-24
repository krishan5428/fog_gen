import 'package:fire_nex/data/database/app_database.dart';

class PanelRepository {
  final AppDatabase _db;

  PanelRepository(this._db);

  // create
  Future<int> insertPanel(PanelCompanion companion) {
    return _db.panelDao.insertPanel(companion);
  }

  // get
  Future<PanelData?> getPanelByPanelSimNumber(String panelSimNumber) {
    return _db.panelDao.getPanelByPanelSimNumber(panelSimNumber);
  }

  Future<PanelData?> getPanelBySiteName(String siteName) {
    return _db.panelDao.getPanelBySiteName(siteName);
  }

  Future<List<PanelData>> getAllPanelWithUserId(int userId) {
    return _db.panelDao.getAllPanelWithUserId(userId);
  }

  Future<List<PanelData>> getFilteredPanels(int userId, String panelType) {
    return _db.panelDao.getFilteredPanels(userId: userId, panelType: panelType);
  }

  Future<List<PanelData>> getAllPanels() {
    return _db.panelDao.getPanelData();
  }

  Future<int> updateAdminCode(String panelSimNumber, String newAdminCode) {
    return _db.panelDao.updateAdminCode(panelSimNumber, newAdminCode);
  }

  Future<int> updateAddress(String panelSimNumber, String newAddress) {
    return _db.panelDao.updateAddress(panelSimNumber, newAddress);
  }

  Future<int> updateAdminMobileNumber(
    String panelSimNumber,
    String newAdminMobileNumber,
  ) {
    return _db.panelDao.updateAdminMobileNumber(
      panelSimNumber,
      newAdminMobileNumber,
    );
  }

  Future<int> updateMobileNumber(
    String panelSimNumber,
    String newAdminMobileNumber,
    int index,
  ) {
    return _db.panelDao.updateMobileNumber(
      panelSimNumber,
      newAdminMobileNumber,
      index,
    );
  }

  Future<int> deletePanel(String panelSimNumber) {
    return _db.panelDao.deletePanelByPanelSimNumber(panelSimNumber);
  }

  Future<int> updatePanel(PanelData panel) {
    return (_db.update(_db.panel)..where(
      (tbl) => tbl.panelSimNumber.equals(panel.panelSimNumber),
    )).write(panel.toCompanion(true));
  }
}
