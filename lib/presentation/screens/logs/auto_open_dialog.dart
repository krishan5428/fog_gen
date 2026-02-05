import 'dart:async';
import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';


class AutoOpenDialog extends StatefulWidget {
  const AutoOpenDialog({super.key});

  @override
  _AutoOpenDialogState createState() => _AutoOpenDialogState();
}

class _AutoOpenDialogState extends State<AutoOpenDialog> {
  int _timeLeft = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          // Time is up
          timer.cancel();
          // Pop with TRUE to indicate we should open the file
          Navigator.of(context).pop(true);
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("File Saved Successfully"),
      content: Text("Opening file in $_timeLeft seconds..."),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel',
              style: TextStyle(color: AppColors.colorPrimary)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.colorPrimary,
            foregroundColor: AppColors.white,
          ),
          child: const Text("Open Now"),
        ),
      ],
    );
  }
}
