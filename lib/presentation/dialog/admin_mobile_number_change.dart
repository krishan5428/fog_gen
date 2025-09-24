import 'package:flutter/material.dart';
import 'package:fire_nex/presentation/dialog/progress.dart';
import 'package:fire_nex/utils/silent_sms.dart';

import '../../constants/app_colors.dart';
import '../screens/panel_details.dart';
import '../viewModel/panel_view_model.dart';
import '../widgets/form_section.dart';
import '../widgets/vertical_gap.dart';
import 'confirmation_dialog.dart';

void showAdminMobileNumberChangeDialog(
  BuildContext context,
  String adminCode,
  String panelSimNumber,
  String adminMobileNumber,
  String panelName,
  PanelViewModel viewModel,
) {
  final TextEditingController currentAdminMobileNumberController =
      TextEditingController();
  final TextEditingController newAdminMobileNumberController =
      TextEditingController();
  final TextEditingController reenterAdminMobileNumberController =
      TextEditingController();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return AlertDialog(
        backgroundColor: Colors.white,
        contentPadding: const EdgeInsets.all(16),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VerticalSpace(height: 20),
              FormSection(
                label: 'Current Admin Mobile Number',
                controller: currentAdminMobileNumberController,
                keyboardType: TextInputType.number,
                maxLength: 10,
                validator:
                    (value) =>
                        value == null || value.length < 10
                            ? 'Enter valid current admin mobile number'
                            : null,
              ),
              VerticalSpace(),
              FormSection(
                label: 'New Admin Mobile Number',
                controller: newAdminMobileNumberController,
                keyboardType: TextInputType.number,
                maxLength: 10,
                validator:
                    (value) =>
                        value == null || value.length < 10
                            ? 'Enter valid new admin mobile number'
                            : null,
              ),
              VerticalSpace(),
              FormSection(
                label: 'Re-enter Admin Mobile Number',
                controller: reenterAdminMobileNumberController,
                keyboardType: TextInputType.number,
                maxLength: 10,
                validator:
                    (value) =>
                        value == null || value.length < 10
                            ? 'Enter valid re-entered admin mobile number'
                            : null,
              ),
              VerticalSpace(height: 20),
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
                    onPressed: () async {
                      final currentAdminMobileNumber =
                          currentAdminMobileNumberController.text.trim();
                      final newAdminMobileNumber =
                          newAdminMobileNumberController.text.trim();
                      final reenteredAdminMobileNumber =
                          reenterAdminMobileNumberController.text.trim();

                      if (adminMobileNumber != currentAdminMobileNumber) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Current admin number is incorrect'),
                          ),
                        );
                        return;
                      } else if (newAdminMobileNumber !=
                          reenteredAdminMobileNumber) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('New numbers do not match'),
                          ),
                        );
                        return;
                      }

                      final result = await showConfirmationDialog(
                        context: context,
                        message: 'Do you want to update Admin mobile number?',
                        cancelText: 'No',
                        confirmText: 'Yes',
                      );

                      if (result == true) {
                        final messages = getAdminMobileNumberMessages(
                          newAdminMobileNumber: newAdminMobileNumber,
                          adminCode: adminCode,
                          panelName: panelName,
                        );

                        // Show progress dialog
                        ProgressDialog.show(context);

                        // Send first SMS
                        sendSmsSilently(panelSimNumber, messages[0]);

                        // If a second message is present, delay and send
                        if (messages.length == 2) {
                          await Future.delayed(const Duration(seconds: 4));
                          sendSmsSilently(panelSimNumber, messages[1]);
                        }

                        // Dismiss progress dialog
                        if (context.mounted) ProgressDialog.dismiss(context);

                        final success = await viewModel.updateAdminMobileNumber(
                          panelSimNumber,
                          newAdminMobileNumber,
                        );

                        if (success && context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => PanelDetailsScreen(
                                    panelSimNumber: panelSimNumber,
                                  ),
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Admin number updated successfully',
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to update admin number'),
                            ),
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
  );
}

/// Returns one or two SMS messages based on panel type
List<String> getAdminMobileNumberMessages({
  required String panelName,
  required String adminCode,
  required String newAdminMobileNumber,
}) {
  if (panelName.toUpperCase() == "MULTICOM 4G DIALER") {
    return ["< $adminCode TEL NO\n#01-$newAdminMobileNumber* >"];
  } else {
    return [
      "$adminCode TEL NO INTRUSION #01-$newAdminMobileNumber* END",
      "$adminCode TEL NO FIRE #01-$newAdminMobileNumber* END",
    ];
  }
}
