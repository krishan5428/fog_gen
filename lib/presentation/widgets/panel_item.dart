import 'package:flutter/material.dart';
import 'package:fog_gen_new/core/responses/socket_repository.dart';
import 'package:fog_gen_new/core/utils/packets.dart';
import 'package:fog_gen_new/presentation/dialog/confirmation_dialog.dart';
import 'package:fog_gen_new/presentation/dialog/ok_dialog.dart';
import 'package:fog_gen_new/presentation/dialog/progress.dart';
import 'package:fog_gen_new/presentation/dialog/progress_with_message.dart';
import 'package:fog_gen_new/presentation/screens/main/main_screen.dart';
import 'package:fog_gen_new/utils/snackbar_helper.dart';

import '../../constants/app_colors.dart';
import '../../core/data/pojo/panel_data.dart';
import '../../core/utils/application_class.dart';
import '../../utils/navigation.dart';
import '../../utils/responsive.dart';
import '../screens/panel_details/panel_details.dart';
import 'custom_button.dart';

class PanelCard extends StatelessWidget {
  final PanelData panelData;
  const PanelCard({super.key, required this.panelData});

  bool get isGsmDialerPanel {
    final name = panelData.panelName.trim().toUpperCase();
    return name == 'GALAXY GX GSMD DIALER' ||
        name == 'SEC GSMD 4G' ||
        name == 'SEC GSMD 4GC';
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = Responsive.fontSize(context);
    final spacing = Responsive.spacingBwtView(context);
    final smallTextSize = Responsive.smallTextSize(context);
    debugPrint("PanelCard → Loaded panel: ${panelData.panelName}");

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: AppColors.colorAccent),
      ),
      elevation: 2,
      color: AppColors.white,
      child: Padding(
        padding: EdgeInsets.all(spacing),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      panelData.siteName.toUpperCase(),
                      style: TextStyle(
                        color: AppColors.colorAccent,
                        fontSize: fontSize * 1.2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      panelData.panelName,
                      style: TextStyle(
                        color: AppColors.colorPrimary,
                        fontSize: smallTextSize * 0.9,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () async {
                    CustomNavigation.instance.push(
                      context: context,
                      screen: PanelDetailsScreen(panelData: panelData),
                    );

                    // final updatedPanel = await CustomNavigation.instance.push(
                    //   context: context,
                    //   screen: PanelDetailsScreen(panelData: panelData),
                    // );
                    //
                    // // FIX: Use ViewModel instead of finding Ancestor State
                    // if (updatedPanel != null && context.mounted) {
                    //   try {
                    //     context.read<PanelListViewModel>().updateSinglePanel(
                    //       updatedPanel,
                    //     );
                    //   } catch (e) {
                    //     debugPrint(
                    //       "PanelListViewModel not found in context (PanelCard might be used outside PanelList): $e",
                    //     );
                    //   }
                    // }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.colorPrimary,
                    side: const BorderSide(
                      width: 1,
                      color: AppColors.colorPrimary,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'DETAILS',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: smallTextSize * 0.9,
                          color: AppColors.colorPrimary,
                        ),
                      ),
                      Icon(
                        Icons.arrow_right,
                        size: fontSize,
                        color: AppColors.colorPrimary,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: spacing),

            _buildNormalPanelButtons(context, smallTextSize * 0.9, spacing),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // NORMAL PANELS → Alarm Reset, Evacuate, Sounder Off
  // ---------------------------------------------------------------------------

  Widget _buildNormalPanelButtons(
    BuildContext context,
    double textSize,
    double spacing,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CustomButton(
                buttonText: 'ALARM RESET',
                onPressed: () => onAlarmReset(context),
                buttonTextSize: textSize,
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: CustomButton(
                buttonText: 'TRIGGER FOGGER',
                onPressed: () => onEvacuate(context),
                buttonTextSize: textSize,
              ),
            ),
          ],
        ),
        SizedBox(height: spacing / 2),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                buttonText: 'SOUNDER OFF',
                onPressed: () => onSounderOff(context),
                buttonTextSize: textSize,
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: CustomButton(
                buttonText: 'Extended View',
                onPressed: () => onExtendedButtonClicked(context, panelData),
                buttonTextSize: textSize,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void onAlarmReset(BuildContext context) {
    _sendOutputCommand(
      context: context,
      outputNumber: 3,
      title: "Confirm Alarm Reset",
      confirmationMessage:
          "Are you sure you want to SEND SMS to reset the alarm?",
    );
  }

  void onExtendedButtonClicked(BuildContext context, PanelData panelData) {
    CustomNavigation.instance.pushReplace(
      context: context,
      screen: MainScreen(panelData: panelData),
    );
  }

  void onEvacuate(BuildContext context) {
    _sendOutputCommand(
      context: context,
      outputNumber: 2,
      title: "Confirm Evacuation",
      confirmationMessage:
          "Are you sure you want to SEND SMS to trigger evacuation?",
    );
  }

  void onSounderOff(BuildContext context) {
    _sendOutputCommand(
      context: context,
      outputNumber: 4,
      title: "Confirm Sounder Off",
      confirmationMessage:
          "Do you really want to SEND SMS to turn off the sounder?",
    );
  }

  Future<void> _sendOutputCommand({
    required BuildContext context,
    required int outputNumber,
    required String title,
    required String confirmationMessage,
  }) async {
    final socketRepository = SocketRepository();
    final confirm = await showConfirmationDialog(
      context: context,
      title: title,
      message: confirmationMessage,
    );

    if (confirm != true) {
      SnackBarHelper.showSnackBar(context, 'Cancelled!');
      return;
    }

    if (panelData.isIpPanel || panelData.isIpGsmPanel) {
      ProgressDialog.show(context);

      final _ = Application()
        ..mIPAddress = panelData.ipAdd
        ..mPortNumber = int.tryParse(panelData.portNo)
        ..mPassword = panelData.pass;

      final lastOutput = outputNumber - 1;

      try {
        final response = await socketRepository.sendPacketSR1(
          Packets.getPacket(
            isReadPacket: false,
            args: ["007", lastOutput.toString().padLeft(3, '0'), "3"],
          ),
        );

        ProgressDialog.dismiss(context);

        if (response == "S*007#0*E") {
          SnackBarHelper.showSnackBar(context, 'Successful');
        } else {
          await _handleFailedIPCommand(context, outputNumber);
        }
      } catch (e) {
        ProgressDialog.dismiss(context);
        final errorText = e.toString().toLowerCase();
        final isConnectionFailed =
            errorText.contains('socketexception') ||
            errorText.contains('connection refused') ||
            errorText.contains('timed out') ||
            errorText.contains('did not respond') ||
            errorText.contains('failed');

        if (isConnectionFailed) {
          if (panelData.isIpGsmPanel) {
            final confirm = await showConfirmationDialog(
              context: context,
              title: 'Network Unavailable❗️',
              message:
                  'We couldn’t reach the device through IP.\n Would you like to try sending the command by SMS?',
            );
            if (confirm == true) {
              _sendCommandSMS(outputNumber, context);
            }
          } else {
            showInfoDialog(
              context: context,
              message:
                  'Unable to connect to the panel.\nPlease check the network connection and try again.',
            );
          }
        } else {
          SnackBarHelper.showSnackBar(context, 'Unexpected error: $e');
        }
      }
    } else {
      _sendCommandSMS(outputNumber, context);
    }
  }

  Future<void> _handleFailedIPCommand(
    BuildContext context,
    int outputNumber,
  ) async {
    if (panelData.isIpGsmPanel) {
      final confirm = await showConfirmationDialog(
        context: context,
        message:
            'Unable to send IP Command!\nDo you want to send the SMS command instead?',
      );
      if (confirm == true) {
        _sendCommandSMS(outputNumber, context);
      }
    } else {
      showInfoDialog(
        context: context,
        message:
            'Panel seems to be offline.\nPlease check the connection and try again.',
      );
    }
  }

  void _sendCommandSMS(int outputNumber, BuildContext context) async {
    final sim = panelData.panelSimNumber;
    final onMessage = "< 1234 OUTPUT $outputNumber ON >";
    final offMessage = "< 1234 OUTPUT $outputNumber OFF >";

    final messages = [onMessage, offMessage];

    final isSend = await ProgressDialogWithMessage.show(
      context,
      messages: messages,
      panelSimNumber: sim,
    );

    if (isSend == true) {
      SnackBarHelper.showSnackBar(context, 'Done');
    } else {
      SnackBarHelper.showSnackBar(context, 'Cancelled!');
    }
  }

  void onArmButtonPressed(BuildContext context) async {
    final String simNumber = panelData.panelSimNumber;
    final String adminCode = panelData.adminCode;
    final String panelName = panelData.panelName.trim().toUpperCase();

    String message = panelName == "MULTICOM 4G DIALER"
        ? "< $adminCode ARM >"
        : "$adminCode FULL ARM END";

    final isSend = await ProgressDialogWithMessage.show(
      context,
      messages: [message],
      panelSimNumber: simNumber,
    );

    if (isSend == true) {
      SnackBarHelper.showSnackBar(context, 'Send!');
    } else {
      SnackBarHelper.showSnackBar(context, 'Cancelled');
    }
  }

  void onDisarmButtonPressed(BuildContext context) async {
    final String simNumber = panelData.panelSimNumber;
    final String adminCode = panelData.adminCode;
    final String panelName = panelData.panelName.trim().toUpperCase();

    String message = panelName == "MULTICOM 4G DIALER"
        ? "< $adminCode DISARM >"
        : "$adminCode DISARM END";

    final isSend = await ProgressDialogWithMessage.show(
      context,
      messages: [message],
      panelSimNumber: simNumber,
    );

    if (isSend == true) {
      SnackBarHelper.showSnackBar(context, 'Send!');
    } else {
      SnackBarHelper.showSnackBar(context, 'Cancelled');
    }
  }

  void onAlarmResetButtonPressed(BuildContext context) async {
    final String simNumber = panelData.panelSimNumber;
    final String adminCode = panelData.adminCode;
    final String panelName = panelData.panelName.trim().toUpperCase();

    String message = panelName == "MULTICOM 4G DIALER"
        ? "< $adminCode ALARM RESET >"
        : "$adminCode ALARM RESET END";

    final isSend = await ProgressDialogWithMessage.show(
      context,
      messages: [message],
      panelSimNumber: simNumber,
    );

    if (isSend == true) {
      SnackBarHelper.showSnackBar(context, 'Send!');
    } else {
      SnackBarHelper.showSnackBar(context, 'Cancelled');
    }
  }

  void onPanicButtonPressed(BuildContext context) async {
    final String simNumber = panelData.panelSimNumber;
    final String adminCode = panelData.adminCode;
    final String message = "$adminCode PANIC 1 END";

    final isSend = await ProgressDialogWithMessage.show(
      context,
      messages: [message],
      panelSimNumber: simNumber,
    );

    if (isSend == true) {
      SnackBarHelper.showSnackBar(context, 'Send!');
    } else {
      SnackBarHelper.showSnackBar(context, 'Cancelled');
    }
  }

  void onSounderButtonPressed(BuildContext context) async {
    final String simNumber = panelData.panelSimNumber;
    final String adminCode = panelData.adminCode;
    final String message = "$adminCode SOUNDER OFF END";

    final isSend = await ProgressDialogWithMessage.show(
      context,
      messages: [message],
      panelSimNumber: simNumber,
    );

    if (isSend == true) {
      SnackBarHelper.showSnackBar(context, 'Send!');
    } else {
      SnackBarHelper.showSnackBar(context, 'Cancelled');
    }
  }
}
