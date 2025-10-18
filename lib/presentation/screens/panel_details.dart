import 'package:fire_nex/constants/app_colors.dart';
import 'package:fire_nex/core/responses/socket_repository.dart';
import 'package:fire_nex/data/database/app_database.dart';
import 'package:fire_nex/presentation/bottom_sheet_dialog/change_admin_mobile_number.dart';
import 'package:fire_nex/presentation/dialog/confirmation_dialog.dart';
import 'package:fire_nex/presentation/dialog/ok_dialog.dart';
import 'package:fire_nex/presentation/dialog/progress.dart';
import 'package:fire_nex/presentation/dialog/progress_with_message.dart';
import 'package:fire_nex/presentation/screens/edit_panel.dart';
import 'package:fire_nex/presentation/screens/more_settings.dart';
import 'package:fire_nex/presentation/screens/panel_list.dart';
import 'package:fire_nex/presentation/viewModel/panel_view_model.dart';
import 'package:fire_nex/utils/navigation.dart';
import 'package:fire_nex/utils/responsive.dart';
import 'package:fire_nex/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/strings.dart';
import '../../core/utils/application_class.dart';
import '../../core/utils/packets.dart';
import '../../utils/auth_helper.dart';
import '../bottom_sheet_dialog/change_address.dart';
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
  String? device;

  @override
  void initState() {
    super.initState();
    getDevice();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final panel = widget.panelData;
      context.read<PanelViewModel>().setCurrentPanel(panel);
    });
  }

  void getDevice() async {
    device = await SharedPreferenceHelper.getDeviceType();
  }

  @override
  Widget build(BuildContext context) {
    final spacingBwtView = Responsive.spacingBwtView(context);
    Future<void> deletePanel() async {
      final firstConfirm = await showConfirmationDialog(
        context: context,
        message: 'Are you sure you want to delete this panel?',
      );
      if (firstConfirm != true) return;

      final secondConfirm = await showConfirmationDialog(
        context: context,
        message:
            'After deleting the Panel, you will not configure the panel.\nSure?',
      );
      if (secondConfirm != true) return;

      bool? isSend = false;
      bool? deleteConfirm = false;

      final panel = widget.panelData;

      if (panel.isIPPanel || panel.isIPGPRSPanel) {
        ProgressDialog.show(context);
        final _ =
            Application()
              ..mIPAddress = panel.ipAddress
              ..mPortNumber = int.tryParse(panel.port)
              ..mPassword = panel.ipPassword;

        try {
          final socketRepo = SocketRepository();
          final response = await socketRepo.sendPacketSR1(
            Packets.getPacket(isReadPacket: false, args: ["012", "2"]),
          );

          if (response == "S*012#0*E") {
            ProgressDialog.dismiss(context);
            SnackBarHelper.showSnackBar(context, 'Done');
            deleteConfirm = true;
          } else {
            ProgressDialog.dismiss(context);
            if (panel.isIPGPRSPanel) {
              final fallback = await showConfirmationDialog(
                context: context,
                title: 'Network Unavailable❗️',
                message:
                    'We couldn’t reach the device through IP.\n Would you like to try sending the command by SMS?',
              );
              if (fallback == true) {
                isSend = await _performDeleteActionWithDialog(context, panel);
                deleteConfirm = true;
              }
            } else if (panel.isIPPanel) {
              await showInfoDialog(
                context: context,
                message:
                    'Seems like the panel is not connected!\nPlease check the Panel and try again!',
              );
            }
          }
        } catch (e) {
          ProgressDialog.dismiss(context);
          debugPrint("Error sending packet: $e");

          final errorText = e.toString().toLowerCase();
          final isConnectionFailed =
              errorText.contains('socketexception') ||
              errorText.contains('connection refused') ||
              errorText.contains('timed out') ||
              errorText.contains('did not respond') ||
              errorText.contains('failed');

          if (isConnectionFailed) {
            showInfoDialog(
              context: context,
              message:
                  'Unable to connect to the panel.\nPlease check the network connection and try again.',
            );
          } else {
            SnackBarHelper.showSnackBar(context, 'Unexpected error: $e');
          }
        }
      } else {
        isSend = await _performDeleteActionWithDialog(context, panel);
        deleteConfirm = true;
      }

      if (isSend == true && deleteConfirm == true) {
        context.read<PanelViewModel>().deletePanel(panel.panelSimNumber);
        await showInfoDialog(
          context: context,
          message: "The panel has been reset with the default configurations.",
          onOk: () {
            CustomNavigation.instance.pushReplace(
              context: context,
              screen: const PanelListPage(),
            );
          },
        );
      } else {
        await showInfoDialog(
          context: context,
          message: "Failed to delete the panel.",
        );
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

          return Stack(
            children: [
              SingleChildScrollView(
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
                          if (panel.isIPGPRSPanel) ...[
                            DefaultTabController(
                              length: 2,
                              child: Column(
                                children: [
                                  TabBar(
                                    labelColor: AppColors.colorPrimary,
                                    unselectedLabelColor: Colors.grey,
                                    indicatorColor: AppColors.colorPrimary,

                                    labelStyle: const TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                    unselectedLabelStyle: const TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontWeight: FontWeight.w400,
                                      fontSize: 14,
                                    ),

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
                                        /// --- GPRS DETAILS TAB ---
                                        SingleChildScrollView(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              PanelDetailsScreen._infoRow(
                                                "PANEL NAME",
                                                panel.panelName,
                                              ),
                                              PanelDetailsScreen._infoRow(
                                                "SITE NAME",
                                                panel.siteName.toUpperCase(),
                                              ),
                                              PanelDetailsScreen._infoRow(
                                                "PANEL SIM NO.",
                                                panel.panelSimNumber,
                                              ),
                                              PanelDetailsScreen._infoRow(
                                                "ADMIN MOBILE NO.",
                                                panel.adminMobileNumber,
                                              ),
                                              PanelDetailsScreen._infoRow(
                                                "ADDRESS",
                                                panel.address,
                                              ),
                                            ],
                                          ),
                                        ),

                                        /// --- IP DETAILS TAB ---
                                        SingleChildScrollView(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              PanelDetailsScreen._infoRow(
                                                "IP ADDRESS",
                                                panel.ipAddress,
                                              ),
                                              PanelDetailsScreen._infoRow(
                                                "PORT NUMBER",
                                                panel.port,
                                              ),
                                              PanelDetailsScreen._infoRow(
                                                "STATIC IP ADDRESS",
                                                panel.staticIPAddress,
                                              ),
                                              PanelDetailsScreen._infoRow(
                                                "STATIC PORT NUMBER",
                                                panel.staticPort,
                                              ),
                                              PanelDetailsScreen._infoRow(
                                                "PASSWORD",
                                                panel.ipPassword,
                                              ),
                                              PanelDetailsScreen._infoRow(
                                                "ADDRESS",
                                                panel.address,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          /// ✅ Only IP Panel
                          if (panel.isIPPanel && !panel.isIPGPRSPanel) ...[
                            PanelDetailsScreen._infoRow(
                              "PANEL NAME",
                              panel.panelName,
                            ),
                            PanelDetailsScreen._infoRow(
                              "SITE NAME",
                              panel.siteName,
                            ),
                            PanelDetailsScreen._infoRow(
                              "IP ADDRESS",
                              panel.ipAddress,
                            ),
                            PanelDetailsScreen._infoRow(
                              "PORT NUMBER",
                              panel.port,
                            ),
                            PanelDetailsScreen._infoRow(
                              "STATIC IP ADDRESS",
                              panel.staticIPAddress,
                            ),
                            PanelDetailsScreen._infoRow(
                              "STATIC PORT NUMBER",
                              panel.staticPort,
                            ),
                            PanelDetailsScreen._infoRow(
                              "PASSWORD",
                              panel.ipPassword,
                            ),
                            PanelDetailsScreen._infoRow(
                              "ADDRESS",
                              panel.address,
                            ),
                          ],

                          /// ✅ Normal GPRS Panel
                          if (!panel.isIPPanel && !panel.isIPGPRSPanel) ...[
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
                            PanelDetailsScreen._infoRow(
                              "ADDRESS",
                              panel.address,
                            ),
                          ],

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
                          if (!panel.isIPPanel)
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
                                () => CustomNavigation.instance.push(
                                  context: context,
                                  screen: MoreSettingsScreen(panelData: panel),
                                ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: CustomButton(
                                  onPressed:
                                      () => CustomNavigation.instance.pop(
                                        context,
                                      ),
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
                                            screen: const EditPanelScreen(),
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
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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

  Future<bool?> _performDeleteActionWithDialog(
    BuildContext context,
    PanelData panelData,
  ) async {
    final messages = _buildDeletionMessages(panelData.panelName);
    if (messages == null) {
      await showInfoDialog(
        context: context,
        message: "Failed to delete the panel.",
      );
      return false;
    }

    final result = await ProgressDialogWithMessage.show(
      context,
      messages: messages,
      panelSimNumber: panelData.panelSimNumber,
    );
    return result;
  }

  List<String>? _buildDeletionMessages(String panelName) {
    if (fourGComPanels.contains(panelName)) {
      return [
        'SECURICO 1234 ADD ADMIN +91-0000000000 END',
        for (int i = 1; i <= 10; i++)
          'SECURICO 1234 REMOVE USER${i.toString().padLeft(2, '0')} END',
        'SECURICO 1234 ADD SIGNATURE ADD SIGNATURE FOR THIS PANEL* END',
      ];
    } else if (neuronPanels.contains(panelName)) {
      return [
        '< 1234 CLEAR TEL >',
        '< 1234 SIGNATURE ADD SIGNATURE FOR THIS PANEL* >',
      ];
    }
    return null;
  }
}
