import 'package:fire_nex/constants/app_colors.dart';
import 'package:fire_nex/data/database/app_database.dart';
import 'package:fire_nex/presentation/dialog/panel_filter.dart';
import 'package:fire_nex/presentation/dialog/panel_type.dart';
import 'package:fire_nex/presentation/dialog/progress.dart';
import 'package:fire_nex/presentation/viewModel/panel_view_model.dart';
import 'package:fire_nex/presentation/widgets/custom_button.dart';
import 'package:fire_nex/presentation/widgets/vertical_gap.dart';
import 'package:fire_nex/utils/auth_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/app_bar.dart';
import '../widgets/app_drawer.dart';
import '../widgets/panel_item.dart';

class PanelListPage extends StatefulWidget {
  const PanelListPage({super.key});

  @override
  State<PanelListPage> createState() => _PanelListState();
}

class _PanelListState extends State<PanelListPage> {
  List<PanelData> panelList = [];
  List<PanelData> filteredPanelList = [];
  bool _isInitialized = false;
  String currentFilterType = 'ALL';
  int? userId;
  List<Map<String, String>> siteAndSiteList = [];
  // List<SitePanelSimInfo> sitePanelInfoList = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        fetchPanel();
      });
    }
  }

  void fetchPanel() async {
    if (mounted) ProgressDialog.show(context, message: "Fetching panels");

    try {
      final panelVM = context.read<PanelViewModel>();
      userId = await SharedPreferenceHelper.getUserId();

      List<PanelData> panels = await panelVM.getAllPanelWithUserId(userId!);

      if (userId == 999999) {
        panels.insert(
          0,
          PanelData(
            id: userId!,
            panelSimNumber: "9289102616",
            panelType: "ALARM PANEL",
            panelName: "Demo Panel",
            siteName: "Demo Site",
            address: "Panel Address",
            adminCode: "1234",
            adminMobileNumber: "9899446573",
            userId: 999999,
            mobileNumber1: "8888888888",
            mobileNumber2: "0000000000",
            mobileNumber3: "0000000000",
            mobileNumber4: "0000000000",
            mobileNumber5: "0000000000",
            mobileNumber6: "0000000000",
            mobileNumber7: "0000000000",
            mobileNumber8: "0000000000",
            mobileNumber9: "0000000000",
            mobileNumber10: "0000000000",
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        panelList = panels;
        filteredPanelList = panels;
      });

      // 🔹 Update ViewModel here
      panelVM.updatePanelList(panels);

      // 🔹 Log for verification
      debugPrint("SITE AND PANEL SIM LIST UPDATED IN VIEWMODEL:");
      for (var info in panelVM.sitePanelInfoList) {
        debugPrint("- Site: ${info.siteName}, SIM: ${info.panelSimNumber}");
      }
    } catch (e) {
      debugPrint("Error fetching panels: $e");
    }
    if (mounted) {
      Future.delayed(Duration(milliseconds: 300), () {
        if (mounted) {
          ProgressDialog.dismiss(context);
        }
      });
    }
  }

  void fetchPanelWithFilter(String panelType) async {
    if (mounted) {
      ProgressDialog.show(context, message: "Fetching panels");
    }

    try {
      final panelViewModel = context.read<PanelViewModel>();
      userId = await SharedPreferenceHelper.getUserId();
      debugPrint("Fetched userId: $userId");

      List<PanelData> panels;
      if (panelType == 'ALL') {
        panels = await panelViewModel.getAllPanelWithUserId(userId!);
      } else {
        panels = await panelViewModel.getFilteredPanels(userId!, panelType);
      }

      // ✅ Only inject dummy panel after fetching the real ones
      if (userId == 999999) {
        panels.insert(
          0,
          PanelData(
            id: userId!,
            panelSimNumber: "9598641084",
            panelType: "ALARM PANEL",
            panelName: "Demo Panel",
            siteName: "Demo Site",
            address: "123 Demo Street",
            adminCode: "1234",
            adminMobileNumber: "9899446573",
            userId: 999999,
            mobileNumber1: "8888888888",
            mobileNumber2: "0000000000",
            mobileNumber3: "0000000000",
            mobileNumber4: "0000000000",
            mobileNumber5: "0000000000",
            mobileNumber6: "0000000000",
            mobileNumber7: "0000000000",
            mobileNumber8: "0000000000",
            mobileNumber9: "0000000000",
            mobileNumber10: "0000000000",
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        panelList = panels;
        filteredPanelList = panels;
      });
    } catch (e) {
      debugPrint("Error fetching the panels: $e");
    } finally {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            ProgressDialog.dismiss(context);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      drawer: const AppDrawer(),
      appBar: CustomAppBar(
        pageName: 'Panel List',
        isFilter: true,
        isDash: true,
        onFilterTap: _showPanelFilterDialog,
      ),
      body:
          panelList.isEmpty
              ? Center(
                child: SizedBox(
                  width: 300,
                  child: CustomButton(
                    buttonText: 'ADD NEW PANEL',
                    icon: Icons.add,
                    onPressed: _showPanelTypeDialog,
                  ),
                ),
              )
              : ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
                children: [
                  ...filteredPanelList.map(
                        (panel) => Consumer<PanelViewModel>(
                      builder: (context, viewModel, child) {
                        // check if currentPanel has the same sim number and use updated data
                        final updatedPanel = (viewModel.currentPanel != null &&
                            viewModel.currentPanel!.panelSimNumber == panel.panelSimNumber)
                            ? viewModel.currentPanel!
                            : panel;

                        return PanelCard(panelData: updatedPanel);
                      },
                    ),
                  ),
                  VerticalSpace(height: 20),
                  Center(
                    child: SizedBox(
                      width: 300,
                      child: CustomButton(
                        buttonText: 'ADD NEW PANEL',
                        icon: Icons.add,
                        onPressed: _showPanelTypeDialog,
                      ),
                    ),
                  ),
                  VerticalSpace(height: 50),
                ],
              ),
    );
  }

  void _showPanelTypeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const PanelTypeDialog();
      },
    );
  }

  void _showPanelFilterDialog() async {
    final selectedFilter = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return PanelFilterDialog(initialFilter: currentFilterType);
      },
    );

    if (selectedFilter != null) {
      currentFilterType = selectedFilter;
      fetchPanelWithFilter(selectedFilter);
    }
  }
}
