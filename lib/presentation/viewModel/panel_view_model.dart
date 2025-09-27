import 'package:drift/native.dart';
import 'package:fire_nex/data/database/app_database.dart';
import 'package:fire_nex/data/modelClass/site_panel_info.dart';
import 'package:fire_nex/data/repositories/panel_repo.dart';
import 'package:flutter/foundation.dart';

class PanelViewModel extends ChangeNotifier {
  final PanelRepository _panelRepository;

  PanelViewModel(this._panelRepository);

  PanelData? _currentPanel;
  PanelData? get currentPanel => _currentPanel;
  List<SitePanelSimInfo> sitePanelInfoList = [];
  void setCurrentPanel(PanelData panel) {
    _currentPanel = panel;
    notifyListeners();
  }

  void clearCurrentPanel() {
    _currentPanel = null;
    notifyListeners();
  }

  Future<InsertPanelResult> insertPanel(
    String panelType,
    String panelCategory,
    String panelSimNumber,
    String mobileNumber,
    String siteName,
    String address,
    String adminCode,
    int userId,
  ) async {
    final normalizedSiteName = siteName.trim().toLowerCase();

    final existingSim = await _panelRepository.getPanelByPanelSimNumber(
      panelSimNumber,
    );
    if (existingSim != null) {
      return InsertPanelResult.simNumberExists;
    }

    final existingSite = await _panelRepository.getPanelBySiteName(
      normalizedSiteName,
    );
    if (existingSite != null) {
      return InsertPanelResult.siteNameExists;
    }

    final companion = PanelCompanion.insert(
      panelType: panelType,
      panelName: panelCategory,
      panelSimNumber: panelSimNumber,
      adminMobileNumber: mobileNumber,
      siteName: normalizedSiteName,
      address: address,
      adminCode: adminCode,
      userId: userId,
    );

    try {
      await _panelRepository.insertPanel(companion);
      return InsertPanelResult.success;
    } on SqliteException catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains('panel_sim_number')) {
        return InsertPanelResult.simNumberExists;
      } else if (message.contains('site_name')) {
        return InsertPanelResult.siteNameExists;
      } else {
        return InsertPanelResult.failure;
      }
    } catch (_) {
      return InsertPanelResult.failure;
    }
  }

  Future<void> refreshPanel(String panelSimNumber) async {
    final updatedPanel = await _panelRepository.getPanelByPanelSimNumber(
      panelSimNumber,
    );
    if (updatedPanel != null) {
      setCurrentPanel(updatedPanel); // this notifies listeners
    }
  }

  Future<List<PanelData>> getAllPanelWithUserId(int userId) {
    return _panelRepository.getAllPanelWithUserId(userId);
  }

  Future<PanelData?> getPanelByPanelSimNumber(String panelSimNumber) {
    return _panelRepository.getPanelByPanelSimNumber(panelSimNumber);
  }

  Future<List<PanelData>> getFilteredPanels(int userId, String panelType) {
    return _panelRepository.getFilteredPanels(userId, panelType);
  }

  Future<List<PanelData>> getAllPanels() {
    return _panelRepository.getAllPanels();
  }

  Future<bool> updatePanelDetails({
    required String siteName,
    required String simNumber,
  }) async {
    try {
      if (_currentPanel == null) return false;

      final updated = _currentPanel!.copyWith(
        siteName: siteName.trim().toLowerCase(),
        panelSimNumber: simNumber.trim(),
      );

      final result = await _panelRepository.updatePanel(updated);

      if (result > 0) {
        setCurrentPanel(updated); // refresh provider state
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateAdminCode(
    String panelSimNumber,
    String newAdminCode,
  ) async {
    try {
      final result = await _panelRepository.updateAdminCode(
        panelSimNumber,
        newAdminCode,
      );
      return result > 0;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateAddress(String panelSimNumber, String newAddress) async {
    try {
      final result = await _panelRepository.updateAddress(
        panelSimNumber,
        newAddress,
      );
      return result > 0;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateAdminMobileNumber(
    String panelSimNumber,
    String newAdminMobileNumber,
  ) async {
    try {
      final result = await _panelRepository.updateAdminMobileNumber(
        panelSimNumber,
        newAdminMobileNumber,
      );
      return result > 0;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateMobileNumber(
    String panelSimNumber,
    String newMobileNumber,
    int index,
  ) async {
    try {
      final result = await _panelRepository.updateMobileNumber(
        panelSimNumber,
        newMobileNumber,
        index,
      );

      if (result > 0) {
        // Fetch the updated panel from DB
        final updatedPanel = await getPanelByPanelSimNumber(panelSimNumber);
        if (updatedPanel != null) {
          setCurrentPanel(
            updatedPanel,
          ); // updates _currentPanel and notifies listeners
        }
      }

      return result > 0;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deletePanel(String panelSimNumber) async {
    try {
      final result = await _panelRepository.deletePanel(panelSimNumber);
      return result > 0;
    } catch (_) {
      return false;
    }
  }

  void updatePanelList(List<PanelData> panels) {
    sitePanelInfoList = panels.map((panel){
      return SitePanelSimInfo(siteName: panel.siteName, panelSimNumber: panel.panelSimNumber);
    }).toList();

    notifyListeners();
  }
}

enum InsertPanelResult { success, simNumberExists, siteNameExists, failure }
