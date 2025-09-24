import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

class TimerItem extends StatelessWidget {
  final String title;
  final String entryTimeLabel;
  final String entryTimeText;
  final VoidCallback onEditUpdate;

  final Widget? entryTimeLabelWidget;

  const TimerItem({
    super.key,
    required this.title,
    required this.entryTimeLabel,
    required this.entryTimeText,
    required this.onEditUpdate,
    this.entryTimeLabelWidget,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasText = entryTimeText.isNotEmpty;

    return Container(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 17),
      decoration: BoxDecoration(
        border: Border.all(width: 1.5, color: AppColors.colorPrimary),
        color: AppColors.white,
        borderRadius: const BorderRadius.all(Radius.circular(6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.colorPrimary,
                ),
              ),
              TextButton(
                onPressed: onEditUpdate,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.colorPrimary,
                  side: const BorderSide(color: AppColors.colorPrimary),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'UPDATE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        color: AppColors.colorPrimary,
                      ),
                    ),
                    Icon(
                      Icons.arrow_right,
                      size: 18,
                      color: AppColors.colorPrimary,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          Row(
            children: [
              entryTimeLabelWidget ??
                  Text(
                    entryTimeLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.colorAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              if (hasText)
                Text(
                  entryTimeText,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.colorAccent,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
