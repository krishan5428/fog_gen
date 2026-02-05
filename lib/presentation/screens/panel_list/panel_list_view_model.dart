import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/data/pojo/panel_data.dart';
import '../../../utils/auth_helper.dart';
import '../../cubit/mappings/panel_sim_number_cubit.dart';
import '../../cubit/mappings/site_cubit.dart';
import '../../cubit/panel/panel_cubit.dart';

class PanelListViewModel extends ChangeNotifier {
  // State Variables
  String currentFilterType = 'ALL';
  int? userId;
  List<PanelData> _allPanels = [];
  List<PanelData> filteredPanelList = [];
  bool loadFailed = false;

  // -- Initialization Logic --

  Future<void> initialLoad(BuildContext context) async {
    final fetchedId = await SharedPreferenceHelper.getUserId();
    if (fetchedId != null) {
      debugPrint("used userId: $fetchedId");
      userId = fetchedId;
      fetchPanels(context);
    }
  }

  void fetchPanels(BuildContext context) {
    if (userId != null) {

      context.read<PanelCubit>().getPanel(userId: userId.toString());
    }
  }

  // -- State Handlers (Called from BlocListener in UI) --

  void handleLoading() {
    loadFailed = false;
    notifyListeners();
  }

  void handleSuccess(BuildContext context, List<PanelData> panels) {
    _allPanels = panels;
    loadFailed = false;

    // Apply current filter immediately upon fresh data
    _applyFilterInternal();

    // Extract and update dependent Cubits
    final siteNames = _extractSiteNames(panels);
    final simNumbers = _extractPanelSimNumbers(panels);

    context.read<SiteCubit>().setSites(siteNames);
    context.read<PanelSimNumberCubit>().setPanelSimNumbers(simNumbers);

    notifyListeners();
  }

  void handleFailure() {
    loadFailed = true;
    notifyListeners();
  }

  // -- Logic / Helpers --

  void setFilter(String newFilter) {
    currentFilterType = newFilter;
    _applyFilterInternal();
    notifyListeners();
  }

  void _applyFilterInternal() {
    if (currentFilterType == 'ALL') {
      filteredPanelList = List.from(_allPanels);
    } else {
      filteredPanelList = _allPanels.where((panel) {
        return panel.panelType.toUpperCase() == currentFilterType.toUpperCase();
      }).toList();
    }
  }

  List<String> _extractSiteNames(List<PanelData> panels) {
    return panels
        .map((panel) => panel.siteName.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  List<String> _extractPanelSimNumbers(List<PanelData> panels) {
    return panels
        .map((panel) => panel.panelSimNumber.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }
}