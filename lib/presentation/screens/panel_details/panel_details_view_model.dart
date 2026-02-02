import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/data/pojo/panel_data.dart';
import '../../../core/responses/socket_repository.dart';
import '../../../core/utils/application_class.dart';
import '../../../core/utils/packets.dart';
import '../../../utils/auth_helper.dart';
import '../../../utils/snackbar_helper.dart';
import '../../cubit/panel/panel_cubit.dart';
import '../../dialog/confirmation_dialog.dart';
import '../../dialog/progress.dart';
import '../../dialog/progress_with_message.dart';

class PanelDetailsViewModel extends ChangeNotifier {
  PanelData panelData;
  String? deviceType;

  PanelDetailsViewModel({required this.panelData}) {
    _loadDeviceType();
  }

  Future<void> _loadDeviceType() async {
    deviceType = await SharedPreferenceHelper.getDeviceType();
    notifyListeners();
  }

  void updatePanelData(PanelData newData) {
    panelData = newData;
    notifyListeners();
  }

  // -- Main Action --
  Future<void> initiateDeletePanel(BuildContext context) async {
    // 1. First Confirmation
    final firstConfirm = await showConfirmationDialog(
      context: context,
      message: 'Are you sure you want to delete this panel?',
    );
    if (firstConfirm != true) return;

    // 2. Second Confirmation
    if (!context.mounted) return;
    final secondConfirm = await showConfirmationDialog(
      context: context,
      message:
          'After deleting the Panel, you will not configure the panel.\nSure?',
    );
    if (secondConfirm != true) return;

    // 3. Execute Logic
    if (context.mounted) {
      await _executeDeletionLogic(context);
    }
  }

  Future<void> _executeDeletionLogic(BuildContext context) async {
    bool ipSuccess = false;
    bool? smsSuccess = false;
    final panel = panelData;

    // --- CASE 1: IP PANEL ---
    if (panel.isIpGsmPanel) {
      ProgressDialog.show(context);

      // Setup Application Global
      final _ = Application()
        ..mIPAddress = panel.ipAdd
        ..mPortNumber = int.tryParse(panel.portNo)
        ..mPassword = panel.pass
        ..mStaticIPAddress = panel.staticIp
        ..mStaticPortNumber = int.tryParse(panel.staticPort);

      try {
        final socketRepo = SocketRepository();
        final response = await socketRepo.sendPacketSR1(
          Packets.getPacket(isReadPacket: false, args: ["012", "2"]),
        );

        ProgressDialog.dismiss(context);

        if (response == "S*012#0*E") {
          if (context.mounted) {
            SnackBarHelper.showSnackBar(context, 'Panel removed through IP');
          }
          ipSuccess = true;
        } else {
          // IP Reached but Invalid Response
          if (!context.mounted) return;
          final fallback = await showConfirmationDialog(
            context: context,
            title: 'Network Unavailable❗️',
            message:
                'We couldn’t reach the device through IP.\nWould you like to try deleting the panel by SMS?',
          );

          if (fallback == true && context.mounted) {
            smsSuccess = await _performDeleteActionWithDialog(context);
          }
        }
      } catch (e) {
        ProgressDialog.dismiss(context);

        // Check for offline/connection errors
        final msg = e.toString().toLowerCase();
        final connectionFailed =
            msg.contains('socket') ||
            msg.contains('failed') ||
            msg.contains('timed out') ||
            msg.contains('refused');

        if (connectionFailed) {
          if (!context.mounted) return;
          final fallback = await showConfirmationDialog(
            context: context,
            title: 'Connection Failed',
            message:
                'Unable to connect via IP (Offline).\nWould you like to delete the panel by SMS instead?',
          );

          if (fallback == true && context.mounted) {
            smsSuccess = await _performDeleteActionWithDialog(context);
          }
        } else {
          if (context.mounted) {
            SnackBarHelper.showSnackBar(context, 'Unexpected error: $e');
          }
        }
      }
    }
    // --- CASE 2: NON-IP PANEL ---
    else {
      smsSuccess = await _performDeleteActionWithDialog(context);
    }

    // --- FINAL: BACKEND DELETE (OFFLINE SAFE) ---
    // If hardware reset succeeded OR if user wants to force delete from app
    bool shouldDeleteFromApp = ipSuccess || (smsSuccess == true);

    if (!shouldDeleteFromApp && context.mounted) {
      // OFFLINE FALLBACK: If hardware reset failed/skipped, ask to remove from App only
      shouldDeleteFromApp =
          await showConfirmationDialog(
            context: context,
            title: "Remove from App?",
            message:
                "Hardware reset failed or was skipped.\nDo you still want to remove this panel from your app list? (This works offline)",
          ) ??
          false;
    }

    if (shouldDeleteFromApp && context.mounted) {
      // This Cubit call handles the offline logic (Delete local -> Sync later)
      context.read<PanelCubit>().deletePanel(
        userId: panel.usrId,
        panelId: panel.pnlId,
      );
    }
  }

  Future<bool?> _performDeleteActionWithDialog(BuildContext context) async {
    final messages = _buildDeletionMessages(
      panelData.panelName,
      panelData.adminCode,
    );

    if (messages == null) {
      if (context.mounted) {
        SnackBarHelper.showSnackBar(
          context,
          "SMS Configuration not found for panel type: ${panelData.panelName}",
        );
      }
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
    return [
      '< 1234 CLEAR TEL >',
      '< 1234 SIGNATURE ADD SIGNATURE FOR THIS PANEL* >',
    ];
  }
}
