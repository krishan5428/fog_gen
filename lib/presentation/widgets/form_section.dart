import 'package:flutter/material.dart';
import 'package:fire_nex/constants/app_colors.dart';

class FormSection extends StatelessWidget {
  final String label;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final int? maxLength;
  final String? Function(String?)? validator;

  const FormSection({
    super.key,
    required this.label,
    this.keyboardType = TextInputType.text,
    this.controller,
    this.maxLength,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        fillColor: AppColors.white,
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
