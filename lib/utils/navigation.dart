import 'package:flutter/material.dart';

class CustomNavigation {
  // Private constructor
  CustomNavigation._privateConstructor();

  // Singleton instance
  static final CustomNavigation _instance =
      CustomNavigation._privateConstructor();

  // Public accessor
  static CustomNavigation get instance => _instance;

  void push({required BuildContext context, required Widget screen}) {
    if (!context.mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void pushReplace({required BuildContext context, required Widget screen}) {
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void pushAndRemove({required BuildContext context, required Widget screen}) {
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => screen),
      (route) => false,
    );
  }

  void popAndPush({required BuildContext context, required Widget screen}) {
    if (!context.mounted) return;
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void mayBePop({required BuildContext context}) {
    if (!context.mounted) return;
    Navigator.maybePop(context);
  }

  void pop(BuildContext context) {
    if (!context.mounted) return;
    Navigator.pop(context);
  }

  void popWithResult({required BuildContext context, dynamic result}) {
    if (!context.mounted) return;
    Navigator.pop(context, result);
  }
}
