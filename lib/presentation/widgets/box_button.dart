import 'package:fog_gen_new/constants/app_colors.dart';
import 'package:flutter/material.dart';

class GridOption {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  GridOption({required this.title, required this.icon, required this.onTap});
}

class GridBox extends StatelessWidget {
  final GridOption option;
  const GridBox({super.key, required this.option});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: option.onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.colorPrimary.withOpacity(0.2),
        highlightColor: AppColors.colorPrimary.withOpacity(0.1),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(option.icon, size: 40, color: AppColors.colorPrimary),
              const SizedBox(height: 12),
              Text(
                option.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.colorPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
