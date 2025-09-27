import 'package:fire_nex/presentation/dialog/confirmation_dialog.dart';
import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../data/database/app_database.dart';
import '../../utils/navigation.dart';
import '../../utils/responsive.dart';
import '../../utils/silent_sms.dart';
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
                        screen: PanelDetailsScreen(
                          panelData: panelData,
                        ),
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
    int delaySeconds = 10,
  }) async {
    final confirm = await showConfirmationDialog(
      context: context,
      title: title,
      message: confirmationMessage,
    );

    if (confirm == true) {
      final simNumber = panelData.panelSimNumber;
      final onMessage = "< 1234 OUTPUT $outputNumber ON >";
      final offMessage = "< 1234 OUTPUT $outputNumber OFF >";

      sendSms(simNumber, onMessage);

      Future.delayed(Duration(seconds: delaySeconds), () {
        sendSms(simNumber, offMessage);
      });
    }
  }
}
