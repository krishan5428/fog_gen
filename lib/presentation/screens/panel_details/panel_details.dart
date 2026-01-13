import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../../constants/app_colors.dart';
import '../../../core/data/pojo/panel_data.dart';
import '../../../utils/navigation.dart';
import '../../../utils/responsive.dart';
import '../../../utils/snackbar_helper.dart';
import '../../bottom_sheet_dialog/change_address.dart';
import '../../bottom_sheet_dialog/change_admin_mobile_number.dart';
import '../../cubit/panel/panel_cubit.dart';
import '../../dialog/ok_dialog.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/custom_button.dart';
import '../edit_panel.dart';
import '../more_settings/more_settings.dart';
import '../panel_list/panel_list.dart';
import 'panel_details_view_model.dart';

class PanelDetailsScreen extends StatelessWidget {
  final PanelData panelData;
  const PanelDetailsScreen({super.key, required this.panelData});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PanelDetailsViewModel(panelData: panelData),
      child: const PanelDetailsContent(),
    );
  }
}

class PanelDetailsContent extends StatelessWidget {
  const PanelDetailsContent({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PanelDetailsViewModel>();
    final panelData = vm.panelData;
    final spacingBwtView = Responsive.spacingBwtView(context);

    return BlocListener<PanelCubit, PanelState>(
      listener: (context, state) async {
        // Handle Delete
        if (state is DeletePanelsSuccess) {
          await showInfoDialog(
            context: context,
            message: "The panel has been removed.",
            onOk: () {
              CustomNavigation.instance.pushReplace(
                context: context,
                screen: const PanelListPage(),
              );
            },
          );
        } else if (state is DeletePanelsFailure) {
          SnackBarHelper.showSnackBar(
            context,
            'Delete Panel failed: ${state.message}',
          );
        }

        // Handle Update (Sync UI immediately for offline updates)
        else if (state is UpdatePanelsSuccess) {
          // If the update matches our current panel, refresh the view model
          if (state.panelData.pnlId == vm.panelData.pnlId) {
            vm.updatePanelData(state.panelData);
          }
        }
      },
      child: Scaffold(
        appBar: const CustomAppBar(pageName: 'Panel Details', isFilter: false),
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  // Info Header
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.litePrimary, AppColors.white],
                      ),
                    ),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.info,
                          color: AppColors.colorPrimary,
                          size: 14,
                        ),
                        SizedBox(width: 3),
                        Text(
                          "Getting the details of panel...",
                          style: TextStyle(
                            color: AppColors.colorPrimary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content Area
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      children: [
                        DefaultTabController(
                          length: 2,
                          child: Column(
                            children: [
                              TabBar(
                                labelColor: AppColors.colorPrimary,
                                unselectedLabelColor: Colors.grey,
                                indicatorColor: AppColors.colorPrimary,
                                tabs: const [
                                  Tab(text: "GSM Dialer"),
                                  Tab(text: "IP Comm"),
                                ],
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                height: spacingBwtView * 20,
                                child: TabBarView(
                                  children: [
                                    // GSM TAB
                                    SingleChildScrollView(
                                      child: Column(
                                        children: [
                                          _infoRow("PANEL NAME", panelData.panelName),
                                          _infoRow("SITE NAME", panelData.site.toUpperCase()),
                                          _infoRow("PANEL SIM NO.", panelData.panelSimNumber),
                                          _infoRow("ADMIN MOBILE NO.", panelData.adminMobileNumber),
                                          _infoRow("ADDRESS", panelData.address),
                                        ],
                                      ),
                                    ),
                                    // IP TAB
                                    SingleChildScrollView(
                                      child: Column(
                                        children: [
                                          _infoRow("IP ADDRESS", panelData.ip_address),
                                          _infoRow("PORT NUMBER", panelData.port_no),
                                          _infoRow("STATIC IP ADDRESS", panelData.static_ip_address),
                                          _infoRow("STATIC PORT NUMBER", panelData.static_port_no),
                                          _infoRow("PASSWORD", panelData.password),
                                          _infoRow("ADDRESS", panelData.address),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Actions
                        CustomButton(
                          onPressed: () => _showAddressChangeSheet(context, vm),
                          buttonText: "Update Address",
                        ),

                        if (!panelData.is_ip_panel) const SizedBox(height: 10),

                        CustomButton(
                          onPressed: () => _showAdminMobileNumberChangeSheet(context, vm),
                          buttonText: "Update Admin Mobile Number",
                        ),

                        const SizedBox(height: 10),

                        CustomButton(
                          buttonText: "MORE SETTINGS",
                          onPressed: () {
                            CustomNavigation.instance.push(
                              context: context,
                              screen: MoreSettingsScreen(panelData: panelData),
                            );
                          },
                        ),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                onPressed: () => CustomNavigation.instance.pop(context),
                                buttonText: "BACK",
                                backgroundColor: AppColors.litePrimary,
                                foregroundColor: AppColors.colorPrimary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: CustomButton(
                                onPressed: () => _navigateToEdit(context, vm),
                                buttonText: "EDIT",
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Floating Delete Button
            Positioned(
              top: 5,
              right: 5,
              child: GestureDetector(
                onTap: () => vm.initiateDeletePanel(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.colorPrimary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    children: [
                      Text(
                        "DELETE",
                        style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 5),
                      Icon(Icons.delete, size: 14, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const Text(" : ", style: TextStyle(fontSize: 14)),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.colorPrimary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAdminMobileNumberChangeSheet(BuildContext context, PanelDetailsViewModel vm) async {
    final updated = await showAdminMobileNumberChangeBottomSheet(context, vm.panelData);
    if (updated != null) {
      // The bottom sheet typically calls the Cubit.
      // If it returns the updated object, we update the view.
      vm.updatePanelData(updated);
    }
  }

  Future<void> _showAddressChangeSheet(BuildContext context, PanelDetailsViewModel vm) async {
    final updated = await showChangeAddressBottomSheet(context, vm.panelData);
    if (updated != null) {
      vm.updatePanelData(updated);
    }
  }

  Future<void> _navigateToEdit(BuildContext context, PanelDetailsViewModel vm) async {
    final updatedPanel = await CustomNavigation.instance.push(
      context: context,
      screen: EditPanelScreen(panelData: vm.panelData),
    );

    if (updatedPanel != null) {
      vm.updatePanelData(updatedPanel);
      // We don't need popWithResult here as we are already on the details page.
      // The pop happens in EditScreen. We just update the local view.
    }
  }
}