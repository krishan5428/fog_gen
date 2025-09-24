import 'package:flutter/material.dart';
import 'package:fire_nex/constants/app_colors.dart';

class ImageUploadWidget extends StatelessWidget {
  final String captureText;
  final String uploadText;
  final VoidCallback? onTap;
  final ImageProvider? image;
  final bool isVisible;

  const ImageUploadWidget({
    super.key,
    required this.captureText,
    required this.uploadText,
    this.onTap,
    this.image,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 10),
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.colorPrimary),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          if (image != null)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image(image: image!, fit: BoxFit.cover),
              ),
            ),
          Center(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(captureText, style: const TextStyle(fontSize: 10)),
                  const SizedBox(height: 3),
                  Text(
                    uploadText,
                    style: const TextStyle(
                      color: AppColors.colorPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
