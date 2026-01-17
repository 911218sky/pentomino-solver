import 'package:logger/logger.dart';

/// Application logger utility
class AppLogger {
  static final Logger _logger = Logger(
    printer: SimplePrinter(
      colors: false,
      printTime: false,
    ),
  );

  /// Debug level logging
  static void debug(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Info level logging
  static void info(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Warning level logging
  static void warning(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Error level logging
  static void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}
