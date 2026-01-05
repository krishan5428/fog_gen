import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../constants/app_colors.dart';
import '../panel_sr1/panel_sr1_viewmodel.dart';

class OutputControlsWidget extends StatelessWidget {
  const OutputControlsWidget({super.key});

  void _showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 4,
          backgroundColor: AppColors.white,
          title: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppColors.black,
            ),
          ),
          content: Text(
            content,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14,
              color: AppColors.greyDark,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                "Cancel",
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.colorAccent,
              ),
              child: const Text(
                "Confirm",
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onConfirm();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PanelSR1ViewModel>();

    const buttonTextStyle = TextStyle(
      fontFamily: 'Montserrat',
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      fontSize: 12,
    );
    final bool isSounderOn = viewModel.outputSounderStatus == "ON";
    final String sounderButtonText = isSounderOn ? "OFF SOUNDER" : "ON SOUNDER";

    final ButtonStyle sounderButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: isSounderOn ? AppColors.colorAccent : AppColors.greyDark,
      foregroundColor: Colors.white,
      shape: const StadiumBorder(),
      textStyle: buttonTextStyle,
    );

    final ButtonStyle triggerButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.orange.shade800,
      foregroundColor: AppColors.white,
      shape: const StadiumBorder(),
      textStyle: buttonTextStyle,
    );

    final bool isFanOn = viewModel.outputAuto3Status == "ON";
    final String fanButtonText = isFanOn ? "OFF EXHAUST FAN" : "ON EXHAUST FAN";

    final ButtonStyle fanButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: isFanOn ? AppColors.textGrey : AppColors.connectionGreen,
      foregroundColor: Colors.white,
      shape: const StadiumBorder(),
      textStyle: buttonTextStyle,
    );

    return Container(
      margin: const EdgeInsets.only(left: 7, right: 7, top: 7),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.18),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Output Controls",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.black,
            ),
          ),
          const Divider(height: 16, thickness: 0.5),

          // ✅ First row
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: sounderButtonStyle,
                  onPressed: () {
                    _showConfirmationDialog(
                      context: context,
                      title:
                          isSounderOn
                              ? "Turn Sounder OFF?"
                              : "Turn Sounder ON?",
                      content:
                          "Are you sure you want to turn the sounder ${isSounderOn ? "OFF" : "ON"}?",
                      onConfirm: () {
                        HapticFeedback.lightImpact();
                        if (isSounderOn) {
                          viewModel.sendSounderOffAckCommand();
                        } else {
                          viewModel.sendSounderOnCommand();
                        }
                      },
                    );
                  },
                  child: Text(sounderButtonText),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: triggerButtonStyle,
                  onPressed: () {
                    _showConfirmationDialog(
                      context: context,
                      title: "Trigger Fogger?",
                      content:
                          "Are you sure you want to trigger the fogger (pulse)?",
                      onConfirm: () {
                        HapticFeedback.lightImpact();
                        viewModel.sendAutomationPulseCommand(2);
                      },
                    );
                  },
                  child: const Text(
                    "FOGGER TRIGGER",
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: fanButtonStyle,
                  onPressed: () {
                    _showConfirmationDialog(
                      context: context,
                      title:
                          isFanOn
                              ? "Turn Exhaust Fan OFF?"
                              : "Turn Exhaust Fan ON?",
                      content:
                          "Are you sure you want to turn the exhaust fan ${isFanOn ? "OFF" : "ON"}?",
                      onConfirm: () {
                        HapticFeedback.lightImpact();
                        viewModel.sendAutomationToggleCommand(3, !isFanOn);
                      },
                    );
                  },
                  child: Text(
                    fanButtonText,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _showConfirmationDialog(
                      context: context,
                      title: "Reset Alarms?",
                      content: "Are you sure you want to reset all alarms?",
                      onConfirm: () {
                        HapticFeedback.lightImpact();
                        viewModel.sendAlarmResetCommand();
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.connectionGreen,
                    foregroundColor: AppColors.white,
                    shape: const StadiumBorder(),
                    textStyle: buttonTextStyle,
                  ),
                  child: const Text('ALARM RESET'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
