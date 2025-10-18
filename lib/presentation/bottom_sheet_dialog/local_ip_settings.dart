import 'package:fire_nex/core/responses/socket_repository.dart';
import 'package:fire_nex/core/utils/packets.dart';
import 'package:fire_nex/presentation/widgets/custom_text_field.dart';
import 'package:fire_nex/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../utils/navigation.dart';
import '../dialog/confirmation_dialog.dart';
import '../dialog/progress.dart';
import '../widgets/vertical_gap.dart';

void showLocalIpSettings(
  BuildContext context,
  String response,
  SocketRepository socketRepository,
) {
  final List<String> extractedValues = getExtractedResponse(response);

  final TextEditingController deviceIPController = TextEditingController(
    text: extractedValues.isNotEmpty ? extractedValues[0] : '',
  );
  final TextEditingController subnetMaskController = TextEditingController(
    text: extractedValues.length > 1 ? extractedValues[1] : '',
  );
  final TextEditingController defaultGatewayController = TextEditingController(
    text: extractedValues.length > 2 ? extractedValues[2] : '',
  );
  final TextEditingController dns1Controller = TextEditingController(
    text: extractedValues.length > 3 ? extractedValues[3] : '',
  );
  final TextEditingController dns2Controller = TextEditingController(
    text: extractedValues.length > 4 ? extractedValues[4] : '',
  );
  final TextEditingController portController = TextEditingController(
    text: extractedValues.length > 5 ? extractedValues[5] : '',
  );

  List<String> errorMessages = [];

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
          void validateFields() {
            errorMessages.clear();

            final deviceIP = deviceIPController.text.trim();
            final subnetMask = subnetMaskController.text.trim();
            final defaultGateway = defaultGatewayController.text.trim();
            final dns1 = dns1Controller.text.trim();
            final dns2 = dns2Controller.text.trim();
            final port = portController.text.trim();

            // Simple IP regex
            final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');

            if (!ipRegex.hasMatch(deviceIP)) {
              errorMessages.add('Invalid Device IP');
            }
            if (!ipRegex.hasMatch(subnetMask)) {
              errorMessages.add('Invalid Subnet Mask');
            }
            if (!ipRegex.hasMatch(defaultGateway)) {
              errorMessages.add('Invalid Default Gateway');
            }
            if (!ipRegex.hasMatch(dns1)) errorMessages.add('Invalid DNS 1');
            if (!ipRegex.hasMatch(dns2)) errorMessages.add('Invalid DNS 2');

            final portNumber = int.tryParse(port);
            if (portNumber == null || portNumber < 1 || portNumber > 65535) {
              errorMessages.add('Invalid Port Number');
            }
          }

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
                    "Local IP Settings",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.colorPrimary,
                    ),
                  ),
                  VerticalSpace(height: 20),
                  CustomTextField(
                    hintText: 'Device IP',
                    controller: deviceIPController,
                    isNumber: true,
                    maxLength: 15,
                  ),
                  VerticalSpace(),
                  CustomTextField(
                    hintText: 'Subnet Mask',
                    controller: subnetMaskController,
                    maxLength: 15,
                    isNumber: true,
                  ),
                  VerticalSpace(),
                  CustomTextField(
                    hintText: 'Default Gateway',
                    controller: defaultGatewayController,
                    isNumber: true,
                    maxLength: 15,
                  ),
                  VerticalSpace(),
                  CustomTextField(
                    hintText: 'DNS 1',
                    controller: dns1Controller,
                    isNumber: true,
                    maxLength: 15,
                  ),
                  VerticalSpace(),
                  CustomTextField(
                    hintText: 'DNS 2',
                    controller: dns2Controller,
                    isNumber: true,
                    maxLength: 15,
                  ),
                  VerticalSpace(),
                  CustomTextField(
                    hintText: 'Port Number',
                    controller: portController,
                    isNumber: true,
                    maxLength: 5,
                  ),
                  // Error display at bottom
                  if (errorMessages.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Column(
                        children:
                            errorMessages
                                .map(
                                  (e) => Text(
                                    e,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                                .toList(),
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
                          validateFields();
                          setState(() {});

                          if (errorMessages.isNotEmpty) return;

                          final result = await showConfirmationDialog(
                            context: context,
                            message: 'Do you want to update Local IP settings?',
                            cancelText: 'No',
                            confirmText: 'Yes',
                          );

                          if (result == true) {
                            ProgressDialog.show(
                              context,
                              message: 'Updating Local IP data...',
                            );

                            final response = await socketRepository
                                .sendPacketSR1(
                                  Packets.getPacket(
                                    isReadPacket: false,
                                    args: [
                                      "002",
                                      deviceIPController.text.trim(),
                                      subnetMaskController.text.trim(),
                                      defaultGatewayController.text.trim(),
                                      dns1Controller.text.trim(),
                                      dns2Controller.text.trim(),
                                      portController.text.trim(),
                                    ],
                                  ),
                                );

                            ProgressDialog.dismiss(context);
                            CustomNavigation.instance.pop(context);
                            if (response.contains('#0*E')) {
                              SnackBarHelper.showSnackBar(
                                context,
                                'Submitted successfully',
                              );
                            } else {
                              SnackBarHelper.showSnackBar(context, 'Error');
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
    },
  );
}

List<String> getExtractedResponse(String response) {
  if (response.isEmpty) return [];

  // Remove the leading "S*002#" (anything before the first #) and trailing "*E"
  final cleaned = response
      .replaceAll(RegExp(r'^S\*[^#]*#'), '')
      .replaceAll('*E', '');

  // Split by '#' to get each field
  final parts = cleaned.split('#');

  // Remove any empty strings
  return parts.where((part) => part.isNotEmpty).toList();
}
