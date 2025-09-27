import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.buttonText,
    this.backgroundColor = AppColors.colorPrimary,
    this.foregroundColor = AppColors.suffleWhite,
    this.onPressed,
    this.icon,
    this.buttonTextSize = 14.0,
  });

  final String buttonText;
  final double? buttonTextSize;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: 2,
        ),
        onPressed: onPressed,
        child:
            icon == null
                ? Text(
                  buttonText.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: buttonTextSize,
                  ),
                )
                : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      buttonText.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: buttonTextSize,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
