import 'package:fog_gen_new/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../utils/navigation.dart';
import '../../utils/responsive.dart';
import '../widgets/form_section.dart';

Future<void> forgotPasswordDialog(BuildContext context) async {
  final TextEditingController mobileNumberController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final fontSize = Responsive.fontSize(context);
  final spacingBwtView = Responsive.spacingBwtView(context);

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      String? message; // error or success message
      String? password;

      return StatefulBuilder(
        builder: (ctx, setState) {
          return Dialog(
            backgroundColor: AppColors.lightGrey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Forgot Password",
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FormSection(
                          label: 'Enter Mobile Number',
                          controller: mobileNumberController,
                          keyboardType: TextInputType.number,
                          maxLength: 10,
                          validator: (value) {
                            if (value == null || value.trim().length != 10) {
                              return 'Enter a valid 10-digit mobile number';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: spacingBwtView),

                        if (message != null) ...[
                          Text(
                            message!,
                            style: TextStyle(
                              fontSize: fontSize * 0.9,
                              color:
                                  Colors.red,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          CustomNavigation.instance.pop(dialogContext);
                        },
                        child: const Text(
                          "Close",
                          style: TextStyle(color: AppColors.colorPrimary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;

                          final mobile = mobileNumberController.text.trim();
                          // final db = Provider.of<AppDatabase>(
                          //   context,
                          //   listen: false,
                          // );
                          // final user = await db.userDao.getUserByMobile(mobile);

                          // if (user == null) {
                          //   setState(() {
                          //     password = null;
                          //     message =
                          //         'No account found for this mobile number.';
                          //   });
                          // } else {
                          // setState(() {
                          //   password = user.password;
                          //   message =
                          //       'Account found for $mobile. Password will be sent via SMS.';
                          // });

                          try {
                            // await ProgressDialogWithMessage.show(
                            //   context,
                            //   messages: [
                            //     "Your fog_gen_new Account password is: ${user.password}",
                            //   ],
                            //   panelSimNumber: user.mobileNumber,
                            // );
                            // await SendSms(
                            //   mobile,
                            //   "Your FireNex Account password is: ${user.password}",
                            // );

                            // Close dialog after success
                            Navigator.of(dialogContext).pop();
                            CustomNavigation.instance.pop(context);

                            // Optional: show a snackbar after closing
                            SnackBarHelper.showSnackBar(
                              context,
                              "Password sent successfully to $mobile",
                            );
                          } catch (e) {
                            setState(() {
                              message = 'Failed to send SMS: $e';
                            });
                          }
                          // }
                        },

                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.colorPrimary,
                          foregroundColor: AppColors.white,
                        ),
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
