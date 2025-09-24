import 'package:fire_nex/utils/responsive.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class SnackBarHelper {
  static void showSnackBar(BuildContext context, String message) {
    _showSnackBar(context, message);
  }

  static void _showSnackBar(BuildContext context, String message) {
    final fontSize = Responsive.fontSize(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: AppColors.white, fontSize: fontSize),
        ),
        // backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.colorPrimary,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
