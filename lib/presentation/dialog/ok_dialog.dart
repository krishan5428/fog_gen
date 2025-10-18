import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../utils/navigation.dart';

Future<void> showInfoDialog({
  required BuildContext context,
  required String message,
  VoidCallback? onOk,
}) async {
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      return Dialog(
        backgroundColor: AppColors.lightGrey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      if (onOk != null) {
                        onOk();
                      } else {
                        CustomNavigation.instance.pop(ctx);
                      }
                    },
                    child: const Text(
                      "OK",
                      style: TextStyle(color: AppColors.colorPrimary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
