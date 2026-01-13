import 'package:fog_gen_new/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../constants/app_colors.dart';
import '../../core/data/pojo/panel_data.dart';
import '../../utils/auth_helper.dart';
import '../../utils/navigation.dart';
import '../cubit/panel/panel_cubit.dart';
import '../dialog/confirmation_dialog.dart';
import '../dialog/progress.dart';
import '../dialog/progress_with_message.dart';
import '../widgets/form_section.dart';
import '../widgets/vertical_gap.dart';

Future<PanelData?> showAdminMobileNumberChangeBottomSheet(
  BuildContext context,
  PanelData panel,
) {
  final TextEditingController currentAdminMobileNumberController =
      TextEditingController();
  final TextEditingController newAdminMobileNumberController =
      TextEditingController();
  final TextEditingController reenterAdminMobileNumberController =
      TextEditingController();
  String? errorText;

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.lightGrey,
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
                top: 0,
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
                      "Change Admin Mobile Number",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.colorPrimary,
                      ),
                    ),
                    VerticalSpace(height: 20),
                    FormSection(
                      label: 'Current Admin Mobile Number',
                      controller: currentAdminMobileNumberController,
                      keyboardType: TextInputType.number,
                      maxLength: 10,
                      validator: (value) => value == null || value.length < 10
                          ? 'Enter valid current admin mobile number'
                          : null,
                    ),
                    VerticalSpace(),
                    FormSection(
                      label: 'New Admin Mobile Number',
                      controller: newAdminMobileNumberController,
                      keyboardType: TextInputType.number,
                      maxLength: 10,
                      validator: (value) => value == null || value.length < 10
                          ? 'Enter valid new admin mobile number'
                          : null,
                    ),
                    VerticalSpace(),
                    FormSection(
                      label: 'Re-enter Admin Mobile Number',
                      controller: reenterAdminMobileNumberController,
                      keyboardType: TextInputType.number,
                      maxLength: 10,
                      validator: (value) => value == null || value.length < 10
                          ? 'Enter valid re-entered admin mobile number'
                          : null,
                    ),
                    if (errorText != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
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
                            final currentAdminMobileNumber =
                                currentAdminMobileNumberController.text.trim();
                            final newAdminMobileNumber =
                                newAdminMobileNumberController.text.trim();
                            final reenteredAdminMobileNumber =
                                reenterAdminMobileNumberController.text.trim();

                            if (currentAdminMobileNumber.isEmpty ||
                                newAdminMobileNumber.isEmpty ||
                                reenteredAdminMobileNumber.isEmpty) {
                              setState(() {
                                errorText = 'All fields must be filled!';
                              });
                              return;
                            }

                            if (panel.adminMobileNumber !=
                                currentAdminMobileNumber) {
                              setState(() {
                                errorText = 'Current admin number is incorrect';
                              });
                              return;
                            } else if (newAdminMobileNumber !=
                                reenteredAdminMobileNumber) {
                              setState(() {
                                errorText = 'New numbers do not match';
                              });
                              return;
                            }

                            final result = await showConfirmationDialog(
                              context: context,
                              message:
                                  'Do you want to update Admin mobile number?',
                              cancelText: 'No',
                              confirmText: 'Yes',
                            );

                            if (result == true) {
                              String device =
                                  await SharedPreferenceHelper.getDeviceType();
                              final smsPermission = await Permission.sms.status;

                              final messages = getAdminMobileNumberMessages(
                                newAdminMobileNumber: newAdminMobileNumber,
                                panel: panel,
                              );

                              var isSend = false;

                              if (messages.isNotEmpty &&
                                  panel.panelSimNumber.trim().isNotEmpty &&
                                  device.isNotEmpty) {
                                debugPrint('sms executed');
                                isSend = (await _trySendSms(
                                  context,
                                  device,
                                  smsPermission,
                                  panel.panelSimNumber,
                                  [messages],
                                ))!;
                              }

                              if (isSend) {
                                context.read<PanelCubit>().updatePanelData(
                                  userId: panel.userId,
                                  panelId: panel.pnlId,
                                  key: 'admin_mobile_number',
                                  value: newAdminMobileNumber,
                                );
                              } else {
                                SnackBarHelper.showSnackBar(
                                  context,
                                  'Cancelled',
                                );
                              }
                            }
                          },
                          child: const Text("Submit"),
                        ),
                      ],
                    ),
                    VerticalSpace(height: 10),
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

Future<bool?> _trySendSms(
  BuildContext context,
  String device,
  PermissionStatus smsPermission,
  String simNumber,
  List<String> messages,
) async {
  // if (device.toUpperCase() == "ANDROID" && smsPermission.isGranted) {
  // Show progress dialog
  final result = ProgressDialogWithMessage.show(
    context,
    messages: messages,
    panelSimNumber: simNumber,
  );
  return result;
  // } else {
  //   // Fallback: directly send SMS
  //   for (final msg in messages) {
  //     await sendSms(simNumber, msg);
  //   }
  //   return true;
  // }
}

String getAdminMobileNumberMessages({
  required PanelData panel,
  required String newAdminMobileNumber,
}) {
  return '''
< 1234 TEL NO
#01-+91$newAdminMobileNumber*
#02-+91${panel.adminMobileNumber}*
#03-+91${panel.mobileNumber2}*
#04-+91${panel.mobileNumber3}*
#05-+91${panel.mobileNumber4}*
>
''';
}
