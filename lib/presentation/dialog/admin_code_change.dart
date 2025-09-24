import 'package:flutter/material.dart';
import 'package:fire_nex/utils/silent_sms.dart';

import '../../constants/app_colors.dart';
import '../screens/panel_details.dart';
import '../viewModel/panel_view_model.dart';
import '../widgets/form_section.dart';
import '../widgets/vertical_gap.dart';
import 'confirmation_dialog.dart';

void showChangeAdminCodeDialog(
  BuildContext context,
  String? currentAdminCode,
  String panelSimNumber,
  String panelName,
  PanelViewModel viewModel,
) {
  final TextEditingController currentCodeController = TextEditingController();
  final TextEditingController newCodeController = TextEditingController();
  final TextEditingController reenterCodeController = TextEditingController();

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
                label: 'Current Admin Code',
                controller: currentCodeController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                validator:
                    (value) =>
                        value == null || value.length < 4
                            ? 'Enter valid current code'
                            : null,
              ),
              VerticalSpace(),
              FormSection(
                label: 'New Admin Code',
                controller: newCodeController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                validator:
                    (value) =>
                        value == null || value.length < 4
                            ? 'Enter valid new code'
                            : null,
              ),
              VerticalSpace(),
              FormSection(
                label: 'Re-enter Admin Code',
                controller: reenterCodeController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                validator:
                    (value) =>
                        value == null || value.length < 4
                            ? 'Enter valid re-entered code'
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
                      final currentCode = currentCodeController.text;
                      final newCode = newCodeController.text;
                      final reenteredCode = reenterCodeController.text;

                      if (currentCode != currentAdminCode) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Current admin code is incorrect'),
                          ),
                        );
                        return;
                      } else if (newCode != reenteredCode) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('New codes do not match'),
                          ),
                        );
                        return;
                      }

                      final result = await showConfirmationDialog(
                        context: context,
                        message: 'Do you want to update Admin code?',
                        cancelText: 'No',
                        confirmText: 'Yes',
                      );

                      if (result == true) {
                        final message = getNewPanelCodeMessage(
                          newCode: newCode,
                          adminCode: currentAdminCode ?? '',
                          panelName: panelName,
                        );

                        sendSmsSilently(panelSimNumber, message);

                        // TODO: send this message to panel via SMS or command
                        print("Generated Panel Command: $message");

                        final success = await viewModel.updateAdminCode(
                          panelSimNumber,
                          newCode,
                        );

                        if (success) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => PanelDetailsScreen(
                                    panelSimNumber: panelSimNumber,
                                  ),
                            ),
                          ); // Close dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Admin code updated successfully'),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to update admin code'),
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

/// Panel code message builder
String getNewPanelCodeMessage({
  required String panelName,
  required String adminCode,
  required String newCode,
}) {
  const changeCode = "CHANGE CODE";

  if (panelName == "MULTICOM 4G DIALER") {
    return "< $adminCode $changeCode#00#$newCode-$newCode* >";
  } else if (panelName == "SOLITAIRE 08S GGIP") {
    return "START$adminCode SET PSWD:$changeCode:END";
  } else {
    return "$adminCode$changeCode#$newCode-$newCode* END";
  }
}
