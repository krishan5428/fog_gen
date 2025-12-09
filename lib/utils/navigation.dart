import 'package:flutter/material.dart';

class CustomNavigation {
  // Private constructor
  CustomNavigation._privateConstructor();

  // Singleton instance
  static final CustomNavigation _instance =
  CustomNavigation._privateConstructor();

  // Public accessor
  static CustomNavigation get instance => _instance;

  // Push a new screen and get a result (supports await and null safety)
  Future<T?> push<T>({
    required BuildContext context,
    required Widget screen,
  }) {
    if (!context.mounted) return Future.value(null);
    return Navigator.push<T>(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  // Push replacement screen and return a result
  Future<T?> pushReplace<T>({
    required BuildContext context,
    required Widget screen,
    T? result,
  }) {
    if (!context.mounted) return Future.value(null);
    return Navigator.pushReplacement<T, T>(
      context,
      MaterialPageRoute(builder: (_) => screen),
      result: result,
    );
  }

  // Push and remove all screens below, with result
  Future<T?> pushAndRemove<T>({
    required BuildContext context,
    required Widget screen,
  }) {
    if (!context.mounted) return Future.value(null);
    return Navigator.pushAndRemoveUntil<T>(
      context,
      MaterialPageRoute(builder: (_) => screen),
          (route) => false,
    );
  }

  // Pop current and then push new screen (returns result of pushed screen)
  Future<T?> popAndPush<T>({
    required BuildContext context,
    required Widget screen,
  }) {
    if (!context.mounted) return Future.value(null);
    Navigator.pop(context);
    // Return the result from new push
    return Navigator.push<T>(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  // Maybe pop current screen
  void mayBePop({required BuildContext context}) {
    if (!context.mounted) return;
    Navigator.maybePop(context);
  }

  // Pop current screen
  void pop(BuildContext context) {
    if (!context.mounted) return;
    Navigator.pop(context);
  }

  // Pop with a result value (generic)
  void popWithResult<T>({required BuildContext context, T? result}) {
    if (!context.mounted) return;
    Navigator.pop<T>(context, result);
  }
}
