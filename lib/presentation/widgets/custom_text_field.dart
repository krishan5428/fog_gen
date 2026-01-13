import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/app_colors.dart';
import '../../utils/responsive.dart';

class CustomTextField extends StatelessWidget {
  final String hintText;
  final String? errorText;
  final IconData? icon;
  final TextEditingController controller;
  final bool isPassword;
  final bool isNumber;
  final bool isEmail;
  final int maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled; // NEW PARAMETER

  const CustomTextField({
    super.key,
    required this.hintText,
    this.errorText,
    this.icon,
    required this.controller,
    this.isPassword = false,
    this.isNumber = false,
    this.isEmail = false,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.enabled = true, // Default to true
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = Responsive.fontSize(context);

    return TextField(
      controller: controller,
      enabled: enabled, // PASS TO TEXTFIELD
      obscureText: isPassword,
      maxLines: maxLines,
      maxLength: maxLength,
      style: TextStyle(fontSize: fontSize, color: enabled ? Colors.black : Colors.grey),
      keyboardType:
      isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : isEmail
          ? TextInputType.emailAddress
          : TextInputType.text,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: hintText,
        errorText: errorText,
        prefixIcon:
        icon != null ? Icon(icon, color: AppColors.colorAccent) : null,
        labelStyle: const TextStyle(color: AppColors.colorPrimary),
        border: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.colorAccent),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade100, // Visual feedback for disabled state
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.colorPrimary, width: 1.5),
        ),
        counterText: '',
      ),
    );
  }
}