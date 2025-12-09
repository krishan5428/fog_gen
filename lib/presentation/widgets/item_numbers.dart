import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../utils/responsive.dart';

class NumberCard extends StatelessWidget {
  final String number;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showEdit;
  final bool showDelete;

  const NumberCard({
    super.key,
    required this.number,
    this.onEdit,
    this.onDelete,
    this.showEdit = true,
    this.showDelete = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDeleted = number == '0000000000';
    final fontSize = Responsive.fontSize(context);
    final spacingBwtView = Responsive.spacingBwtView(context);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: spacingBwtView,
        vertical: spacingBwtView * 0.2,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 16,
            child: Padding(
              padding: EdgeInsets.all(spacingBwtView / 2),
              child: Text(
                number,
                style: TextStyle(
                  color: AppColors.colorPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize * 1.1,
                ),
              ),
            ),
          ),
          if (showEdit)
            IconButton(
              onPressed: onEdit,
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.litePrimary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.edit,
                  color: AppColors.colorPrimary,
                  size: 18,
                ),
              ),
            ),
          if (showDelete && !isDeleted)
            IconButton(
              onPressed: onDelete,
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.litePrimary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.delete,
                  color: Colors.red,
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
