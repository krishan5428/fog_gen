import 'package:flutter/material.dart';
import 'package:fire_nex/constants/app_colors.dart';

class ProgressDialog {
  static bool _isShowing = false;

  static void show(
    BuildContext context, {
    String message = 'Please wait, processing your request...',
  }) {
    if (_isShowing) return;
    _isShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              backgroundColor: AppColors.white,
              content: Row(
                children: [
                  const CircularProgressIndicator(color: AppColors.colorPrimary,),
                  const SizedBox(width: 20),
                  Expanded(child: Text(message)),
                ],
              ),
            ),
          ),
    );
  }

  static void dismiss(BuildContext context) {
    if (_isShowing) {
      _isShowing = false;
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
