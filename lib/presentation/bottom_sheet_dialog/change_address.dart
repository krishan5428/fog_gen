import 'package:flutter/material.dart';
import 'package:fire_nex/utils/silent_sms.dart';

import '../../constants/app_colors.dart';
import '../../constants/strings.dart';
import '../dialog/confirmation_dialog.dart';
import '../screens/panel_details.dart';
import '../viewModel/panel_view_model.dart';
import '../widgets/form_section.dart';
import '../widgets/vertical_gap.dart';

void showChangeAddressBottomSheet(
  BuildContext context,
  String adminCode,
  String panelSimNumber,
  String panelName,
  PanelViewModel viewModel,
) {
  final TextEditingController newAddressController = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    // for full height when keyboard opens
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
                "Update Address",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.colorPrimary,
                ),
              ),
              VerticalSpace(height: 20),
              FormSection(
                label: 'New Address',
                controller: newAddressController,
                keyboardType: TextInputType.number,
                maxLength: 40,
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Enter valid address'
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
                      final newAddress = newAddressController.text.trim();

                      final result = await showConfirmationDialog(
                        context: context,
                        message: 'Do you want to update Address?',
                        cancelText: 'No',
                        confirmText: 'Yes',
                      );

                      if (result == true) {
                        final message = getAddressMessage(
                          newAddress: newAddress,
                          panelName: panelName,
                        );

                        sendSmsSilently(panelSimNumber, message);

                        print("Generated Panel Command: $message");

                        final success = await viewModel.updateAddress(
                          panelSimNumber,
                          newAddress,
                        );

                        if (success) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => PanelDetailsScreen(
                                    panelSimNumber: panelSimNumber,
                                  ),
                            ),
                          );
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
  required String newAddress,
}) {
  if (neuronPanels.contains(panelName)) {
    return "< 1234 SIGNATURE #$newAddress* >";
  } else if (fourGComPanels.contains(panelName)) {
    return "SECURICO 1234 ADD SIGNATURE $newAddress* END";
  } else {
    return "";
  }
}
