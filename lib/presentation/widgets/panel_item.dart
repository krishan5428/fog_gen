import 'package:fire_nex/core/responses/socket_repository.dart';
import 'package:fire_nex/core/utils/packets.dart';
import 'package:fire_nex/presentation/dialog/confirmation_dialog.dart';
import 'package:fire_nex/presentation/dialog/ok_dialog.dart';
import 'package:fire_nex/presentation/dialog/progress.dart';
import 'package:fire_nex/presentation/dialog/progress_with_message.dart';
import 'package:fire_nex/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../core/utils/application_class.dart';
import '../../data/database/app_database.dart';
import '../../utils/navigation.dart';
import '../../utils/responsive.dart';
import '../screens/panel_details.dart';
import 'custom_button.dart';

class PanelCard extends StatelessWidget {
  final PanelData panelData;
  const PanelCard({super.key, required this.panelData});

  @override
  Widget build(BuildContext context) {
    final fontSize = Responsive.fontSize(context);
    final spacingBwtView = Responsive.spacingBwtView(context);
    final smallTextSize = Responsive.smallTextSize(context);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: AppColors.colorAccent),
      ),
      elevation: 2,
      color: AppColors.white,
      child: Padding(
        padding: EdgeInsets.all(spacingBwtView),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 0),
              child: Row(
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
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.colorPrimary,
                      side: const BorderSide(
                        width: 0.5,
                        color: AppColors.colorPrimary,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
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
            ),
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        buttonText: 'ALARM RESET',
                        onPressed: () => onAlarmResetButtonPressed(context),
                        buttonTextSize: smallTextSize,
                        backgroundColor: AppColors.litePrimary,
                        foregroundColor: AppColors.colorPrimary,
                      ),
                    ),
                    SizedBox(width: spacingBwtView),
                    Expanded(
                      child: CustomButton(
                        buttonText: 'EVACUATE',
                        onPressed: () => onEvacuateButtonPressed(context),
                        buttonTextSize: smallTextSize,
                        backgroundColor: AppColors.litePrimary,
                        foregroundColor: AppColors.colorPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacingBwtView / 2),
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    buttonText: 'SOUNDER OFF',
                    onPressed: () => onSounderButtonPressed(context),
                    buttonTextSize: smallTextSize,
                    backgroundColor: AppColors.litePrimary,
                    foregroundColor: AppColors.colorPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void onAlarmResetButtonPressed(BuildContext context) {
    _sendOutputCommand(
      context: context,
      outputNumber: 3,
      title: "Confirm Alarm Reset",
      confirmationMessage:
          "Are you sure you want to SEND SMS to reset the alarm?",
    );
  }

  void onSounderButtonPressed(BuildContext context) {
    _sendOutputCommand(
      context: context,
      outputNumber: 4,
      title: "Confirm Sounder Off",
      confirmationMessage:
          "Do you really want to SEND SMS to turn off the sounder?",
    );
  }

  void onEvacuateButtonPressed(BuildContext context) {
    _sendOutputCommand(
      context: context,
      outputNumber: 2,
      title: "Confirm Evacuation",
      confirmationMessage:
          "Are you sure you want to SEND SMS to trigger evacuation?",
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
      SnackBarHelper.showSnackBar(context, 'Execution revoked!');
      return;
    }

    if (panelData.isIPPanel || panelData.isIPGPRSPanel) {
      ProgressDialog.show(context);

      final _ =
          Application()
            ..mIPAddress = panelData.ipAddress
            ..mPortNumber = int.tryParse(panelData.port)
            ..mPassword = panelData.ipPassword;

      final lastOutput = outputNumber - 1;

      try {
        final response = await socketRepository.sendPacketSR1(
          Packets.getPacket(
            isReadPacket: false,
            args: ["007", lastOutput.toString().padLeft(3, '0'), "3"],
          ),
        );

        debugPrint('response from panel: $response');

        ProgressDialog.dismiss(context);

        if (response == "S*007#0*E") {
          SnackBarHelper.showSnackBar(context, 'Successful');
        } else {
          await _handleFailedIPCommand(context, outputNumber);
        }
      }
      catch (e) {
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
          if (panelData.isIPGPRSPanel) {
            final confirm = await showConfirmationDialog(
              context: context,
              title: 'Network Unavailable❗️',
              message:
                  'We couldn’t reach the device through IP.\n Would you like to try sending the command by SMS?',
            );
            if (confirm == true) {
              _sendCommandSMS(outputNumber, context);
            } else {
              SnackBarHelper.showSnackBar(context, 'Execution revoked');
            }
          } else if (panelData.isIPPanel) {
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
    if (panelData.isIPGPRSPanel) {
      final confirm = await showConfirmationDialog(
        context: context,
        message:
            'Unable to send IP Command!\nDo you want to send the SMS command instead?',
      );
      if (confirm == true) {
        _sendCommandSMS(outputNumber, context);
      }
    } else if (panelData.isIPPanel) {
      showInfoDialog(
        context: context,
        message:
            'Panel seems to be offline.\nPlease check the connection and try again.',
      );
    }
  }

  void _sendCommandSMS(int outputNumber, BuildContext context) async {
    final simNumber = panelData.panelSimNumber;
    final onMessage = "< 1234 OUTPUT $outputNumber ON >";
    final offMessage = "< 1234 OUTPUT $outputNumber OFF >";

    final messages = [onMessage, offMessage];
    final isSend = await ProgressDialogWithMessage.show(
      context,
      messages: messages,
      panelSimNumber: simNumber,
    );
    if (isSend == true) {
      SnackBarHelper.showSnackBar(context, 'Done');
    } else {
      SnackBarHelper.showSnackBar(context, 'Revoked!');
    }
  }
}
