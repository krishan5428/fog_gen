import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../viewModel/intrusion_view_model.dart';
import '../widgets/form_section.dart';
import '../widgets/vertical_gap.dart';
import 'confirmation_dialog.dart';

Future<bool?> showAddNumberDialog(
  BuildContext parent,
  String panelSimNumber,
  String adminMobileNumber,
  IntrusionViewModel viewModel,
) async {
  final TextEditingController newIntNumber = TextEditingController();

  return showDialog<bool>(
    context: parent,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
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
                label: 'Add new Number',
                controller: newIntNumber,
                keyboardType: TextInputType.number,
                maxLength: 10,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter valid number';
                  }
                  if (value == adminMobileNumber) {
                    return 'Number cannot be the Admin mobile number';
                  }
                  if (value == panelSimNumber) {
                    return 'Number cannot be the Panel SIM number';
                  }
                  return null;
                },
              ),
              VerticalSpace(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: AppColors.colorAccent),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final newNumber = newIntNumber.text.trim();

                      if (newNumber.isEmpty ||
                          newNumber == adminMobileNumber ||
                          newNumber == panelSimNumber) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid number'),
                          ),
                        );
                        return;
                      }

                      final existingNumbers = await viewModel
                          .getIntrusionNumbersByPanelSimNumber(panelSimNumber);

                      final alreadyExists = existingNumbers.any(
                        (entry) => entry.intrusionNumber == newNumber,
                      );

                      if (alreadyExists) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                            content: Text('This number already exists'),
                          ),
                        );
                        return;
                      }

                      final result = await showConfirmationDialog(
                        context: dialogContext,
                        message: 'Do you want to Add number?',
                        cancelText: 'No',
                        confirmText: 'Yes',
                      );

                      if (result == true) {
                        final success = await viewModel.insertIntrusionNumber(
                          panelSimNumber,
                          newNumber,
                        );

                        if (success) {
                          Navigator.pop(dialogContext, true); // Success
                        } else {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Failed to update Intrusion Number',
                              ),
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
