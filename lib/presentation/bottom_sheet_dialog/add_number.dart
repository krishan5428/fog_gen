import 'package:flutter/material.dart';
import 'package:fire_nex/presentation/dialog/confirmation_dialog.dart';
import 'package:fire_nex/presentation/viewModel/panel_view_model.dart';
import 'package:fire_nex/utils/silent_sms.dart';

import '../../constants/app_colors.dart';
import '../../constants/strings.dart';
import '../../data/database/app_database.dart';
import '../widgets/form_section.dart';

Future<bool?> showAddNumberBottomSheet(
  BuildContext parent,
  PanelData panel,
  int index,
  PanelViewModel viewModel, {
  required List<String> existingNumbers,
}) async {
  final TextEditingController newIntNumber = TextEditingController();
  String? errorText; // for showing error inside the bottom sheet

  return showModalBottomSheet<bool>(
    context: parent,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext sheetContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                  Text(
                    neuronPanels.contains(panel.panelName)
                        ? "Add Number for MOBILE NUMBER ${(index + 1).toString().padLeft(2, '0')}" // increment index for NEURON
                        : "Add Number for USER${index.toString().padLeft(2, '0')}",
                    // keep index as-is
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.colorPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FormSection(
                    label: 'Add new Number',
                    controller: newIntNumber,
                    keyboardType: TextInputType.number,
                    maxLength: 10,
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
                        onPressed: () => Navigator.pop(sheetContext, false),
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
                          final newNumber = newIntNumber.text.trim();
                          final normalizedNewNumber =
                              newNumber.replaceAll(RegExp(r'\D'), '').trim();
                          final normalizedExisting =
                              existingNumbers
                                  .map(
                                    (e) =>
                                        e.replaceAll(RegExp(r'\D'), '').trim(),
                                  )
                                  .toList();

                          // Check length
                          if (normalizedNewNumber.length != 10) {
                            setState(() {
                              errorText = 'Number must be exactly 10 digits';
                            });
                            return;
                          }

                          if (newNumber == "1234567890") {
                            setState(() {
                              errorText = 'This number is not allowed';
                            });
                            return;
                          }

                          if (normalizedNewNumber.isEmpty ||
                              normalizedNewNumber == panel.adminMobileNumber ||
                              normalizedNewNumber == panel.panelSimNumber ||
                              normalizedExisting.contains(
                                normalizedNewNumber,
                              )) {
                            setState(() {
                              errorText =
                                  'This number is already used, please use a DIFFERENT NUMBER!';
                            });
                            return;
                          }

                          // ✅ Await confirmation dialog
                          final confirm = await showConfirmationDialog(
                            context: sheetContext,
                            message: 'Do you want to add/update this number?',
                          );

                          if (confirm == true) {
                            final success = await viewModel.updateMobileNumber(
                              panel.panelSimNumber,
                              newNumber,
                              index,
                            );

                            if (success) {
                              final message = getMobileNumberMessages(
                                newNumber: newNumber,
                                panel: panel,
                                index: index,
                              );

                              if (message.isNotEmpty &&
                                  panel.panelSimNumber.trim().isNotEmpty) {
                                debugPrint('sms executed');
                                await sendSmsSilently(
                                  panel.panelSimNumber,
                                  message,
                                );
                              }

                              ScaffoldMessenger.of(parent).showSnackBar(
                                const SnackBar(
                                  content: Text('Number added successfully!'),
                                  duration: Duration(seconds: 2),
                                ),
                              );

                              Navigator.pop(sheetContext, true);
                            } else {
                              setState(() {
                                errorText =
                                    'Failed to update Mobile Number in database';
                              });
                            }
                          }
                        },
                        child: const Text("Submit"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

String getMobileNumberMessages({
  required PanelData panel,
  required String newNumber,
  required int index,
}) {
  if (neuronPanels.contains(panel.panelName)) {
    index += 1;
    if (index == 2) {
      return '''
< 1234 TEL NO
#01-+91${panel.adminMobileNumber}*
#02-+91$newNumber*
#03-+91${panel.mobileNumber2}*
#04-+91${panel.mobileNumber3}*
#05-+91${panel.mobileNumber4}*
>
''';
    } else if (index == 3) {
      return '''
< 1234 TEL NO
#01-+91${panel.adminMobileNumber}*
#02-+91${panel.mobileNumber1}*
#03-+91$newNumber*
#04-+91${panel.mobileNumber3}*
#05-+91${panel.mobileNumber4}*
>
''';
    } else if (index == 4) {
      return '''
< 1234 TEL NO
#01-+91${panel.adminMobileNumber}*
#02-+91${panel.mobileNumber1}*
#03-+91${panel.mobileNumber2}*
#04-+91$newNumber*
#05-+91${panel.mobileNumber4}*
>
''';
    } else if (index == 5) {
      return '''
< 1234 TEL NO
#01-+91${panel.adminMobileNumber}*
#02-+91${panel.mobileNumber1}*
#03-+91${panel.mobileNumber2}*
#04-+91${panel.mobileNumber3}*
#05-+91$newNumber*
>
''';
    } else if (index == 6) {
      return '''
< 1234 TEL NO
#06-+91$newNumber*
#07-+91${panel.mobileNumber6}*
#08-+91${panel.mobileNumber7}*
#09-+91${panel.mobileNumber8}*
#10-+91${panel.mobileNumber9}*
>
''';
    } else if (index == 7) {
      return '''
< 1234 TEL NO
#06-+91${panel.mobileNumber5}*
#07-+91$newNumber*
#08-+91${panel.mobileNumber7}*
#09-+91${panel.mobileNumber8}*
#10-+91${panel.mobileNumber9}*
>
''';
    } else if (index == 8) {
      return '''
< 1234 TEL NO
#06-+91${panel.mobileNumber5}*
#07-+91${panel.mobileNumber6}*
#08-+91$newNumber*
#09-+91${panel.mobileNumber8}*
#10-+91${panel.mobileNumber9}*
>
''';
    } else if (index == 9) {
      return '''
< 1234 TEL NO
#06-+91${panel.mobileNumber5}*
#07-+91${panel.mobileNumber6}*
#08-+91${panel.mobileNumber7}*
#09-+91$newNumber*
#10-+91${panel.mobileNumber9}*
>
''';
    } else if (index == 10) {
      return '''
< 1234 TEL NO
#06-+91${panel.mobileNumber5}*
#07-+91${panel.mobileNumber6}*
#08-+91${panel.mobileNumber7}*
#09-+91${panel.mobileNumber8}*
#10-+91$newNumber*
>
''';
    } else {
      return "";
    }
  } else if (fourGComPanels.contains(panel.panelName)) {
    return "SECURICO 1234 ADD USER${index.toString().padLeft(2, '0')} +91-$newNumber END";
  } else {
    return "";
  }
}
