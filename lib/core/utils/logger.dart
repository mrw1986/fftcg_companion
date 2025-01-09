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
    info('✅ $message'); // This is the correct way according to docs
  }
}

extension TalkerDebugExtension on Talker {
  void debugOperation(String operation, String details) {
    debug('[$operation] $details');
  }

  void logState(String component, String state) {
    debug('$component state: $state');
  }

  void logDataConversion(String type, dynamic data) {
    verbose('Converting $type: $data');
  }
}
