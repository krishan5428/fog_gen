import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

Widget buildContactItem(
  BuildContext context, {
  required IconData icon,
  required String text,
}) {
  return GestureDetector(
    onTap: () {},
    child: Container(
      padding: EdgeInsets.all(15),
      child: Row(
        children: [
          Icon(icon, color: AppColors.colorPrimary, size: 18),
          SizedBox(width: 15),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.colorPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
  );
}
