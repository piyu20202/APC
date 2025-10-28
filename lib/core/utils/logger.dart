import 'package:flutter/foundation.dart';

class Logger {
  static void log(String message, {String? tag}) {
    if (kDebugMode) {
      debugPrint('[${tag ?? 'App'}] $message');
    }
  }

  static void info(String message) {
    log(message, tag: 'INFO');
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      log('$message\nError: $error', tag: 'ERROR');
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }

  static void warning(String message) {
    log(message, tag: 'WARNING');
  }
}
