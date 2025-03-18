import 'package:flutter/material.dart';

/// Helper class for creating consistently themed SnackBars throughout the app
class SnackBarHelper {
  /// Creates a standard SnackBar with proper theming
  static SnackBar createSnackBar({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 2),
    SnackBarAction? action,
    bool centered = false,
    bool floating = true,
    double? width,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return SnackBar(
      content: centered
          ? Center(
              child: Text(
                message,
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            )
          : Text(
              message,
              style: TextStyle(
                color: colorScheme.onPrimaryContainer,
              ),
            ),
      duration: duration,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      behavior: floating ? SnackBarBehavior.floating : SnackBarBehavior.fixed,
      backgroundColor: colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(floating ? 28 : 0),
      ),
      margin: floating && width != null
          ? EdgeInsets.only(
              bottom: 24,
              left: (MediaQuery.of(context).size.width - width) / 2,
              right: (MediaQuery.of(context).size.width - width) / 2,
            )
          : floating
              ? const EdgeInsets.all(16)
              : null,
      elevation: 6,
      action: action,
    );
  }

  /// Creates a success SnackBar with proper theming
  static SnackBar createSuccessSnackBar({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 2),
    SnackBarAction? action,
    bool centered = false,
    bool floating = true,
    double? width,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return SnackBar(
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            color: colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: centered
                ? Center(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  )
                : Text(
                    message,
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
          ),
        ],
      ),
      duration: duration,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      behavior: floating ? SnackBarBehavior.floating : SnackBarBehavior.fixed,
      backgroundColor: colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(floating ? 28 : 0),
      ),
      margin: floating && width != null
          ? EdgeInsets.only(
              bottom: 24,
              left: (MediaQuery.of(context).size.width - width) / 2,
              right: (MediaQuery.of(context).size.width - width) / 2,
            )
          : floating
              ? const EdgeInsets.all(16)
              : null,
      elevation: 6,
      action: action,
    );
  }

  /// Creates an error SnackBar with proper theming
  static SnackBar createErrorSnackBar({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
    bool centered = false,
    bool floating = true,
    double? width,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return SnackBar(
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error,
            color: colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: centered
                ? Center(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  )
                : Text(
                    message,
                    style: TextStyle(
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
          ),
        ],
      ),
      duration: duration,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      behavior: floating ? SnackBarBehavior.floating : SnackBarBehavior.fixed,
      backgroundColor: colorScheme.errorContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(floating ? 28 : 0),
      ),
      margin: floating && width != null
          ? EdgeInsets.only(
              bottom: 24,
              left: (MediaQuery.of(context).size.width - width) / 2,
              right: (MediaQuery.of(context).size.width - width) / 2,
            )
          : floating
              ? const EdgeInsets.all(16)
              : null,
      elevation: 6,
      action: action,
    );
  }

  /// Shows a standard SnackBar with proper theming
  static void showSnackBar({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 2),
    SnackBarAction? action,
    bool centered = false,
    bool floating = true,
    double? width,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      createSnackBar(
        context: context,
        message: message,
        duration: duration,
        action: action,
        centered: centered,
        floating: floating,
        width: width,
      ),
    );
  }

  /// Shows a success SnackBar with proper theming
  static void showSuccessSnackBar({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 2),
    SnackBarAction? action,
    bool centered = false,
    bool floating = true,
    double? width,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      createSuccessSnackBar(
        context: context,
        message: message,
        duration: duration,
        action: action,
        centered: centered,
        floating: floating,
        width: width,
      ),
    );
  }

  /// Shows an error SnackBar with proper theming
  static void showErrorSnackBar({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
    bool centered = false,
    bool floating = true,
    double? width,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      createErrorSnackBar(
        context: context,
        message: message,
        duration: duration,
        action: action,
        centered: centered,
        floating: floating,
        width: width,
      ),
    );
  }
}
