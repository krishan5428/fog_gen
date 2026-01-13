import 'package:flutter/material.dart';
import 'package:fog_gen_new/core/data/pojo/panel_data.dart';
import 'package:fog_gen_new/core/responses/socket_repository.dart';
import 'package:fog_gen_new/core/utils/application_class.dart';
import 'package:fog_gen_new/core/utils/packets.dart';
import 'package:fog_gen_new/presentation/bottom_sheet_dialog/local_ip_settings.dart';
import 'package:fog_gen_new/presentation/bottom_sheet_dialog/panel_id.dart';
import 'package:fog_gen_new/presentation/bottom_sheet_dialog/update_destination_ip_data.dart';
import 'package:fog_gen_new/presentation/dialog/confirmation_dialog.dart';
import 'package:fog_gen_new/presentation/dialog/ok_dialog.dart';
import 'package:fog_gen_new/presentation/dialog/progress.dart';
import 'package:fog_gen_new/presentation/dialog/progress_with_message.dart';
import 'package:fog_gen_new/presentation/screens/panel_list/panel_list.dart';
import 'package:fog_gen_new/utils/navigation.dart';
import 'package:fog_gen_new/utils/snackbar_helper.dart';

class MoreSettingsViewModel extends ChangeNotifier {
  final PanelData panelData;
  final SocketRepository _socketRepository = SocketRepository();

  MoreSettingsViewModel({required this.panelData});

  void _setupPanelConnection() {
    final app = Application();
    app.mIPAddress = panelData.ip_address;
    app.mPortNumber = int.tryParse(panelData.port_no);
    app.mPassword = panelData.password;
    app.mStaticIPAddress = panelData.static_ip_address;
    app.mStaticPortNumber = int.tryParse(panelData.static_port_no);
  }

  // --- ACTIONS ---

  Future<void> fetchPanelID(BuildContext context) async {
    _setupPanelConnection();

    try {
      ProgressDialog.show(context, message: 'Reading Panel ID data...');

      final response = await _socketRepository.sendPacketSR1(
        Packets.getPacket(isReadPacket: true, args: ["001"]),
      );

      // Check mounted before using context again
      if (!context.mounted) return;
      ProgressDialog.dismiss(context);

      if (response.contains('001')) {
        showPanelIdDialog(context, response, _socketRepository);
      } else {
        await _handleConnectionFailure(context, "newAddress");
      }
    } catch (e) {
      // Check mounted in catch block too
      if (!context.mounted) return;
      ProgressDialog.dismiss(context);
      SnackBarHelper.showSnackBar(context, 'Failed to send packet: $e');
    }
  }

  Future<void> fetchLocalIPSettings(BuildContext context) async {
    _setupPanelConnection();

    try {
      ProgressDialog.show(context, message: 'Reading Local IP data...');

      final response = await _socketRepository.sendPacketSR1(
        Packets.getPacket(isReadPacket: true, args: ["002"]),
      );

      if (!context.mounted) return;
      ProgressDialog.dismiss(context);

      if (response.contains('002')) {
        showLocalIpSettings(context, response, _socketRepository);
      } else {
        SnackBarHelper.showSnackBar(context, 'Unexpected response: $response');
      }
    } catch (e) {
      if (!context.mounted) return;
      ProgressDialog.dismiss(context);
      SnackBarHelper.showSnackBar(context, 'Failed to send packet: $e');
    }
  }

  Future<void> fetchDestinationIPSettings(
    BuildContext context, {
    required String packetArg,
    required String title,
  }) async {
    _setupPanelConnection();

    try {
      ProgressDialog.show(context, message: 'Reading $title settings...');

      final response = await _socketRepository.sendPacketSR1(
        Packets.getPacket(isReadPacket: true, args: ["003", packetArg]),
      );

      if (!context.mounted) return;
      ProgressDialog.dismiss(context);

      if (response.contains("003")) {
        // We pop the "Selection Dialog" here
        CustomNavigation.instance.pop(context);

        // Show the data dialog
        showDestinationIPUpdateData(
          context,
          response,
          _socketRepository,
          title,
        );
      } else {
        CustomNavigation.instance.pop(context);
        SnackBarHelper.showSnackBar(context, 'Unexpected response: $response');
      }
    } catch (e) {
      if (!context.mounted) return;
      ProgressDialog.dismiss(context);
      CustomNavigation.instance.pop(context);
      SnackBarHelper.showSnackBar(context, 'Failed to send packet: $e');
    }
  }

  // --- HELPERS ---

  Future<void> _handleConnectionFailure(
    BuildContext context,
    String smsCommandType,
  ) async {
    if (panelData.is_ip_gsm_panel) {
      if (!context.mounted) return;

      final confirm = await showConfirmationDialog(
        context: context,
        message: 'Unable to send IP Command!\nDo you want to send SMS command?',
      );

      if (!context.mounted) return;

      if (confirm == true) {
        _sendSMSCommand(smsCommandType, context);
      }
    } else if (panelData.is_ip_panel) {
      if (!context.mounted) return;

      showInfoDialog(
        context: context,
        message:
            'Seems like Panel is not connected!\nPlease check the Panel and try again!',
      );
    }
  }

  Future<void> _sendSMSCommand(String commandType, BuildContext context) async {
    final simNumber = panelData.panelSimNumber.trim();

    // Note: ProgressDialogWithMessage.show is likely async internally
    final isSent = await ProgressDialogWithMessage.show(
      context,
      messages: ["message"],
      panelSimNumber: simNumber,
    );

    if (!context.mounted) return;

    if (isSent == true) {
      SnackBarHelper.showSnackBar(context, 'Address updated successfully.');
      CustomNavigation.instance.pushReplace(
        context: context,
        screen: const PanelListPage(),
      );
    }
  }
}
