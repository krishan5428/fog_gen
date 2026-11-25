import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import 'package:fog_gen_new/constants/app_colors.dart';

/// Single place for showing user feedback toasts across the app.
///
/// Every screen should call this (or [SnackBarHelper], which now delegates
/// here) instead of ScaffoldMessenger/SnackBar or a local toastification
/// helper, so styling, alignment, and stacking behavior stay consistent
/// app-wide. The max-3-stacked-toasts limit is enforced globally via the
/// `ToastificationConfigProvider` wrapping the app in fire_nex_app.dart.
class ToastHelper {
  ToastHelper._();

  static void show(
    BuildContext context,
    String message, {
    ToastificationType? type,
    String? title,
  }) {
    if (!context.mounted) return;

    final resolved =
        type != null ? _forType(type, title) : _infer(message, title);

    toastification.show(
      context: context,
      type: resolved.type,
      style: ToastificationStyle.fillColored,
      alignment: Alignment.bottomCenter,
      title: Text(
        resolved.title,
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.bold,
          fontSize: 14.sp,
          color: Colors.white,
        ),
      ),
      description: Text(
        message,
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w500,
          fontSize: 12.sp,
          color: Colors.white,
        ),
      ),
      autoCloseDuration: const Duration(seconds: 3),
      showProgressBar: false,
      primaryColor: resolved.color,
      foregroundColor: Colors.white,
      icon: Icon(resolved.icon, color: Colors.white),
    );
  }

  static void success(BuildContext context, String message, {String? title}) =>
      show(context, message, type: ToastificationType.success, title: title);

  static void error(BuildContext context, String message, {String? title}) =>
      show(context, message, type: ToastificationType.error, title: title);

  static void warning(BuildContext context, String message, {String? title}) =>
      show(context, message, type: ToastificationType.warning, title: title);

  static void info(BuildContext context, String message, {String? title}) =>
      show(context, message, type: ToastificationType.info, title: title);

  static _Resolved _forType(ToastificationType type, String? title) {
    switch (type) {
      case ToastificationType.success:
        return _Resolved(
          type,
          title ?? 'Success',
          const Color(0xFF2ECC71),
          Icons.check_circle_outline,
        );
      case ToastificationType.error:
        return _Resolved(
          type,
          title ?? 'Error',
          const Color(0xFFD32F2F),
          Icons.error_outline,
        );
      case ToastificationType.warning:
        return _Resolved(
          type,
          title ?? 'Notice',
          const Color(0xFFF2994A),
          Icons.warning_amber_outlined,
        );
      default:
        return _Resolved(
          ToastificationType.info,
          title ?? 'Info',
          AppColors.colorPrimary,
          Icons.info_outline,
        );
    }
  }

  /// Mirrors the message-sniffing convention already established in
  /// mqtt_control_screen.dart's `_showFeedback`, generalized so callers that
  /// never carried a severity (e.g. every old `SnackBarHelper.showSnackBar`
  /// call site) still get a sensible type without touching each one.
  static _Resolved _infer(String message, String? title) {
    final m = message.toLowerCase();
    if (m.contains('success') ||
        m.contains('verified') ||
        m.contains('saved') ||
        m.contains('updated') ||
        m.contains('added') ||
        m.contains('submitted') ||
        m.contains('sent')) {
      return _Resolved(
        ToastificationType.success,
        title ?? 'Success',
        const Color(0xFF2ECC71),
        Icons.check_circle_outline,
      );
    }
    if (m.contains('fail') ||
        m.contains('error') ||
        m.contains('timeout') ||
        m.contains('denied') ||
        m.contains('invalid') ||
        m.contains('unexpected') ||
        m.contains('wrong') ||
        m.contains('please')) {
      return _Resolved(
        ToastificationType.error,
        title ?? 'Error',
        const Color(0xFFD32F2F),
        Icons.error_outline,
      );
    }
    if (m.contains('cancel')) {
      return _Resolved(
        ToastificationType.info,
        title ?? 'Cancelled',
        Colors.grey.shade700,
        Icons.close,
      );
    }
    if (m.contains('disconnect')) {
      return _Resolved(
        ToastificationType.info,
        title ?? 'Disconnected',
        Colors.grey.shade700,
        Icons.link_off,
      );
    }
    return _Resolved(
      ToastificationType.info,
      title ?? 'Notice',
      AppColors.colorPrimary,
      Icons.info_outline,
    );
  }
}

class _Resolved {
  final ToastificationType type;
  final String title;
  final Color color;
  final IconData icon;

  const _Resolved(this.type, this.title, this.color, this.icon);
}
