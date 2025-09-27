import 'package:fire_nex/constants/app_colors.dart';
import 'package:fire_nex/data/database/app_database.dart';
import 'package:fire_nex/presentation/bottom_sheet_dialog/change_admin_mobile_number.dart';
import 'package:fire_nex/presentation/dialog/confirmation_dialog.dart';
import 'package:fire_nex/presentation/dialog/ok_dialog.dart';
import 'package:fire_nex/presentation/screens/edit_panel.dart';
import 'package:fire_nex/presentation/screens/more_settings.dart';
import 'package:fire_nex/presentation/screens/panel_list.dart';
import 'package:fire_nex/presentation/viewModel/panel_view_model.dart';
import 'package:fire_nex/utils/navigation.dart';
import 'package:fire_nex/utils/silent_sms.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/strings.dart';
import '../bottom_sheet_dialog/change_address.dart';
import '../dialog/progress.dart';
import '../widgets/app_bar.dart';
import '../widgets/custom_button.dart';

class PanelDetailsScreen extends StatefulWidget {
  final PanelData panelData;
  const PanelDetailsScreen({super.key, required this.panelData});

  @override
  State<PanelDetailsScreen> createState() => _PanelDetailsScreenState();

  static Widget _infoRow(String label, String value) {
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
}

class _PanelDetailsScreenState extends State<PanelDetailsScreen> {
  @override
  void initState() {
    super.initState();
    final panel = widget.panelData;
    context.read<PanelViewModel>().setCurrentPanel(panel);
  }

  @override
  Widget build(BuildContext context) {
    Future<void> deletePanel() async {
      final result = await showConfirmationDialog(
        context: context,
        message: 'Are you sure you want to delete this panel?',
      );

      if (result == true) {
        final confirmDelete = await showConfirmationDialog(
          context: context,
          message:
              'After deleting the Panel, you will not configure the panel.\nSure?',
        );

        if (confirmDelete == true) {
          final viewModel = context.read<PanelViewModel>();
          final panel = await viewModel.getPanelByPanelSimNumber(
            widget.panelData.panelSimNumber,
          );

          if (panel != null) {
            await _performDeleteActionWithDialog(
              context,
              panel,
              (panelData) => viewModel.deletePanel(panelData.panelSimNumber),
              () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const PanelListPage()),
              ),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Panel Deleted Successfully')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to delete panel')),
            );
          }
        }
      }
    }

    return Scaffold(
      appBar: const CustomAppBar(pageName: 'Panel Details', isFilter: false),
      backgroundColor: Colors.white,
      body: FutureBuilder<PanelData?>(
        future: context.read<PanelViewModel>().getPanelByPanelSimNumber(
          widget.panelData.panelSimNumber,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final panel = snapshot.data ?? widget.panelData;

          // Store into provider
          // WidgetsBinding.instance.addPostFrameCallback((_) {
          //   context.read<PanelViewModel>().setCurrentPanel(panel);
          // });
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 80),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.litePrimary, AppColors.white],
                        ),
                        borderRadius: BorderRadius.circular(4),
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          PanelDetailsScreen._infoRow(
                            "PANEL NAME",
                            panel.panelName,
                          ),
                          PanelDetailsScreen._infoRow(
                            "SITE NAME",
                            panel.siteName,
                          ),
                          PanelDetailsScreen._infoRow(
                            "PANEL SIM NO.",
                            panel.panelSimNumber,
                          ),
                          PanelDetailsScreen._infoRow(
                            "ADMIN MOBILE NO.",
                            panel.adminMobileNumber,
                          ),
                          PanelDetailsScreen._infoRow("ADDRESS", panel.address),
                          const SizedBox(height: 30),
                          CustomButton(
                            onPressed:
                                () => showChangeAddressBottomSheet(
                                  context,
                                  widget.panelData,
                                  context.read<PanelViewModel>(),
                                ),
                            buttonText: "Update Address",
                          ),

                          const SizedBox(height: 10),
                          CustomButton(
                            onPressed:
                                () => showAdminMobileNumberChangeBottomSheet(
                                  context,
                                  panel,
                                  context.read<PanelViewModel>(),
                                ),
                            buttonText: "Update Admin Mobile Number",
                          ),
                          const SizedBox(height: 10),
                          CustomButton(
                            buttonText: "MORE SETTINGS",
                            onPressed:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MoreSettingsScreen(),
                                  ),
                                ),
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
                                  onPressed:
                                      () =>
                                          CustomNavigation.instance.pushReplace(
                                            context: context,
                                            screen: EditPanelScreen(),
                                          ),
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
              Positioned(
                top: 5,
                right: 5,
                child: GestureDetector(
                  onTap: deletePanel,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 5,
                      horizontal: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.colorPrimary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          "DELETE",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 5),
                        Icon(Icons.delete, size: 14, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _performDeleteActionWithDialog(
    BuildContext context,
    PanelData panelData,
    Future<bool> Function(PanelData) deletePanelData,
    VoidCallback backPage,
  ) async {
    final simNumber = panelData.panelSimNumber;
    final panelName = panelData.panelName;
    ProgressDialog.show(context);

    if (fourGComPanels.contains(panelName)) {
      final messages = [
        'SECURICO 1234 ADD ADMIN +91-0000000000 END',
        'SECURICO 1234 REMOVE USER01 END',
        'SECURICO 1234 REMOVE USER02 END',
        'SECURICO 1234 REMOVE USER03 END',
        'SECURICO 1234 REMOVE USER04 END',
        'SECURICO 1234 REMOVE USER05 END',
        'SECURICO 1234 REMOVE USER06 END',
        'SECURICO 1234 REMOVE USER07 END',
        'SECURICO 1234 REMOVE USER08 END',
        'SECURICO 1234 REMOVE USER09 END',
        'SECURICO 1234 REMOVE USER10 END',
        'SECURICO 1234 ADD SIGNATURE ADD SIGNATURE FOR THIS PANEL* END',
      ];

      for (final msg in messages) {
        await sendSms(simNumber, msg);
        await Future.delayed(const Duration(seconds: 3));
      }
    } else if (neuronPanels.contains(panelName)) {
      await sendSms(simNumber, "< 1234 CLEAR TEL >");
      await Future.delayed(const Duration(seconds: 3));
      await sendSms(
        simNumber,
        "< 1234 SIGNATURE ADD SIGNATURE FOR THIS PANEL* >",
      );
    } else {
      showInfoDialog(context: context, message: "Failed to delete the panel.");
    }

    final success = await deletePanelData(panelData);
    ProgressDialog.dismiss(context);

    if (success) {
      showInfoDialog(
        context: context,
        message: "Your panel has been reset with the default configurations.",
      );
      backPage();
    } else {
      showInfoDialog(context: context, message: "Failed to delete the panel.");
    }
  }
}
