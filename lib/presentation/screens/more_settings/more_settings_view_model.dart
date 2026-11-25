import 'package:flutter/material.dart';
import 'package:fog_gen_new/core/data/pojo/panel_data.dart';
import 'package:fog_gen_new/core/responses/socket_repository.dart';
import 'package:fog_gen_new/core/utils/application_class.dart';
import 'package:fog_gen_new/core/utils/packets.dart';
import 'package:fog_gen_new/presentation/bottom_sheet_dialog/local_ip_settings.dart';
import 'package:fog_gen_new/presentation/bottom_sheet_dialog/panel_id.dart';
import 'package:fog_gen_new/presentation/bottom_sheet_dialog/update_destination_ip_data.dart';
import 'package:fog_gen_new/presentation/dialog/ok_dialog.dart';
import 'package:fog_gen_new/presentation/dialog/progress.dart';
import 'package:fog_gen_new/utils/navigation.dart';
import 'package:fog_gen_new/utils/snackbar_helper.dart';

class MoreSettingsViewModel extends ChangeNotifier {
  final PanelData panelData;
  final SocketRepository _socketRepository;

  MoreSettingsViewModel({
    required this.panelData,
    SocketRepository? socketRepository,
  }) : _socketRepository = socketRepository ?? SocketRepository();

  void _setupPanelConnection() {
    final app = Application();
    app.mIPAddress = panelData.ipAdd;
    app.mPortNumber = int.tryParse(panelData.portNo);
    app.mPassword = panelData.pass;
    app.mStaticIPAddress = panelData.staticIp;
    app.mStaticPortNumber = int.tryParse(panelData.staticPort);
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
        await _handleConnectionFailure(context);
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

  // The Panel ID can only be read over IP: an SMS cannot bring the panel's
  // answer back into the app. (This used to offer an SMS fallback that sent
  // the literal text "message" and then reported "Address updated".)
  Future<void> _handleConnectionFailure(BuildContext context) async {
    if (!context.mounted) return;
    await showInfoDialog(
      context: context,
      message:
          'Panel not reachable over IP.\nThe Panel ID can only be read over IP. '
          'Please check the network and try again.',
    );
  }
}
