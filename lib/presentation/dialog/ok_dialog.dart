import 'package:flutter/material.dart';

Future<void> showInfoDialog({
  required BuildContext context,
  required String message,
}) async {
  return showDialog<void>(
    context: context,
    builder:
        (ctx) => AlertDialog(
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("OK"),
            ),
          ],
        ),
  );
}
