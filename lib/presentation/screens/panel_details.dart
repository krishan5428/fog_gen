import 'package:fog_gen_new/constants/app_colors.dart';
import 'package:fog_gen_new/core/responses/socket_repository.dart';
import 'package:fog_gen_new/presentation/bottom_sheet_dialog/change_admin_mobile_number.dart';
import 'package:fog_gen_new/presentation/dialog/confirmation_dialog.dart';
import 'package:fog_gen_new/presentation/dialog/ok_dialog.dart';
import 'package:fog_gen_new/presentation/dialog/progress.dart';
import 'package:fog_gen_new/presentation/dialog/progress_with_message.dart';
import 'package:fog_gen_new/presentation/screens/edit_panel.dart';
import 'package:fog_gen_new/presentation/screens/more_settings/more_settings.dart';
import 'package:fog_gen_new/presentation/screens/panel_list.dart';
import 'package:fog_gen_new/utils/navigation.dart';
import 'package:fog_gen_new/utils/responsive.dart';
import 'package:fog_gen_new/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../constants/strings.dart';
import '../../core/data/pojo/panel_data.dart';
import '../../core/utils/application_class.dart';
import '../../core/utils/packets.dart';
import '../../utils/auth_helper.dart';
import '../bottom_sheet_dialog/change_address.dart';
import '../cubit/fire/fire_cubit.dart';
import '../cubit/intrusion/intru_cubit.dart';
import '../cubit/panel/panel_cubit.dart';
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
  late PanelData panelData;

  @override
  void initState() {
    super.initState();
    getDevice();
    panelData = widget.panelData;
  }

  void getDevice() async {
    device = await SharedPreferenceHelper.getDeviceType();
  }

  @override
  Widget build(BuildContext context) {
    final spacingBwtView = Responsive.spacingBwtView(context);
    final panelNameKey = panelData.panelName.trim().toUpperCase();

    Future<void> deletePanel() async {
      // Step 1: Two-step confirmation
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

      bool ipSuccess = false;
      bool? smsSuccess = false;

      final panel = panelData;

      // ---------------------------------------------------------------------------
      // 1. Attempt delete through IP
      // ---------------------------------------------------------------------------
      if (panel.is_ip_gsm_panel) {
        ProgressDialog.show(context);

        final _ =
            Application()
              ..mIPAddress = panel.ip_address
              ..mPortNumber = int.tryParse(panel.port_no)
              ..mPassword = panel.password
              ..mStaticIPAddress = panel.static_ip_address
              ..mStaticPortNumber = int.tryParse(panel.static_port_no);

        try {
          final socketRepo = SocketRepository();
          final response = await socketRepo.sendPacketSR1(
            Packets.getPacket(isReadPacket: false, args: ["012", "2"]),
          );

          ProgressDialog.dismiss(context);

          if (response == "S*012#0*E") {
            // IP delete success
            SnackBarHelper.showSnackBar(context, 'Panel removed through IP');
            ipSuccess = true;
          } else {
            // IP reached the device but unexpected reply
            final fallback = await showConfirmationDialog(
              context: context,
              title: 'Network Unavailable❗️',
              message:
                  'We couldn’t reach the device through IP.\nWould you like to try deleting the panel by SMS?',
            );

            if (fallback == true) {
              smsSuccess = await _performDeleteActionWithDialog(context, panel);
            }
          }
        } catch (e) {
          ProgressDialog.dismiss(context);

          // Connection error (common case)
          final msg = e.toString().toLowerCase();
          final connectionFailed =
              msg.contains('socket') ||
              msg.contains('failed') ||
              msg.contains('timed out') ||
              msg.contains('refused');

          if (connectionFailed) {
            final fallback = await showConfirmationDialog(
              context: context,
              title: 'Connection Failed',
              message:
                  'Unable to connect via IP.\nWould you like to delete the panel by SMS instead?',
            );

            if (fallback == true) {
              smsSuccess = await _performDeleteActionWithDialog(context, panel);
            }
          } else {
            SnackBarHelper.showSnackBar(context, 'Unexpected error: $e');
          }
        }
      } else {
        // Panel is not IP panel → directly use SMS
        smsSuccess = await _performDeleteActionWithDialog(context, panel);
      }

      // ---------------------------------------------------------------------------
      // 2. Proceed to backend delete only if IP OR SMS succeeded
      // ---------------------------------------------------------------------------
      if (ipSuccess || smsSuccess!) {
        context.read<PanelCubit>().deletePanel(
          userId: panel.userId,
          panelId: panel.pnlId,
        );
      } else {
        await showInfoDialog(
          context: context,
          message: "Failed to delete the panel.",
        );
      }
    }

    Future<void> showAdminMobileNumberChangeSheet() async {
      final updated = await showAdminMobileNumberChangeBottomSheet(
        context,
        panelData,
      );
      if (updated != null) {
        setState(() => panelData = updated);
      }
    }

    Future<void> showAddressChangeSheet() async {
      final updated = await showChangeAddressBottomSheet(context, panelData);
      if (updated != null) {
        setState(() => panelData = updated);
      }
    }

    void afterDelete() async {
      final intruId = await SharedPreferenceHelper.getIntruIdForPanelSimNumber(
        panelData.panelSimNumber,
      );
      final fireId = await SharedPreferenceHelper.getFireIdForPanelSimNumber(
        panelData.panelSimNumber,
      );

      if (intruId != null) {
        context.read<IntruCubit>().deleteIntruWRTIntruId(
          userId: panelData.userId,
          intruId: intruId,
        );
      }
      if (fireId != null) {
        context.read<FireCubit>().deleteFireWRTFireId(
          userId: panelData.userId,
          fireId: fireId,
        );
      }

      await SharedPreferenceHelper.clearIdsForPanelSimNumber(
        panelData.panelSimNumber,
      );
    }

    return MultiBlocListener(
      listeners: [
        BlocListener<PanelCubit, PanelState>(
          listener: (context, state) async {
            if (state is DeletePanelsSuccess) {
              if (dialerPanels.contains(panelNameKey)) {
                afterDelete();
              } else {
                await showInfoDialog(
                  context: context,
                  message: "The panel has been reset.",
                  onOk: () {
                    CustomNavigation.instance.pushReplace(
                      context: context,
                      screen: const PanelListPage(),
                    );
                  },
                );
              }
            } else if (state is DeletePanelsFailure) {
              SnackBarHelper.showSnackBar(
                context,
                'Delete Panel failed: ${state.message}',
              );
            }
          },
        ),

        // Intrusion delete listener
        BlocListener<IntruCubit, IntruState>(
          listener: (context, state) async {
            if (state is DeleteIntruSuccess) {
              await showInfoDialog(
                context: context,
                message: "Panel has been reset.",
                onOk: () {
                  CustomNavigation.instance.pushReplace(
                    context: context,
                    screen: const PanelListPage(),
                  );
                },
              );
            }
          },
        ),

        // Fire delete listener
        BlocListener<FireCubit, FireState>(listener: (context, state) {}),
      ],
      child: Scaffold(
        appBar: const CustomAppBar(pageName: 'Panel Details', isFilter: false),
        backgroundColor: Colors.white,
        body: Stack(
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

                  ///-------------------------------------
                  /// PANEL DETAILS DISPLAY SECTION
                  ///-------------------------------------
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
                                          PanelDetailsScreen._infoRow(
                                            "PANEL NAME",
                                            panelData.panelName,
                                          ),
                                          PanelDetailsScreen._infoRow(
                                            "SITE NAME",
                                            panelData.site.toUpperCase(),
                                          ),
                                          PanelDetailsScreen._infoRow(
                                            "PANEL SIM NO.",
                                            panelData.panelSimNumber,
                                          ),
                                          PanelDetailsScreen._infoRow(
                                            "ADMIN MOBILE NO.",
                                            panelData.adminMobileNumber,
                                          ),
                                          PanelDetailsScreen._infoRow(
                                            "ADDRESS",
                                            panelData.address,
                                          ),
                                        ],
                                      ),
                                    ),

                                    // IP TAB
                                    SingleChildScrollView(
                                      child: Column(
                                        children: [
                                          PanelDetailsScreen._infoRow(
                                            "IP ADDRESS",
                                            panelData.ip_address,
                                          ),
                                          PanelDetailsScreen._infoRow(
                                            "PORT NUMBER",
                                            panelData.port_no,
                                          ),
                                          PanelDetailsScreen._infoRow(
                                            "STATIC IP ADDRESS",
                                            panelData.static_ip_address,
                                          ),
                                          PanelDetailsScreen._infoRow(
                                            "STATIC PORT NUMBER",
                                            panelData.static_port_no,
                                          ),
                                          PanelDetailsScreen._infoRow(
                                            "PASSWORD",
                                            panelData.password,
                                          ),
                                          PanelDetailsScreen._infoRow(
                                            "ADDRESS",
                                            panelData.address,
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
                        const SizedBox(height: 30),

                        CustomButton(
                          onPressed: showAddressChangeSheet,
                          buttonText: "Update Address",
                        ),

                        if (!panelData.is_ip_panel) const SizedBox(height: 10),

                        CustomButton(
                          onPressed: showAdminMobileNumberChangeSheet,
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
                                onPressed:
                                    () =>
                                        CustomNavigation.instance.pop(context),
                                buttonText: "BACK",
                                backgroundColor: AppColors.litePrimary,
                                foregroundColor: AppColors.colorPrimary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: CustomButton(
                                onPressed: () async {
                                  final updatedPanel = await CustomNavigation
                                      .instance
                                      .push(
                                        context: context,
                                        screen: EditPanelScreen(
                                          panelData: panelData,
                                        ),
                                      );

                                  if (updatedPanel != null) {
                                    setState(() {
                                      panelData = updatedPanel;
                                    });

                                    CustomNavigation.instance.popWithResult(
                                      context: context,
                                      result: updatedPanel,
                                    );
                                  }
                                },
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

            // DELETE BUTTON
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
        ),
      ),
    );
  }

  Future<bool?> _performDeleteActionWithDialog(
    BuildContext context,
    PanelData panelData,
  ) async {
    final messages = _buildDeletionMessages(
      panelData.panelName,
      panelData.adminCode,
    );

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

  List<String>? _buildDeletionMessages(String panelName, String adminCode) {
    final key = panelName.trim().toUpperCase();

    if (fourGComPanels.contains(key)) {
      return [
        'SECURICO 1234 ADD ADMIN +91-0000000000 END',
        for (int i = 1; i <= 10; i++)
          'SECURICO 1234 REMOVE USER${i.toString().padLeft(2, '0')} END',
        'SECURICO 1234 ADD SIGNATURE ADD SIGNATURE FOR THIS PANEL* END',
      ];
    }

    if (neuronPanels.contains(key)) {
      return [
        '< 1234 CLEAR TEL >',
        '< 1234 SIGNATURE ADD SIGNATURE FOR THIS PANEL* >',
      ];
    }

    if (dialerPanels.contains(key)) {
      return [
        "$adminCode INTRU CLEAR END",
        "$adminCode FIRE CLEAR END",
        "$adminCode CHANGE CODE ENTER #1234-1234* END",
      ];
    }

    return null;
  }
}
