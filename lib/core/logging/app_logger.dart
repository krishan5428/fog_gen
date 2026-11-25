import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Single shared logger for the whole app — use this instead of
/// debugPrint()/print() so every call site goes through one place with
/// one compact, single-line format instead of each file boxing its own
/// output differently.
class AppLogger {
  AppLogger._();

  static final Logger _logger = Logger(
    printer: SimplePrinter(printTime: true, colors: true),
    level: kReleaseMode ? Level.warning : Level.debug,
  );

  static void d(dynamic message) => _logger.d(message);

  static void i(dynamic message) => _logger.i(message);

  static void w(dynamic message) => _logger.w(message);

  static void e(dynamic message, [Object? error, StackTrace? stackTrace]) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
}
