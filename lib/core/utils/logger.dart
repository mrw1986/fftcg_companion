// lib/core/utils/logger.dart
import 'package:talker_flutter/talker_flutter.dart';

// Sanitize sensitive data from error objects
dynamic _sanitizeError(dynamic error) {
  if (error == null) return null;

  // Convert to string and remove sensitive patterns
  final errorString = error.toString();

  // Remove potential sensitive data patterns
  final sanitized = errorString
      .replaceAll(RegExp(r'password[:=]\s*\S+', caseSensitive: false),
          'password: [REDACTED]')
      .replaceAll(
          RegExp(r'token[:=]\s*\S+', caseSensitive: false), 'token: [REDACTED]')
      .replaceAll(RegExp(r'apiKey[:=]\s*\S+', caseSensitive: false),
          'apiKey: [REDACTED]')
      .replaceAll(RegExp(r'secret[:=]\s*\S+', caseSensitive: false),
          'secret: [REDACTED]')
      .replaceAll(RegExp(r'email[:=]\s*\S+@\S+', caseSensitive: false),
          'email: [REDACTED]')
      .replaceAll(RegExp(r'\b\d{4}[- ]?\d{4}[- ]?\d{4}[- ]?\d{4}\b'),
          '****-****-****-****'); // Credit card numbers

  return sanitized;
}

// Create a custom filter that only allows error logs in production
class ProductionLogFilter extends TalkerFilter {
  @override
  bool filter(TalkerData item) {
    // In production, only show errors
    if (const bool.fromEnvironment('dart.vm.product')) {
      return item.logLevel == LogLevel.error;
    }
    // In debug mode, show all logs
    return true;
  }
}

final talker = TalkerFlutter.init(
  settings: TalkerSettings(
    enabled: true,
    useConsoleLogs: true,
    maxHistoryItems: 1000,
  ),
  logger: TalkerLogger(),
  filter: ProductionLogFilter(),
);

// Initialize talker immediately
void initializeTalker() {
  talker.debug('Talker initialized');
  talker.debug('Console logs enabled: ${talker.settings.useConsoleLogs}');
  talker.debug('History enabled: ${talker.settings.useHistory}');
  talker.debug('Max history items: ${talker.settings.maxHistoryItems}');
}

extension TalkerLoggerExtension on Talker {
  void logInfo(String message) {
    info(message);
  }

  void logWarning(String message) {
    warning(message);
  }

  void logError(String message, [dynamic error, StackTrace? stackTrace]) {
    // Sanitize sensitive data from error messages
    final sanitizedError = _sanitizeError(error);
    handle(sanitizedError, stackTrace, message);
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

class ErrorBoundary {
  static T run<T>(
    T Function() operation, {
    T? fallback,
    String? context,
    bool rethrowError = false,
  }) {
    try {
      return operation();
    } catch (e, stack) {
      talker.error('Error in ${context ?? 'unknown context'}', e, stack);
      if (rethrowError) rethrow;
      if (fallback != null) return fallback;
      throw AppError(
        message: 'Operation failed${context != null ? ' in $context' : ''}',
        originalError: e,
        stack: stack,
      );
    }
  }

  static Future<T> runAsync<T>(
    Future<T> Function() operation, {
    T? fallback,
    String? context,
    bool rethrowError = false,
  }) async {
    try {
      return await operation();
    } catch (e, stack) {
      talker.error('Error in ${context ?? 'unknown context'}', e, stack);
      if (rethrowError) rethrow;
      if (fallback != null) return fallback;
      throw AppError(
        message:
            'Async operation failed${context != null ? ' in $context' : ''}',
        originalError: e,
        stack: stack,
      );
    }
  }
}

class AppError implements Exception {
  final String message;
  final dynamic originalError;
  final StackTrace? stack;

  AppError({
    required this.message,
    this.originalError,
    this.stack,
  });

  @override
  String toString() => message;
}

extension ErrorBoundaryX on ErrorBoundary {
  static Future<int> handleCardCount(
    Future<int> Function() operation,
    String setId, {
    int fallback = 0,
  }) async {
    try {
      return await operation();
    } catch (e, stack) {
      talker.error('Error getting card count for set $setId', e, stack);
      return fallback;
    }
  }
}
