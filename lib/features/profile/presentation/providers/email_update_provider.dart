import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'email_update_provider.g.dart';

/// Represents the state of a pending email update.
class EmailUpdateState {
  final String? pendingEmail;

  const EmailUpdateState({this.pendingEmail});

  EmailUpdateState copyWith({
    String? pendingEmail,
  }) {
    // Use `Object()` as a sentinel value to allow explicitly setting to null
    final effectivePendingEmail =
        pendingEmail is Object ? pendingEmail : this.pendingEmail;
    return EmailUpdateState(
      pendingEmail: effectivePendingEmail,
    );
  }
}

/// Notifier to manage the state of a pending email update.
@Riverpod(keepAlive: true)
class EmailUpdateNotifier extends _$EmailUpdateNotifier {
  @override
  EmailUpdateState build() {
    // Initial state is no pending email
    return const EmailUpdateState();
  }

  /// Sets the pending email address.
  void setPendingEmail(String email) {
    state = state.copyWith(pendingEmail: email);
  }

  /// Clears the pending email address.
  void clearPendingEmail() {
    // Explicitly set to null using the sentinel value trick in copyWith
    state = state.copyWith(pendingEmail: null);
  }
}
