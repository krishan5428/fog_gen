import 'package:fire_nex/presentation/dialog/url_dialog.dart';
import 'package:fire_nex/utils/navigation.dart';
import 'package:fire_nex/utils/snackbar_helper.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../constants/app_colors.dart';
import '../../constants/urls.dart';

class SmsPermissionDialog {
  static Future<void> show(BuildContext parentContext) async {
    showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: AppColors.lightGrey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: EdgeInsets.all(
            20,
          ), // removes default padding from edges
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: SizedBox(
              width: MediaQuery.of(dialogContext).size.width,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "SMS Permission Required",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "This app requires SMS permission because it communicates "
                    "with your security panel only via SMS.\n\n"
                    "The app uses SMS solely to send predefined commands (arm, disarm, reset, status) to your panel and to receive status updates\n"
                    "SMS is never used for personal messaging, marketing, or any other purpose.",
                    style: TextStyle(fontSize: 14, color: AppColors.textGrey),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "We adhere to ",
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textGrey,
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          text: 'Google Compliance Policy',
                          style: Theme.of(
                            dialogContext,
                          ).textTheme.bodySmall!.copyWith(
                            color: AppColors.colorPrimary,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer:
                              TapGestureRecognizer()
                                ..onTap = () {
                                  showUrlDialog(
                                    dialogContext,
                                    googleComplianceUrl,
                                    'Google Compliance Policy',
                                  );
                                },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed:
                            () => CustomNavigation.instance.pop(dialogContext),
                        child: const Text(
                          "Deny",
                          style: TextStyle(color: AppColors.colorPrimary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.colorPrimary,
                          foregroundColor: AppColors.white,
                        ),
                        onPressed: () async {
                          CustomNavigation.instance.pop(dialogContext);
                          final status = await Permission.sms.request();

                          if (status.isGranted) {
                            SnackBarHelper.showSnackBar(
                              dialogContext,
                              'SMS permission granted',
                            );
                          } else {
                            SnackBarHelper.showSnackBar(
                              dialogContext,
                              'SMS permission denied',
                            );
                          }
                        },
                        child: const Text("Allow"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
