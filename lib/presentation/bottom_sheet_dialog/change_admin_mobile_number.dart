import 'package:flutter/material.dart';
import 'package:fire_nex/data/database/app_database.dart';
import 'package:fire_nex/presentation/dialog/progress.dart';
import 'package:fire_nex/utils/silent_sms.dart';

import '../../constants/app_colors.dart';
import '../../constants/strings.dart';
import '../dialog/confirmation_dialog.dart';
import '../screens/panel_details.dart';
import '../viewModel/panel_view_model.dart';
import '../widgets/form_section.dart';
import '../widgets/vertical_gap.dart';

void showAdminMobileNumberChangeBottomSheet(
  BuildContext context,
  PanelData panel,
  PanelViewModel viewModel,
) {
  final TextEditingController currentAdminMobileNumberController =
      TextEditingController();
  final TextEditingController newAdminMobileNumberController =
      TextEditingController();
  final TextEditingController reenterAdminMobileNumberController =
      TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
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

                      if (panel.adminMobileNumber != currentAdminMobileNumber) {
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
                          panel: panel,
                        );

                        // Show progress dialog
                        ProgressDialog.show(context);

                        // Send first SMS
                        sendSmsSilently(panel.panelSimNumber, messages[0]);

                        // If a second message is present, delay and send
                        if (messages.length == 2) {
                          await Future.delayed(const Duration(seconds: 4));
                          sendSmsSilently(panel.panelSimNumber, messages[1]);
                        }

                        // Dismiss progress dialog
                        if (context.mounted) ProgressDialog.dismiss(context);

                        final success = await viewModel.updateAdminMobileNumber(
                          panel.panelSimNumber,
                          newAdminMobileNumber,
                        );

                        if (success && context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => PanelDetailsScreen(
                                    panelSimNumber: panel.panelSimNumber,
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
String getAdminMobileNumberMessages({
  required PanelData panel,
  required String newAdminMobileNumber,
}) {
  if (neuronPanels.contains(panel.panelName)) {
    return '''
< 1234 TEL NO
#01-+91$newAdminMobileNumber*
#02-+91${panel.mobileNumber1}*
#03-+91${panel.mobileNumber2}*
#04-+91${panel.mobileNumber3}*
#05-+91${panel.mobileNumber4}*
>
''';
  } else if (fourGComPanels.contains(panel.panelName)) {
    return "SECURICO 1234 ADD ADMIN +91-$newAdminMobileNumber END";
  } else {
    return "";
  }
}
