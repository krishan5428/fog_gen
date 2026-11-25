import 'package:flutter/material.dart';
import 'package:fog_gen_new/constants/app_colors.dart';

class FormSection extends StatelessWidget {
  final String label;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final int? maxLength;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final IconData? prefixIcon;
  final bool readOnly;

  const FormSection({
    super.key,
    required this.label,
    this.keyboardType = TextInputType.text,
    this.controller,
    this.maxLength,
    this.validator,
    this.suffixIcon,
    this.prefixIcon,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      validator: validator,
      readOnly: readOnly,
      showCursor: !readOnly,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        fillColor: readOnly ? const Color(0xFFF0F1F3) : AppColors.white,
        labelStyle: TextStyle(color: AppColors.colorPrimary),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.colorAccent),
        ),
        filled: true,
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.colorPrimary, width: 1),
        ),
      ),
    );
  }
}
