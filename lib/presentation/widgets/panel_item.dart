import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fog_gen_new/core/repo/mqtt_repository.dart';
import 'package:fog_gen_new/features/mqtt/screens/mqtt_control_screen.dart';
import 'package:fog_gen_new/features/mqtt/services/fourg_mqtt_commands.dart';
import 'package:fog_gen_new/features/mqtt/services/fourg_mqtt_service.dart';
import 'package:fog_gen_new/presentation/screens/mqtt_panel_details.dart';
import 'package:toastification/toastification.dart';
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

  /// G4 (4GCOM) panels are identified by a non-empty IMEI and use MQTT.
  bool get _isFourG => panelData.panelImei.trim().isNotEmpty;

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
                      screen: _isFourG
                          ? MqttPanelDetailsScreen(panelData: panelData)
                          : PanelDetailsScreen(panelData: panelData),
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

            if (_isFourG)
              _buildFourGPanelButtons(context, smallTextSize * 0.9, spacing)
            else
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

  // ---------------------------------------------------------------------------
  // G4 (4GCOM) PANELS → Evacuate (O1), Alarm Reset (O2), Silence (O3), Connect
  // ---------------------------------------------------------------------------

  Widget _buildFourGPanelButtons(
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
                buttonText: 'EVACUATE',
                onPressed: () => onEvacuate(context),
                buttonTextSize: textSize,
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: CustomButton(
                buttonText: 'ALARM RESET',
                onPressed: () => onAlarmReset(context),
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
                buttonText: 'SILENCE',
                onPressed: () => onSounderOff(context),
                buttonTextSize: textSize,
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: CustomButton(
                buttonText: 'CONNECT',
                onPressed: () => _openFourGDashboard(context),
                buttonTextSize: textSize,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _openFourGDashboard(BuildContext context) async {
    final result = await CustomNavigation.instance.push(
      context: context,
      screen: MqttControlScreen(
        panelName: panelData.panelName,
        siteName: panelData.siteName,
        panelId: panelData.pnlAccNo,
        imei: panelData.panelImei,
        passcode: panelData.pass,
        panelData: panelData,
      ),
    );
    if (result == "disconnected" && context.mounted) {
      toastification.show(
        context: context,
        type: ToastificationType.info,
        style: ToastificationStyle.fillColored,
        alignment: Alignment.bottomCenter,
        title: Text(
          "Disconnected",
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            fontSize: 14.sp,
          ),
        ),
        description: Text(
          "Device Disconnected",
          style: TextStyle(fontFamily: 'Montserrat', fontSize: 12.sp),
        ),
        autoCloseDuration: const Duration(seconds: 3),
        showProgressBar: false,
        primaryColor: Colors.grey.shade700,
        icon: const Icon(Icons.link_off, color: Colors.white),
      );
    }
  }

  // One-shot quick action over a short-lived MQTT link:
  // connect (8 s cap) → enable output if disabled (011, not a 001 dashboard
  // read, which the backend treats as an app login) → ON → 9 s → OFF →
  // wait for queue → disconnect. Unreachable → offer SMS fallback.
  Future<void> _sendCommandMqtt(BuildContext context, int outputNumber) async {
    final imei = panelData.panelImei.trim();
    if (!_busyImeis.add(imei)) {
      _showBottomToast(
        context: context,
        success: false,
        title: 'Please Wait',
        message: 'A command is already running on this device.',
      );
      return;
    }

    final mqttRepository = MqttRepository();
    final fourGService = FourGMqttService(mqttRepository);

    ProgressDialog.show(context, message: 'Connecting to device...');

    bool connected;
    try {
      connected = await fourGService
          .connectAndHandshake(imei: imei, passcode: panelData.pass)
          .timeout(const Duration(seconds: 8), onTimeout: () => false);
    } catch (_) {
      connected = false;
    }

    if (!connected) {
      // ignore: use_build_context_synchronously — dismiss() checks mounted itself and must run so the spinner never stays up
      ProgressDialog.dismiss(context);
      mqttRepository.disconnect();
      _busyImeis.remove(imei);
      if (!context.mounted) return;
      await _offerMqttSmsFallback(
        context: context,
        outputNumber: outputNumber,
        message:
            'We couldn’t reach the device over MQTT.\nWould you like to try sending the command by SMS instead?',
      );
      return;
    }

    try {
      await fourGService.ensureOutputsEnabled(
        imei: imei,
        passcode: panelData.pass,
        outputs: [_fourGOutputFor(outputNumber)],
        viaDashboard: false,
      );
    } catch (_) {}

    // ignore: use_build_context_synchronously — dismiss() checks mounted itself and must run so the spinner never stays up
    ProgressDialog.dismiss(context);

    // The user confirmed: the command goes out even if the card is gone;
    // context is only used for result toasts, which check mounted.
    unawaited(
      _fireControlCommand(
        // ignore: use_build_context_synchronously
        context: context,
        mqttRepository: mqttRepository,
        fourGService: fourGService,
        outputNumber: outputNumber,
      ),
    );
  }

  Future<void> _fireControlCommand({
    required BuildContext context,
    required MqttRepository mqttRepository,
    required FourGMqttService fourGService,
    required int outputNumber,
  }) async {
    final fourGOutput = _fourGOutputFor(outputNumber);
    final actionLabel = switch (outputNumber) {
      2 => 'Evacuation',
      3 => 'Alarm Reset',
      _ => 'Sounder Off',
    };

    Future<bool> setOutput(bool on) => fourGService.setOutput(
      imei: panelData.panelImei,
      passcode: panelData.pass,
      output: fourGOutput,
      on: on,
    );

    bool success;
    try {
      success = await setOutput(true);
    } catch (_) {
      success = false;
    }

    if (context.mounted) {
      _showBottomToast(
        context: context,
        success: success,
        title: success ? 'Sent' : 'Send Failed',
        message: success
            ? '$actionLabel command sent to the device.'
            : '$actionLabel command could not be sent.',
      );
    }

    try {
      if (success) {
        await Future.delayed(FourGMqttCommands.outputPulseDuration);
        await setOutput(false);
      }
      await fourGService.idle;
    } catch (_) {
      // The ON result was already shown.
    } finally {
      mqttRepository.disconnect();
      _busyImeis.remove(panelData.panelImei.trim());
    }
  }

  static final Set<String> _busyImeis = {};

  /// Card buttons are numbered 2/3/4 (Evacuate / Reset / Silence); on a
  /// 4GCOM they drive Outputs 1/2/3.
  static int _fourGOutputFor(int outputNumber) => outputNumber - 1;

  void _showBottomToast({
    required BuildContext context,
    required bool success,
    required String title,
    required String message,
  }) {
    if (!context.mounted) return;
    toastification.show(
      context: context,
      type: success ? ToastificationType.success : ToastificationType.error,
      style: ToastificationStyle.fillColored,
      alignment: Alignment.bottomCenter,
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.bold,
          fontSize: 14.sp,
        ),
      ),
      description: Text(
        message,
        style: TextStyle(fontFamily: 'Montserrat', fontSize: 12.sp),
      ),
      autoCloseDuration: const Duration(seconds: 3),
      showProgressBar: false,
      primaryColor: success ? Colors.green.shade600 : Colors.red.shade600,
      icon: Icon(
        success ? Icons.check_circle_outline : Icons.error_outline,
        color: Colors.white,
      ),
    );
  }

  Future<void> _offerMqttSmsFallback({
    required BuildContext context,
    required int outputNumber,
    required String message,
  }) async {
    if (panelData.panelSimNumber.trim().isEmpty) {
      showInfoDialog(
        context: context,
        message:
            'Unable to reach the device and no SMS number is configured for it.',
      );
      return;
    }
    final confirm = await showConfirmationDialog(
      context: context,
      title: 'Device Unreachable❗️',
      message: message,
    );
    if (confirm == true && context.mounted) {
      _sendCommandSMS(outputNumber, context);
    }
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

    if (_isFourG) {
      await _sendCommandMqtt(context, outputNumber);
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
    // G4 panels use their own passcode and Outputs 1/2/3.
    final pass = _isFourG ? panelData.pass : "1234";
    final output = _isFourG ? _fourGOutputFor(outputNumber) : outputNumber;
    final onMessage = "< $pass OUTPUT $output ON >";
    final offMessage = "< $pass OUTPUT $output OFF >";

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
