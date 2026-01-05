import 'package:fog_gen_new/core/responses/socket_repository.dart';
import 'package:fog_gen_new/core/utils/packets.dart';
import 'package:fog_gen_new/presentation/widgets/custom_text_field.dart';
import 'package:fog_gen_new/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../utils/navigation.dart';
import '../dialog/confirmation_dialog.dart';
import '../dialog/progress.dart';
import '../widgets/vertical_gap.dart';

void showDestinationIPUpdateData(
  BuildContext context,
  String response,
  SocketRepository socketRepository,
  String title,
) {
  final List<String> extractedValues = getExtractedResponse(response);
  debugPrint('extracted values list: $extractedValues');

  final Map<String, String> numberToLetter = {
    '1': 'DISABLE',
    '2': 'IP',
    '3': 'GPRS',
    '4': 'IP+GPRS',
  };

  final Map<String, String> letterToNumber = {
    'DISABLE': '1',
    'IP': '2',
    'GPRS': '3',
    'IP+GPRS': '4',
  };

  String selectedLetter =
      numberToLetter[extractedValues.length > 1 ? extractedValues[1] : '1'] ??
      'DISABLE';

  final TextEditingController ip1Controller = TextEditingController(
    text: extractedValues.length > 2 ? extractedValues[2] : '',
  );
  final TextEditingController port1Controller = TextEditingController(
    text: extractedValues.length > 3 ? extractedValues[3] : '',
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

            final ip = ip1Controller.text.trim();
            final port = port1Controller.text.trim();
            final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');

            if (!ipRegex.hasMatch(ip)) errorMessages.add('Invalid IP address');

            final portNumber = int.tryParse(port);
            if (portNumber == null || portNumber < 1 || portNumber > 65535) {
              errorMessages.add('Invalid port number');
            }

            setState(() {});
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
                  Text(
                    "UPDATE $title",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.colorPrimary,
                    ),
                  ),
                  VerticalSpace(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      border: Border.all(color: AppColors.colorPrimary),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: DropdownButton<String>(
                      value: selectedLetter,
                      isExpanded: true,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w600,
                        color: AppColors.colorPrimary,
                      ),
                      underline: const SizedBox(),
                      hint: Text('$title Server'),
                      items:
                          ['DISABLE', 'IP', 'GPRS', 'IP+GPRS']
                              .map(
                                (option) => DropdownMenuItem(
                                  value: option,
                                  child: Text(option),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedLetter = value);
                        }
                      },
                    ),
                  ),
                  VerticalSpace(),
                  CustomTextField(
                    hintText: '$title Server IP',
                    controller: ip1Controller,
                    maxLength: 15,
                    isNumber: true,
                  ),
                  VerticalSpace(),
                  CustomTextField(
                    hintText: '$title Port Number',
                    controller: port1Controller,
                    isNumber: true,
                    maxLength: 5,
                  ),
                  VerticalSpace(),
                  if (errorMessages.isNotEmpty)
                    Column(
                      children:
                          errorMessages
                              .map(
                                (e) => Padding(
                                  padding: const EdgeInsets.only(top: 6.0),
                                  child: Text(
                                    e,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
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

                          if (errorMessages.isNotEmpty) return;

                          final confirm = await showConfirmationDialog(
                            context: context,
                            message: 'Do you want to update $title settings?',
                            cancelText: 'No',
                            confirmText: 'Yes',
                          );

                          debugPrint('confirm: $confirm');

                          if (confirm == true) {
                            debugPrint('entered 1');
                            final selectedNumber =
                                letterToNumber[selectedLetter] ?? '1';

                            String type = "";

                            if (title == 'CMS 1') {
                              type = "001";
                            } else if (title == "CMS 2") {
                              type = "002";
                            } else if (title == "PUSH SERVER") {
                              type = "003";
                            }
                            debugPrint('entered 2: $title');
                            debugPrint('entered 3: $type');

                            if (type.isNotEmpty) {
                              debugPrint('entered');
                              ProgressDialog.show(
                                context,
                                message: 'Updating $title settings...',
                              );
                              final result = await socketRepository
                                  .sendPacketSR1(
                                    Packets.getPacket(
                                      isReadPacket: false,
                                      args: [
                                        "003",
                                        type,
                                        selectedNumber,
                                        ip1Controller.text.trim(),
                                        port1Controller.text.trim(),
                                      ],
                                    ),
                                  );
                              ProgressDialog.dismiss(context);

                              CustomNavigation.instance.pop(context);

                              if (result.contains('#0*E')) {
                                SnackBarHelper.showSnackBar(
                                  context,
                                  'Submitted successfully',
                                );
                              } else {
                                SnackBarHelper.showSnackBar(context, 'Error');
                              }
                            } else {
                              SnackBarHelper.showSnackBar(
                                context,
                                'Something went wrong!',
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
