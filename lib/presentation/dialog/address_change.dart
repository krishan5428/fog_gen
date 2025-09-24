import 'package:flutter/material.dart';
import 'package:fire_nex/utils/silent_sms.dart';

import '../../constants/app_colors.dart';
import '../screens/panel_details.dart';
import '../viewModel/panel_view_model.dart';
import '../widgets/form_section.dart';
import '../widgets/vertical_gap.dart';
import 'confirmation_dialog.dart';

void showChangeAddressDialog(
  BuildContext context,
  String adminCode,
  String panelSimNumber,
  String panelName,
  PanelViewModel viewModel,
) {
  final TextEditingController newAddressController = TextEditingController();

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
                label: 'New Address',
                controller: newAddressController,
                keyboardType: TextInputType.number,
                maxLength: 20,
                validator:
                    (value) => value == null ? 'Enter valid address' : null,
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
                      final newAddress = newAddressController.text;

                      final result = await showConfirmationDialog(
                        context: context,
                        message: 'Do you want to update Address?',
                        cancelText: 'No',
                        confirmText: 'Yes',
                      );

                      if (result == true) {
                        final message = getAddressMessage(
                          newAddress: newAddress,
                          adminCode: adminCode,
                          panelName: panelName,
                        );

                        sendSmsSilently(panelSimNumber, message);

                        // TODO: send this message to panel via SMS or command
                        print("Generated Panel Command: $message");

                        final success = await viewModel.updateAddress(
                          panelSimNumber,
                          newAddress,
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
String getAddressMessage({
  required String panelName,
  required String adminCode,
  required String newAddress,
}) {
  if (panelName == "MULTICOM 4G DIALER") {
    return "< $adminCode SIGNATURE #$newAddress* >";
  } else {
    return "$adminCode NAME ADDRESS #$newAddress* END";
  }
}
