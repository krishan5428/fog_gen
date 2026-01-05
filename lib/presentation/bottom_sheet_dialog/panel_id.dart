import 'package:fog_gen_new/core/responses/socket_repository.dart';
import 'package:fog_gen_new/core/utils/packets.dart';
import 'package:fog_gen_new/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../utils/navigation.dart';
import '../dialog/confirmation_dialog.dart';
import '../dialog/progress.dart';
import '../widgets/form_section.dart';
import '../widgets/vertical_gap.dart';

void showPanelIdDialog(
  BuildContext context,
  String response,
  SocketRepository socketRepository,
) {
  final List<String> extractedValues = getExtractedResponse(response);

  final TextEditingController rvalueController = TextEditingController(
    text: extractedValues.isNotEmpty ? extractedValues[0] : '',
  );
  final TextEditingController lvalueController = TextEditingController(
    text: extractedValues.length > 1 ? extractedValues[1] : '',
  );
  final TextEditingController panelIdController = TextEditingController(
    text: extractedValues.length > 2 ? extractedValues[2] : '',
  );

  String? errorText;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.lightGrey,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return StatefulBuilder(
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
                    "Panel ID",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.colorPrimary,
                    ),
                  ),
                  VerticalSpace(height: 20),
                  FormSection(
                    label: 'R Value',
                    controller: rvalueController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    validator:
                        (value) =>
                            value == null || value.length < 6
                                ? 'Enter valid R Value'
                                : null,
                  ),
                  VerticalSpace(),
                  FormSection(
                    label: 'L Value',
                    controller: lvalueController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    validator:
                        (value) =>
                            value == null || value.length < 6
                                ? 'Enter valid L Value'
                                : null,
                  ),
                  VerticalSpace(),
                  FormSection(
                    label: 'Panel ID',
                    controller: panelIdController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    validator:
                        (value) =>
                            value == null || value.length < 6
                                ? 'Enter valid Panel ID'
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
                          final rValue = rvalueController.text.trim();
                          final lValue = lvalueController.text.trim();
                          final panelId = panelIdController.text.trim();

                          if (rValue.isEmpty ||
                              lValue.isEmpty ||
                              panelId.isEmpty) {
                            setState(() {
                              errorText = 'All fields must be filled!';
                            });
                            return;
                          }

                          final result = await showConfirmationDialog(
                            context: context,
                            message: 'Do you want to update Panel ID data?',
                            cancelText: 'No',
                            confirmText: 'Yes',
                          );

                          if (result == true) {
                            ProgressDialog.show(context, message: 'Updating Panel ID data...');
                            final response = await socketRepository
                                .sendPacketSR1(
                                  Packets.getPacket(
                                    isReadPacket: false,
                                    args: ["001", rValue, lValue, panelId],
                                  ),
                                );
                            ProgressDialog.dismiss(context);
                            if (response == 'S*001#0*E') {
                              CustomNavigation.instance.pop(context);
                              SnackBarHelper.showSnackBar(
                                context,
                                'Submitted successfully',
                              );
                            } else {
                              CustomNavigation.instance.pop(context);
                              SnackBarHelper.showSnackBar(context, 'Error');
                            }
                          } else {
                            CustomNavigation.instance.pop(context);
                            SnackBarHelper.showSnackBar(context, 'Operation Cancelled');
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
    },
  );
}

List<String> getExtractedResponse(String response) {
  if (response.isEmpty) return [];

  final cleaned = response
      .replaceAll(RegExp(r'^S\*.*?#'), '')
      .replaceAll('*E', '');

  final parts = cleaned.split('#');
  return parts.where((part) => RegExp(r'^\d+$').hasMatch(part)).toList();
}
