import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fog_gen_new/utils/navigation.dart';
import 'package:fog_gen_new/utils/snackbar_helper.dart';

import '../../constants/app_colors.dart';
import '../../core/data/pojo/panel_data.dart';
import '../../core/responses/socket_repository.dart';
import '../../core/utils/application_class.dart';
import '../../core/utils/packets.dart';
import '../cubit/panel/panel_cubit.dart';
import '../dialog/confirmation_dialog.dart';
import '../dialog/ok_dialog.dart';
import '../dialog/progress.dart';
import '../dialog/progress_with_message.dart';
import '../widgets/form_section.dart';
import '../widgets/vertical_gap.dart';

Future<PanelData?> showChangeAddressBottomSheet(
  BuildContext context,
  PanelData panelData,
) {
  final newAddressController = TextEditingController();
  String? errorText;

  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.lightGrey,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return BlocListener<PanelCubit, PanelState>(
        listener: (context, state) {
          if (state is PanelLoading) {
            ProgressDialog.show(context);
          }
          if (state is UpdatePanelsSuccess) {
            ProgressDialog.dismiss(context);
            CustomNavigation.instance.popWithResult(
              context: context,
              result: state.panelData,
            );
          } else if (state is UpdatePanelsFailure) {
            ProgressDialog.dismiss(context);
            SnackBarHelper.showSnackBar(context, state.message);
          }
        },
        child: StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),
                    Center(
                      child: Container(
                        height: 4,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Update Address",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.colorPrimary,
                      ),
                    ),
                    const VerticalSpace(height: 20),

                    FormSection(
                      label: 'New Address',
                      controller: newAddressController,
                      keyboardType: TextInputType.text,
                      maxLength: 40,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Enter a valid address'
                          : null,
                    ),

                    if (errorText != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          errorText!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(color: AppColors.colorAccent),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.colorPrimary,
                            foregroundColor: AppColors.white,
                          ),
                          onPressed: () async {
                            final newAddress = newAddressController.text.trim();

                            if (newAddress.isEmpty) {
                              setState(() {
                                errorText = 'Address field must be filled!';
                              });
                              return;
                            }

                            final confirm = await showConfirmationDialog(
                              context: context,
                              message: 'Do you want to update this address?',
                              cancelText: 'No',
                              confirmText: 'Yes',
                            );

                            if (confirm != true) {
                              SnackBarHelper.showSnackBar(context, 'Cancelled');
                              return;
                            }

                            /// 1. Handle IP or IP+GSM Panels
                            if (panelData.isIpPanel || panelData.isIpGsmPanel) {
                              try {
                                final socketRepository = SocketRepository();
                                final app = Application();
                                app.mIPAddress = panelData.ipAdd;
                                app.mPortNumber = int.tryParse(
                                  panelData.portNo,
                                );
                                app.mPassword = panelData.pass;

                                final response = await socketRepository
                                    .sendPacketSR1(
                                      Packets.getPacket(
                                        isReadPacket: false,
                                        args: ["021", newAddress],
                                      ),
                                    );

                                if (response == "S*007#0*E") {
                                  // Success via IP
                                  context.read<PanelCubit>().updatePanelData(
                                    userId: panelData.usrId,
                                    panelId: panelData.pnlId,
                                    key: 'site_address',
                                    value: newAddress,
                                  );
                                } else {
                                  // IP connected but returned invalid response
                                  await _handleIpFailure(
                                    context,
                                    panelData,
                                    newAddress,
                                  );
                                }
                              } catch (e) {
                                // IP Connection Failed (Socket Error) -> Attempt Fallback
                                await _handleIpFailure(
                                  context,
                                  panelData,
                                  newAddress,
                                );
                              }
                            }

                            /// 2. Handle GSM Only Panels else {
                            _sendSMSCommand(newAddress, panelData, context);
                          },
                          child: const Text("Submit"),
                        ),
                      ],
                    ),
                    const VerticalSpace(height: 10),
                  ],
                ),
              ),
            );
          },
        ),
      );
    },
  );
}

/// Helper to handle fallback logic when IP fails (either via Exception or Bad Response)
Future<void> _handleIpFailure(
  BuildContext context,
  PanelData panelData,
  String newAddress,
) async {
  if (panelData.isIpGsmPanel) {
    final confirm = await showConfirmationDialog(
      context: context,
      message: 'Unable to connect via IP!\nDo you want to send SMS command?',
    );
    if (confirm == true) {
      _sendSMSCommand(newAddress, panelData, context);
    }
  } else if (panelData.isIpPanel) {
    showInfoDialog(
      context: context,
      message:
          'Seems like Panel is not connected!\nPlease check the Panel and try again!',
    );
  }
}

void _sendSMSCommand(
  String newAddress,
  PanelData panelData,
  BuildContext context,
) async {
  final message = getAddressMessage(
    newAddress: newAddress,
    panelName: panelData.panelName,
  );

  final simNumber = panelData.panelSimNumber.trim();

  if (message.isEmpty || simNumber.isEmpty) {
    SnackBarHelper.showSnackBar(
      context,
      'Invalid address message or SIM number.',
    );
    return;
  }

  final isSent = await ProgressDialogWithMessage.show(
    context,
    messages: [message],
    panelSimNumber: simNumber,
  );

  if (isSent == true) {
    context.read<PanelCubit>().updatePanelData(
      userId: panelData.usrId,
      panelId: panelData.pnlId,
      key: 'site_address',
      value: newAddress,
    );
  }
}

String getAddressMessage({
  required String panelName,
  required String newAddress,
}) {
  return "< 1234 SIGNATURE #$newAddress* >";
}
