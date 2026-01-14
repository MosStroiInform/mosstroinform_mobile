import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger._();

  static const String _tag = '[MosStroInform]';

  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      final buffer = StringBuffer('$_tag [DEBUG] $message');
      if (error != null) {
        buffer.write('\nError: $error');
      }
      if (stackTrace != null) {
        buffer.write('\nStackTrace: $stackTrace');
      }
      debugPrint(buffer.toString());
    }
  }

  static void info(String message) {
    if (kDebugMode) {
      debugPrint('$_tag [INFO] $message');
    }
  }

  static void warning(String message, [Object? error]) {
    if (kDebugMode) {
      final buffer = StringBuffer('$_tag [WARNING] $message');
      if (error != null) {
        buffer.write('\nError: $error');
      }
      debugPrint(buffer.toString());
    }
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      final buffer = StringBuffer('$_tag [ERROR] $message');
      if (error != null) {
        buffer.write('\nError: $error');
      }
      if (stackTrace != null) {
        buffer.write('\nStackTrace: $stackTrace');
      }
      debugPrint(buffer.toString());
    }
  }
}
