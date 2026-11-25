// ignore_for_file: deprecated_member_use
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fog_gen_new/constants/app_colors.dart';

class ProgressDialog {
  static bool _isShowing = false;
  static DateTime? _shownAt;
  static Duration? _minVisibleDuration;
  static int _generation = 0;
  static Timer? _safetyTimer;

  // However a caller is supposed to close this (a matching dismiss() on
  // whatever state change follows), a stuck dialog reads to the user as a
  // frozen app. This is the absolute ceiling on how long it can stay up
  // regardless of what triggered it, or fails to — a bug elsewhere (a race
  // that shows it after data already loaded, a network call that never
  // resolves, a caller that forgets to dismiss) degrades to "spinner for a
  // few extra seconds" instead of "app is stuck".
  static const Duration _maxVisibleDuration = Duration(seconds: 20);

  static void reset() {
    _isShowing = false;
    _shownAt = null;
    _minVisibleDuration = null;
    _generation++;
    _safetyTimer?.cancel();
    _safetyTimer = null;
  }

  static void show(
    BuildContext context, {
    String message = 'Please wait, processing your request...',
    // Callers that fetch from a local cache first (e.g. the dashboard's
    // "Getting updated Panel Data" refresh) can resolve in a single frame,
    // making the dialog flash open and shut — which reads as a glitch, not
    // a loading state. Passing a minimum here keeps *that specific* dialog
    // up for at least this long; left null (the default), dismiss() closes
    // immediately as before, so every other call site is unaffected.
    Duration? minVisibleDuration,
  }) {
    if (_isShowing) return;
    _isShowing = true;
    _shownAt = DateTime.now();
    _minVisibleDuration = minVisibleDuration;
    _generation++;
    final myGeneration = _generation;

    _safetyTimer?.cancel();
    _safetyTimer = Timer(_maxVisibleDuration, () {
      if (_isShowing && _generation == myGeneration) {
        debugPrint(
          'ProgressDialog: force-dismissing after ${_maxVisibleDuration.inSeconds}s safety timeout',
        );
        dismiss(context);
      }
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              backgroundColor: AppColors.white,
              content: Row(
                children: [
                  const CircularProgressIndicator(
                    color: AppColors.colorPrimary,
                  ),
                  const SizedBox(width: 20),
                  Expanded(child: Text(message)),
                ],
              ),
            ),
          ),
    );
  }

  static Future<void> dismiss(BuildContext context) async {
    if (!_isShowing) return;
    final myGeneration = _generation;
    _safetyTimer?.cancel();

    final shownAt = _shownAt;
    final minVisibleDuration = _minVisibleDuration;
    if (shownAt != null &&
        minVisibleDuration != null &&
        minVisibleDuration > Duration.zero) {
      final remaining = minVisibleDuration - DateTime.now().difference(shownAt);
      if (remaining > Duration.zero) {
        await Future.delayed(remaining);
      }
    }

    // A newer show()/reset() happened while this dismiss() was waiting out
    // its minimum — don't close a dialog that isn't the one we were asked
    // to dismiss.
    if (!_isShowing || _generation != myGeneration) return;

    _isShowing = false;
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
  }
}
