// lib/core/utils/logger.dart
import 'package:talker_flutter/talker_flutter.dart';

final talker = TalkerFlutter.init();

extension TalkerLoggerExtension on Talker {
  void logInfo(String message) {
    info(message);
  }

  void logWarning(String message) {
    warning(message);
  }

  void logError(String message, [dynamic error, StackTrace? stackTrace]) {
    handle(error, stackTrace, message);
  }

  void logSuccess(String message) {
    info('✅ $message'); // Changed from good() to info() with emoji
  }
}
