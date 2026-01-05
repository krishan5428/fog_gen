import 'package:fog_gen_new/utils/navigation.dart';
import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../widgets/open_web_page.dart';

void showUrlDialog(BuildContext pContext, String url, String title) {
  showDialog(
    context: pContext,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: AppColors.lightGrey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Choose an action for this link:',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      // Clipboard.setData(ClipboardData(text: url));
                      CustomNavigation.instance.pop(dialogContext);
                      // SnackBarHelper.showSnackBar(
                      //   pContext,
                      //   'Link copied to clipboard',
                      // );
                    },
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: AppColors.colorPrimary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      CustomNavigation.instance.pop(dialogContext);
                      openWebPage(pContext, url);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.colorPrimary,
                      foregroundColor: AppColors.white,
                    ),
                    child: const Text("Open Link"),
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
