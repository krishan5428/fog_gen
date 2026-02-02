import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:fog_gen_new/core/data/pojo/panel_data.dart';
import 'package:fog_gen_new/core/repo/panel_repo.dart';
import 'package:fog_gen_new/utils/auth_helper.dart';

part 'panel_state.dart';

class PanelCubit extends Cubit<PanelState> {
  final PanelRepo panelRepo;

  static const String CACHED_PANELS_KEY = 'cached_panel_list';
  static const String PENDING_ADDS_KEY = 'pending_panels_list';
  static const String PENDING_UPDATES_KEY = 'pending_updates_list';
  static const String PENDING_DELETES_KEY = 'pending_deletes_list';

  PanelCubit(this.panelRepo) : super(PanelInitial());

  // ===========================================================================
  // 1. GET PANELS (OPTIMISTIC: CACHE -> SYNC -> FETCH)
  // ===========================================================================
  void getPanel({required String userId}) async {
    // STEP 1: Optimistic Load (Show Local Data Immediately)
    bool hasCachedData = await _emitCachedData();

    if (!hasCachedData) {
      emit(PanelLoading());
    }

    // STEP 2: Background Sync & Fetch
    try {
      // Sync local actions to server first
      await _syncAllPendingActions(userId);

      // Fetch fresh data from server
      final response = await panelRepo.getPanels(userId);

      if (response.status) {
        // Update local cache with server data
        await _cachePanels(response.panelsData);
        // Re-emit to merge server data with any remaining pending adds
        await _emitCachedData();
      } else {
        if (!hasCachedData) _loadFromCacheFallback();
      }
    } catch (e) {
      // Offline: Stay on cached data
      if (!hasCachedData) _loadFromCacheFallback();
    }
  }

  /// Helper to load and emit data from cache + pending.
  /// Standardized to always emit a state so the UI unblocks.
  Future<bool> _emitCachedData() async {
    try {
      // Load Server Cache
      final cachedString = await SharedPreferenceHelper.getString(
        CACHED_PANELS_KEY,
      );
      List<PanelData> cachedList = [];
      if (cachedString != null && cachedString.isNotEmpty) {
        final List<dynamic> jsonList = json.decode(cachedString);
        cachedList = jsonList.map((e) => PanelData.fromJson(e)).toList();
      }

      // Load Pending Adds
      final pendingAdds = await _getPendingList(PENDING_ADDS_KEY);

      // Combine: Pending Adds (Top) + Cached Data
      final combined = [...pendingAdds, ...cachedList];

      // ALWAYS emit success, even if 'combined' is empty.
      emit(GetPanelsSuccess(panelsData: combined));
      return true;
    } catch (e) {
      if (kDebugMode) {
        print("Cache load error: $e");
      }
    }
    return false;
  }

  void _loadFromCacheFallback() async {
    final success = await _emitCachedData();
    if (!success) {
      emit(GetPanelsFailure(message: 'No internet and no data available.'));
    }
  }

  // ===========================================================================
  // 2. BATCH UPDATE
  // ===========================================================================
  void updatePanelDataList({
    required String userId,
    required int panelId,
    required List<String> keys,
    required List<dynamic> values,
  }) async {
    emit(PanelLoading());
    try {
      final response = await panelRepo.updatePanelDataInList(
        userId,
        panelId,
        keys,
        values,
      );
      if (response.status && response.panelData != null) {
        emit(
          UpdatePanelsSuccess(
            msg: response.msg,
            panelData: response.panelData!,
          ),
        );
        getPanel(userId: userId);
      } else {
        emit(UpdatePanelsFailure(message: response.msg));
      }
    } catch (e) {
      try {
        Map<String, dynamic> changes = {};
        for (int i = 0; i < keys.length; i++) {
          changes[keys[i]] = values[i];
        }

        final updated = await _updateLocalPanel(panelId, changes);

        if (updated != null) {
          if (panelId > 0) {
            for (int i = 0; i < keys.length; i++) {
              await _addPendingAction(PENDING_UPDATES_KEY, {
                'id': panelId,
                'key': keys[i],
                'value': values[i],
              });
            }
          }
          emit(UpdatePanelsSuccess(msg: "Updated Offline", panelData: updated));
          getPanel(userId: userId);
        } else {
          emit(
            UpdatePanelsFailure(
              message: "Failed to update offline (Panel not found)",
            ),
          );
        }
      } catch (innerE) {
        emit(UpdatePanelsFailure(message: "Offline update failed: $innerE"));
      }
    }
  }

  // ===========================================================================
  // 3. ADD PANEL
  // ===========================================================================
  void addPanel({
    required String userId,
    required String panelType,
    required String panelName,
    required String site,
    required String panelSimNumber,
    required String adminCode,
    required String adminMobileNumber,
    required String mobileNumberSubId,
    required String mobileNumber1,
    required String mobileNumber2,
    required String mobileNumber3,
    required String mobileNumber4,
    required String mobileNumber5,
    required String mobileNumber6,
    required String mobileNumber7,
    required String mobileNumber8,
    required String mobileNumber9,
    required String mobileNumber10,
    required String address,
    required String cOn,
    required bool is_ip_gsm_panel,
    required bool is_ip_panel,
    required String ip_address,
    required String port_no,
    required String static_ip_address,
    required String static_port_no,
    required String password,
    required String panel_acc_no,
    required String mac_id,
    required String version,
  }) async {
    emit(PanelLoading());
    try {
      final response = await panelRepo.addPanel(
        userId: userId,
        panelType: panelType,
        panelName: panelName,
        site: site,
        panelSimNumber: panelSimNumber,
        adminCode: adminCode,
        adminMobileNumber: adminMobileNumber,
        mobileNumberSubId: mobileNumberSubId,
        mobileNumber1: mobileNumber1,
        mobileNumber2: mobileNumber2,
        mobileNumber3: mobileNumber3,
        mobileNumber4: mobileNumber4,
        mobileNumber5: mobileNumber5,
        mobileNumber6: mobileNumber6,
        mobileNumber7: mobileNumber7,
        mobileNumber8: mobileNumber8,
        mobileNumber9: mobileNumber9,
        mobileNumber10: mobileNumber10,
        address: address,
        cOn: cOn,
        ip_address: ip_address,
        port_no: port_no,
        static_ip_address: static_ip_address,
        static_port_no: static_port_no,
        password: password,
        is_ip_panel: is_ip_panel,
        is_ip_gsm_panel: is_ip_gsm_panel,
        panel_acc_no: panel_acc_no,
        mac_id: mac_id,
        version: version,
      );

      if (response.status) {
        emit(AddPanelSuccess(message: response.msg));
        getPanel(userId: userId);
      } else {
        emit(AddPanelFailure(message: response.msg));
      }
    } catch (e) {
      // Offline Save: Standardize local object keys
      final tempPanel = PanelData(
        pnlId: -DateTime.now().millisecondsSinceEpoch,
        usrId: userId,
        appType: 'FogShield',
        panelType: panelType,
        panelName: panelName,
        siteName: site,
        siteAddress: address,
        panelSimNumber: panelSimNumber,
        adminCode: adminCode,
        adminMobileNumber: adminMobileNumber,
        mobileNumberSubId: mobileNumberSubId,
        mobileNumber1: mobileNumber1,
        mobileNumber2: mobileNumber2,
        mobileNumber3: mobileNumber3,
        mobileNumber4: mobileNumber4,
        mobileNumber5: mobileNumber5,
        mobileNumber6: mobileNumber6,
        mobileNumber7: mobileNumber7,
        mobileNumber8: mobileNumber8,
        mobileNumber9: mobileNumber9,
        mobileNumber10: mobileNumber10,
        cOn: cOn,
        ipAdd: ip_address,
        portNo: port_no,
        staticIp: static_ip_address,
        staticPort: static_port_no,
        pass: password,
        isIpPanel: is_ip_panel,
        isIpGsmPanel: is_ip_gsm_panel,
        pnlAccNo: panel_acc_no,
        pnlMac: mac_id,
        pnlVer: version,
        pnlLineNo: '',
        pnlRcvrNo: '',
        usr1: '',
        usr2: '',
        usr3: '',
        usr4: '',
      );

      await _addToPendingList(PENDING_ADDS_KEY, tempPanel);
      emit(AddPanelSuccess(message: "Saved Offline."));
      getPanel(userId: userId);
    }
  }

  // ===========================================================================
  // 4. DELETE PANEL
  // ===========================================================================
  void deletePanel({required String userId, required int panelId}) async {
    emit(PanelLoading());
    try {
      final response = await panelRepo.deletePanel(userId, panelId);
      if (response.status) {
        emit(DeletePanelsSuccess(msg: 'Panel Deleted Successfully'));
        getPanel(userId: userId);
      } else {
        emit(DeletePanelsFailure(message: 'Error deleting panel'));
      }
    } catch (e) {
      if (panelId < 0) {
        await _removeFromPendingList(PENDING_ADDS_KEY, panelId);
      } else {
        await _removeFromCache(panelId);
        await _addPendingAction(PENDING_DELETES_KEY, {'id': panelId});
      }
      emit(DeletePanelsSuccess(msg: 'Deleted Offline'));
      getPanel(userId: userId);
    }
  }

  // ===========================================================================
  // 5. GENERAL UPDATE
  // ===========================================================================
  void updatePanelData({
    required String userId,
    required int panelId,
    required String key,
    required String value,
  }) async {
    emit(PanelLoading());
    try {
      final response = await panelRepo.updatePanelData(
        userId,
        panelId,
        key,
        value,
      );
      if (response.status && response.panelData != null) {
        emit(
          UpdatePanelsSuccess(
            msg: response.msg,
            panelData: response.panelData!,
          ),
        );
        getPanel(userId: userId);
      } else if (!response.status) {
        emit(UpdatePanelsFailure(message: response.msg));
      }
    } catch (e) {
      final updated = await _updateLocalPanel(panelId, {key: value});
      if (updated != null) {
        if (panelId > 0) {
          await _addPendingAction(PENDING_UPDATES_KEY, {
            'id': panelId,
            'key': key,
            'value': value,
          });
        }
        emit(UpdatePanelsSuccess(msg: "Updated Offline", panelData: updated));
        getPanel(userId: userId);
      } else {
        emit(UpdatePanelsFailure(message: "Failed to update offline"));
      }
    }
  }

  // Specific Wrappers using Standard Server Keys
  void updateSiteName({
    required String userId,
    required int panelId,
    required String siteName,
  }) {
    updatePanelData(
      userId: userId,
      panelId: panelId,
      key: 'site_name',
      value: siteName,
    );
  }

  void updateAddress({
    required String userId,
    required int panelId,
    required String address,
  }) {
    updatePanelData(
      userId: userId,
      panelId: panelId,
      key: 'site_address',
      value: address,
    );
  }

  void updatePanelSimNumber({
    required String userId,
    required int panelId,
    required String panelSimNumber,
  }) {
    updatePanelData(
      userId: userId,
      panelId: panelId,
      key: 'panel_sim_number',
      value: panelSimNumber,
    );
  }

  void updateAdminMobileNumber({
    required String userId,
    required int panelId,
    required String adminMobileNumber,
  }) async {
    updatePanelData(
      userId: userId,
      panelId: panelId,
      key: 'admin_mobile_number',
      value: adminMobileNumber,
    );
  }

  void updateAdminCode({
    required String userId,
    required int panelId,
    required int adminCode,
  }) async {
    emit(PanelLoading());
    try {
      final response = await panelRepo.updateAdminCode(
        userId,
        panelId,
        adminCode,
      );
      if (response.status) {
        getPanel(userId: userId);
      } else {
        emit(UpdatePanelsFailure(message: 'Error updating Admin Code'));
      }
    } catch (e) {
      final updated = await _updateLocalPanel(panelId, {
        'admin_code': adminCode.toString(),
      });
      if (updated != null) {
        if (panelId > 0) {
          await _addPendingAction(PENDING_UPDATES_KEY, {
            'id': panelId,
            'endpoint': 'updateAdminCode',
            'adminCode': adminCode,
          });
        }
        emit(UpdatePanelsSuccess(msg: "Updated Offline", panelData: updated));
        getPanel(userId: userId);
      }
    }
  }

  void updateSolitareMobileNumber({
    required String userId,
    required int panelId,
    required String mobileNumber,
    required String index,
  }) async {
    String key = 'mobile_number$index';
    updatePanelData(
      userId: userId,
      panelId: panelId,
      key: key,
      value: mobileNumber,
    );
  }

  // ===========================================================================
  // 6. SYNC & STORAGE
  // ===========================================================================
  Future<void> _syncAllPendingActions(String userId) async {
    // 1. Sync Adds
    final adds = await _getPendingList(PENDING_ADDS_KEY);
    List<PanelData> remAdds = [];
    for (var p in adds) {
      try {
        final res = await panelRepo.addPanel(
          userId: userId,
          panelType: p.panelType,
          panelName: p.panelName,
          site: p.siteName,
          panelSimNumber: p.panelSimNumber,
          adminCode: p.adminCode,
          adminMobileNumber: p.adminMobileNumber,
          mobileNumberSubId: p.mobileNumberSubId,
          mobileNumber1: p.mobileNumber1,
          mobileNumber2: p.mobileNumber2,
          mobileNumber3: p.mobileNumber3,
          mobileNumber4: p.mobileNumber4,
          mobileNumber5: p.mobileNumber5,
          mobileNumber6: p.mobileNumber6,
          mobileNumber7: p.mobileNumber7,
          mobileNumber8: p.mobileNumber8,
          mobileNumber9: p.mobileNumber9,
          mobileNumber10: p.mobileNumber10,
          address: p.siteAddress,
          cOn: p.cOn,
          ip_address: p.ipAdd,
          port_no: p.portNo,
          static_ip_address: p.staticIp,
          static_port_no: p.staticPort,
          password: p.pass,
          is_ip_panel: p.isIpPanel,
          is_ip_gsm_panel: p.isIpGsmPanel,
          panel_acc_no: p.pnlAccNo,
          mac_id: p.pnlMac,
          version: p.pnlVer
        );
        if (!res.status) remAdds.add(p);
      } catch (e) {
        remAdds.add(p);
      }
    }
    await _savePendingList(PENDING_ADDS_KEY, remAdds);

    // 2. Sync Deletes
    final dels = await _getPendingActions(PENDING_DELETES_KEY);
    List<Map<String, dynamic>> remDels = [];
    for (var d in dels) {
      try {
        await panelRepo.deletePanel(userId, d['id']);
      } catch (e) {
        remDels.add(d);
      }
    }
    await _savePendingActions(PENDING_DELETES_KEY, remDels);

    // 3. Sync Updates
    final upds = await _getPendingActions(PENDING_UPDATES_KEY);
    List<Map<String, dynamic>> remUpds = [];
    for (var u in upds) {
      try {
        if (u.containsKey('endpoint') && u['endpoint'] == 'updateAdminCode') {
          await panelRepo.updateAdminCode(userId, u['id'], u['adminCode']);
        } else {
          await panelRepo.updatePanelData(
            userId,
            u['id'],
            u['key'],
            u['value'],
          );
        }
      } catch (e) {
        remUpds.add(u);
      }
    }
    await _savePendingActions(PENDING_UPDATES_KEY, remUpds);
  }

  // --- Local Database Helpers ---
  Future<PanelData?> _updateLocalPanel(
    int panelId,
    Map<String, dynamic> changes,
  ) async {
    // Check Pending Adds
    List<PanelData> pending = await _getPendingList(PENDING_ADDS_KEY);
    int idx = pending.indexWhere((p) => p.pnlId == panelId);
    if (idx != -1) {
      // Logic for editing a panel that hasn't hit the server yet
      return pending[idx];
    }

    // Check Cache
    final str = await SharedPreferenceHelper.getString(CACHED_PANELS_KEY);
    if (str != null) {
      List<dynamic> list = json.decode(str);
      List<PanelData> panels = list.map((e) => PanelData.fromJson(e)).toList();
      int cIdx = panels.indexWhere((p) => p.pnlId == panelId);
      if (cIdx != -1) {
        Map<String, dynamic> target = list[cIdx];
        changes.forEach((k, v) => target[k] = v);
        list[cIdx] = target;
        await SharedPreferenceHelper.setString(
          CACHED_PANELS_KEY,
          json.encode(list),
        );
        return PanelData.fromJson(target);
      }
    }
    return null;
  }

  Future<void> _removeFromCache(int panelId) async {
    final str = await SharedPreferenceHelper.getString(CACHED_PANELS_KEY);
    if (str != null) {
      List<dynamic> list = json.decode(str);
      list.removeWhere((i) => i['pnl_id'] == panelId);
      await SharedPreferenceHelper.setString(
        CACHED_PANELS_KEY,
        json.encode(list),
      );
    }
  }

  Future<void> _cachePanels(List<PanelData> panels) async {
    await SharedPreferenceHelper.setString(
      CACHED_PANELS_KEY,
      json.encode(panels.map((e) => e.toJson()).toList()),
    );
  }

  Future<List<PanelData>> _getPendingList(String key) async {
    final str = await SharedPreferenceHelper.getString(key);
    return (str != null && str.isNotEmpty)
        ? (json.decode(str) as List).map((e) => PanelData.fromJson(e)).toList()
        : [];
  }

  Future<void> _addToPendingList(String key, PanelData item) async {
    List<PanelData> list = await _getPendingList(key);
    list.insert(0, item);
    await _savePendingList(key, list);
  }

  Future<void> _savePendingList(String key, List<PanelData> list) async {
    await SharedPreferenceHelper.setString(
      key,
      json.encode(list.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _removeFromPendingList(String key, int id) async {
    List<PanelData> list = await _getPendingList(key);
    list.removeWhere((p) => p.pnlId == id);
    await _savePendingList(key, list);
  }

  Future<List<Map<String, dynamic>>> _getPendingActions(String key) async {
    final str = await SharedPreferenceHelper.getString(key);
    return (str != null && str.isNotEmpty)
        ? List<Map<String, dynamic>>.from(json.decode(str))
        : [];
  }

  Future<void> _addPendingAction(String key, Map<String, dynamic> item) async {
    List<Map<String, dynamic>> list = await _getPendingActions(key);
    list.add(item);
    await _savePendingActions(key, list);
  }

  Future<void> _savePendingActions(
    String key,
    List<Map<String, dynamic>> list,
  ) async {
    await SharedPreferenceHelper.setString(key, json.encode(list));
  }
}
