import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

class AutomationItemCard extends StatelessWidget {
  final bool isEnabled;
  final String title;
  final String entryTimeLabel;
  final String entryTimeText;
  final VoidCallback onEditUpdate;
  final ValueChanged<bool>? onToggle;

  const AutomationItemCard({
    super.key,
    required this.isEnabled,
    required this.title,
    required this.entryTimeLabel,
    required this.entryTimeText,
    required this.onEditUpdate,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.textGrey.withAlpha(30),
            borderRadius: BorderRadius.all(Radius.circular(6)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Current Status : ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.colorAccent,
                          ),
                        ),
                        Text(
                          isEnabled ? "ENABLED" : "DISABLED",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.colorPrimary,
                          ),
                        ),
                      ],
                    ),
                    if (onToggle != null)
                      Switch(
                        value: isEnabled,
                        onChanged: onToggle,
                        activeColor: AppColors.colorPrimary,
                      ),
                  ],
                ),
              ),
              Opacity(
                opacity: isEnabled ? 1.0 : 0.4,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    border: Border.all(
                      width: 1.5,
                      color: AppColors.colorPrimary,
                    ),
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
                            onPressed: isEnabled ? onEditUpdate : null,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.colorPrimary,
                              side: const BorderSide(
                                color: AppColors.colorPrimary,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'EDIT/UPDATE',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                                Icon(Icons.arrow_right, size: 18),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            "$entryTimeLabel : ",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                          ),
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
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
