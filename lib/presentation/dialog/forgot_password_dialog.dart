import 'package:fire_nex/utils/silent_sms.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../data/database/app_database.dart';
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
          return AlertDialog(
            backgroundColor: AppColors.white,
            title: Text(
              "Forgot Password",
              style: TextStyle(fontSize: fontSize * 1.1),
            ),
            content: Form(
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

                  // Show message area
                  if (message != null) ...[
                    Text(
                      message!,
                      style: TextStyle(
                        fontSize: fontSize * 0.9,
                        color: password == null ? Colors.red : Colors.green,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  "Close",
                  style: TextStyle(
                    fontSize: fontSize,
                    color: AppColors.colorAccent,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: AppColors.colorPrimary,
                  textStyle: TextStyle(fontSize: fontSize),
                ),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;

                  final mobile = mobileNumberController.text.trim();
                  final db = Provider.of<AppDatabase>(context, listen: false);
                  final user = await db.userDao.getUserByMobile(mobile);

                  if (user == null) {
                    setState(() {
                      password = null;
                      message = 'No account found for this mobile number.';
                    });
                  } else {
                    setState(() {
                      password = user.password;
                      message =
                          'Account found for $mobile. Password will be sent via SMS.';
                    });

                    try {
                      // ✅ Use your silent_sms.dart function only
                      await sendSms(
                        mobile,
                        "Your FireNex Account password is: ${user.password}",
                      );

                      // Close dialog after success
                      Navigator.of(dialogContext).pop();

                      // Optional: show a snackbar after closing
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Password sent successfully to $mobile',
                          ),
                        ),
                      );
                    } catch (e) {
                      setState(() {
                        message = 'Failed to send SMS: $e';
                      });
                    }
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          );
        },
      );
    },
  );
}
