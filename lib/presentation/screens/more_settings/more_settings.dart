import 'package:fog_gen_new/constants/app_colors.dart';
import 'package:fog_gen_new/core/responses/socket_repository.dart';
import 'package:fog_gen_new/presentation/bottom_sheet_dialog/update_destination_ip_data.dart';
import 'package:fog_gen_new/presentation/dialog/progress.dart';
import 'package:fog_gen_new/presentation/screens/more_settings/telephone_no_settings_page.dart';
import 'package:fog_gen_new/presentation/screens/panel_list.dart';
import 'package:fog_gen_new/utils/navigation.dart';
import 'package:flutter/material.dart';

import '../../../core/data/pojo/panel_data.dart';
import '../../../core/utils/application_class.dart';
import '../../../core/utils/packets.dart';
import '../../../utils/responsive.dart';
import '../../../utils/snackbar_helper.dart';
import '../../bottom_sheet_dialog/local_ip_settings.dart';
import '../../bottom_sheet_dialog/panel_id.dart';
import '../../dialog/confirmation_dialog.dart';
import '../../dialog/ok_dialog.dart';
import '../../dialog/progress_with_message.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/box_button.dart';

class MoreSettingsScreen extends StatelessWidget {
  const MoreSettingsScreen({super.key, required this.panelData});
  final PanelData panelData;

  void _setupPanelConnection() {
    final app = Application();
    app.mIPAddress = panelData.ip_address;
    app.mPortNumber = int.tryParse(panelData.port_no);
    app.mPassword = panelData.password;
    app.mStaticIPAddress = panelData.static_ip_address;
    app.mStaticPortNumber = int.tryParse(panelData.static_port_no);
  }

  @override
  Widget build(BuildContext context) {
    final List<GridOption> options = [];
    final fontSize = Responsive.fontSize(context);
    final socketRepository = SocketRepository();
    options.addAll([
      GridOption(
        title: 'Add / Remove Numbers',
        icon: Icons.person_add_alt_1,
        onTap: () {
          CustomNavigation.instance.push(
            context: context,
            screen: TelephoneNoSettingsPage(panelData: panelData),
          );
        },
      ),

      GridOption(
        title: 'Panel ID',
        icon: Icons.device_hub,
        onTap: () async {
          _setupPanelConnection();

          try {
            ProgressDialog.show(context, message: 'Reading Panel ID data...');
            final response = await socketRepository.sendPacketSR1(
              Packets.getPacket(isReadPacket: true, args: ["001"]),
            );
            ProgressDialog.dismiss(context);

            if (response.contains('001')) {
              showPanelIdDialog(context, response, socketRepository);
            } else {
              if (panelData.is_ip_gsm_panel) {
                final confirm = await showConfirmationDialog(
                  context: context,
                  message:
                      'Unable to send IP Command!\nDo you want to send SMS command?',
                );
                if (confirm == true) {
                  _sendSMSCommand("newAddress", panelData, context);
                }
              }
              if (panelData.is_ip_panel) {
                showInfoDialog(
                  context: context,
                  message:
                      'Seems like Panel is not connected!\nPlease check the Panel and try again!',
                );
              }
            }
          } catch (e) {
            SnackBarHelper.showSnackBar(context, 'Failed to send packet: $e');
          }
        },
      ),
      GridOption(
        title: 'Local IP Settings',
        icon: Icons.settings_ethernet,
        onTap: () async {
          _setupPanelConnection();

          try {
            ProgressDialog.show(context, message: 'Reading Local IP data...');
            final response = await socketRepository.sendPacketSR1(
              Packets.getPacket(isReadPacket: true, args: ["002"]),
            );
            ProgressDialog.dismiss(context);
            if (response.contains('002')) {
              showLocalIpSettings(context, response, socketRepository);
            } else {
              SnackBarHelper.showSnackBar(
                context,
                'Unexpected response: $response',
              );
            }
          } catch (e) {
            SnackBarHelper.showSnackBar(context, 'Failed to send packet: $e');
          }
        },
      ),
      GridOption(
        title: 'Destination IP Settings',
        icon: Icons.public,
        onTap: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                backgroundColor: AppColors.white,
                title: Text(
                  'Destination IP Settings',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildOptionTile(
                      context,
                      title: 'CMS 1',
                      onTap: () async {
                        _setupPanelConnection();

                        try {
                          ProgressDialog.show(
                            context,
                            message: 'Reading CMS 1 settings...',
                          );
                          final response = await socketRepository.sendPacketSR1(
                            Packets.getPacket(
                              isReadPacket: true,
                              args: ["003", "001"],
                            ),
                          );

                          ProgressDialog.dismiss(context);
                          if (response.contains("003")) {
                            CustomNavigation.instance.pop(context);
                            showDestinationIPUpdateData(
                              context,
                              response,
                              socketRepository,
                              'CMS 1',
                            );
                          } else {
                            CustomNavigation.instance.pop(context);
                            SnackBarHelper.showSnackBar(
                              context,
                              'Unexpected response: $response',
                            );
                          }
                        } catch (e) {
                          CustomNavigation.instance.pop(context);
                          SnackBarHelper.showSnackBar(
                            context,
                            'Failed to send packet: $e',
                          );
                        }
                      },
                    ),
                    _buildOptionTile(
                      context,
                      title: 'CMS 2',
                      onTap: () async {
                        _setupPanelConnection();

                        try {
                          ProgressDialog.show(
                            context,
                            message: 'Reading CMS 2 settings...',
                          );
                          final response = await socketRepository.sendPacketSR1(
                            Packets.getPacket(
                              isReadPacket: true,
                              args: ["003", "002"],
                            ),
                          );
                          ProgressDialog.dismiss(context);
                          if (response.contains("003")) {
                            CustomNavigation.instance.pop(context);
                            showDestinationIPUpdateData(
                              context,
                              response,
                              socketRepository,
                              'CMS 2',
                            );
                          } else {
                            CustomNavigation.instance.pop(context);
                            SnackBarHelper.showSnackBar(
                              context,
                              'Unexpected response: $response',
                            );
                          }
                        } catch (e) {
                          CustomNavigation.instance.pop(context);
                          SnackBarHelper.showSnackBar(
                            context,
                            'Failed to send packet: $e',
                          );
                        }
                      },
                    ),
                    _buildOptionTile(
                      context,
                      title: 'PUSH SERVER',
                      onTap: () async {
                        _setupPanelConnection();

                        try {
                          ProgressDialog.show(
                            context,
                            message: 'Reading PUSH SERVER settings...',
                          );
                          final response = await socketRepository.sendPacketSR1(
                            Packets.getPacket(
                              isReadPacket: true,
                              args: ["003", "003"],
                            ),
                          );
                          ProgressDialog.dismiss(context);
                          if (response.contains("003")) {
                            CustomNavigation.instance.pop(context);
                            showDestinationIPUpdateData(
                              context,
                              response,
                              socketRepository,
                              'PUSH SERVER',
                            );
                          } else {
                            CustomNavigation.instance.pop(context);
                            SnackBarHelper.showSnackBar(
                              context,
                              'Unexpected response: $response',
                            );
                          }
                        } catch (e) {
                          CustomNavigation.instance.pop(context);
                          SnackBarHelper.showSnackBar(
                            context,
                            'Failed to send packet: $e',
                          );
                        }
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => CustomNavigation.instance.pop(context),
                    child: const Text(
                      'Close',
                      style: TextStyle(color: AppColors.colorPrimary),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    ]);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(pageName: 'More Settings', isFilter: false),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          itemCount: options.length,
          itemBuilder: (context, index) {
            final option = options[index];
            return GridBox(option: option);
          },
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 18),
      onTap: onTap,
    );
  }
}

void _sendSMSCommand(
  String newAddress,
  PanelData panelData,
  BuildContext context,
) async {
  // final message = getAddressMessage(
  //   newAddress: newAddress,
  //   panelName: panelData.panelName,
  // );

  final simNumber = panelData.panelSimNumber.trim();

  // if (message.isEmpty || simNumber.isEmpty) {
  //   SnackBarHelper.showSnackBar(
  //     context,
  //     'Invalid address message or SIM number.',
  //   );
  //   return;
  // }

  final isSent = await ProgressDialogWithMessage.show(
    context,
    messages: ["message"],
    panelSimNumber: simNumber,
  );

  if (isSent == true) {
    SnackBarHelper.showSnackBar(context, 'Address updated successfully.');
    CustomNavigation.instance.pushReplace(
      context: context,
      screen: const PanelListPage(),
    );
  }
}
