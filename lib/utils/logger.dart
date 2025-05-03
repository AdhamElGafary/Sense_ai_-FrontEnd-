import 'package:flutter/foundation.dart';

/// A simple logging utility to replace print statements
///
/// This class provides a standardized way to log messages with different
/// severity levels. It helps avoid using print statements directly in code,
/// which is a linter warning.
///
/// In production builds, only errors will be shown. In debug builds,
/// all messages will be shown.
class AppLogger {
  /// Singleton instance
  static final AppLogger _instance = AppLogger._internal();

  /// Factory constructor to return the singleton instance
  factory AppLogger() => _instance;

  /// Private constructor
  AppLogger._internal();

  /// Log a debug message
  ///
  /// These messages are only shown in debug builds
  void d(String message) {
    if (kDebugMode) {
      debugPrint('DEBUG: $message');
    }
  }

  /// Log an info message
  ///
  /// These messages are only shown in debug builds
  void i(String message) {
    if (kDebugMode) {
      debugPrint('INFO: $message');
    }
  }

  /// Log a warning message
  ///
  /// These messages are shown in both debug and production builds
  void w(String message) {
    debugPrint('WARNING: $message');
  }

  /// Log an error message
  ///
  /// These messages are always shown
  void e(String message) {
    debugPrint('ERROR: $message');
  }

  /// Log an error message with an exception
  ///
  /// These messages are always shown
  void exception(String message, Object error, [StackTrace? stackTrace]) {
    debugPrint('EXCEPTION: $message');
    debugPrint('ERROR: $error');
    if (stackTrace != null) {
      debugPrint('STACKTRACE: $stackTrace');
    }
  }
}

/// Global logger instance for easy access
final logger = AppLogger();
