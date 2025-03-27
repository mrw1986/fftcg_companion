// This file is no longer needed as its functionality has been consolidated
// into lib/core/providers/email_verification_checker.dart
// Keeping this file as a placeholder to avoid breaking imports
// but it should be removed in a future cleanup

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fftcg_companion/core/providers/email_verification_checker.dart';

/// This provider is deprecated and should not be used.
/// Use emailVerificationCheckerProvider from core/providers/email_verification_checker.dart instead.
@Deprecated('Use emailVerificationCheckerProvider instead')
final autoVerificationCheckerProvider = Provider.autoDispose<void>((ref) {
  // Forward to the actual implementation
  return ref.watch(emailVerificationCheckerProvider);
});
