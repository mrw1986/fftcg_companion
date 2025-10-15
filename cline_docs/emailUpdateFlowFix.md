# Email Update Flow Fix Documentation

## Overview

This document details the implementation of fixes for the email update flow in the FFTCG Companion app, addressing issues with UI state synchronization after email verification.

## Problem Analysis

### Key Issues

1. **Token Invalidation Handling**
   - When a user verifies their new email via the verification link, Firebase invalidates their current authentication token
   - The app wasn't properly handling this token invalidation
   - Result: Unexpected sign-outs and UI state inconsistencies

2. **Riverpod State Error**
   - Error: "Cannot use ref functions after the dependency of a provider changed but before the provider rebuilt"
   - Cause: `EmailUpdateCompletionNotifier` accessing providers during state transitions
   - Impact: Race conditions in state management

3. **Race Condition**
   - During sign-out triggered by token expiration, state updates weren't properly synchronized
   - Result: UI not reflecting the latest state correctly

4. **Lack of Active Verification Monitoring**
   - The app waited passively for Firebase Auth state changes to detect email verification
   - No proactive mechanism to actively check verification status
   - Result: Delayed UI updates and poor user feedback

## Implementation Details

### 1. Token Refresh Handling (`auth_provider.dart`)

#### Progressive Token Refresh Strategy

```dart
try {
  // Try without force first
  await user.getIdToken(false);
} catch (e) {
  // If that fails, try force refresh
  await user.getIdToken(true);
}
```

#### Error Code Handling

- Permanent errors (user-not-found, user-disabled): Force sign-out
- Token expiration: Attempt reload and refresh before sign-out
- Comprehensive error logging at each step

### 2. Error Boundary Implementation (`email_update_completion_provider.dart`)

#### Safe State Reading

```dart
EmailUpdateState? emailUpdateState;
try {
  emailUpdateState = ref.read(emailUpdateNotifierProvider);
  pendingEmail = emailUpdateState.pendingEmail;
  originalEmail = ref.read(originalEmailForUpdateCheckProvider);
} catch (e) {
  talker.error('Error reading provider state', e);
  // Continue with null/default values
}
```

#### State Update Safety

- Local value copies to prevent state access during transitions
- Graceful error recovery
- Comprehensive logging for debugging

### 3. Action Code Settings Enhancement (`auth_service.dart`)

```dart
final actionCodeSettings = ActionCodeSettings(
  url: 'https://yourapp.page.link/finishEmailUpdate?email=$newEmail',
  handleCodeInApp: true,
  androidPackageName: 'com.mrw1986.fftcg_companion',
  androidInstallApp: true,
  androidMinimumVersion: '12',
  iOSBundleId: 'com.mrw1986.fftcg-companion',
);
```

#### Error Handling Improvements

- Specific error cases with custom messages
- Token refresh helper method
- Proper error propagation

### 4. Lifecycle Management (`account_settings_page.dart`)

#### App Resume Handling

- Check for pending email updates
- Safe token refresh and user reload
- UI state synchronization with delays

#### Manual Refresh Capability

```dart
Future<void> _manualRefresh() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await ref.read(authServiceProvider).refreshUserToken();
      await user.reload();
      ref.invalidate(authNotifierProvider);
      if (mounted) setState(() {});
    }
  } catch (e) {
    talker.error('Error during manual refresh', e);
  }
}
```

### 5. Active Verification Monitoring (NEW) (`email_update_verification_checker.dart`)

#### EmailUpdateVerificationChecker Provider

```dart
/// A provider that actively checks for email update verification completion
final emailUpdateVerificationCheckerProvider =
    NotifierProvider<EmailUpdateVerificationChecker, bool>(
  () => EmailUpdateVerificationChecker(),
);

class EmailUpdateVerificationChecker extends Notifier<bool> {
  Timer? _timer;
  
  @override
  bool build() {
    ref.onDispose(() {
      _timer?.cancel();
      talker.debug('EmailUpdateVerificationChecker: Timer disposed');
    });
    
    return false; // Initial state: not verified
  }
  
  void startChecking() {
    // Cancel any existing timer
    _timer?.cancel();
    
    // Start a new timer to check every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _checkEmailUpdateVerification();
    });
    
    talker.info('EmailUpdateVerificationChecker: Started verification checking');
  }
  
  Future<void> _checkEmailUpdateVerification() async {
    // Only check if we're not already verified
    if (state) return;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      talker.debug('EmailUpdateVerificationChecker: No current user');
      return;
    }
    
    String? pendingEmail;
    try {
      pendingEmail = ref.read(emailUpdateNotifierProvider).pendingEmail;
    } catch (e) {
      talker.error('EmailUpdateVerificationChecker: Error reading pendingEmail', e);
      return;
    }
    
    if (pendingEmail == null || pendingEmail.isEmpty) {
      talker.debug('EmailUpdateVerificationChecker: No pending email');
      return;
    }
    
    try {
      // Try to refresh token and reload user
      await user.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;
      
      // Check if email has been updated
      if (refreshedUser != null && refreshedUser.email == pendingEmail) {
        talker.info('EmailUpdateVerificationChecker: Email update verified! Current: ${refreshedUser.email}');
        state = true; // Update state to verified
        _timer?.cancel(); // Stop checking
      } else {
        talker.debug('EmailUpdateVerificationChecker: Email not yet verified. Current: ${refreshedUser?.email}, Pending: $pendingEmail');
      }
    } catch (e) {
      talker.error('EmailUpdateVerificationChecker: Error checking verification', e);
    }
  }
}
```

#### Integration with Email Update Flow

In `account_settings_page.dart`:

```dart
// Send verification email
await ref.read(authServiceProvider).verifyBeforeUpdateEmail(newEmail);

// Update pending email state
ref.read(emailUpdateNotifierProvider.notifier).setPendingEmail(newEmail);
talker.info('Verification email sent for email update.');

// Start the email update verification checker
ref.read(emailUpdateVerificationCheckerProvider.notifier).startChecking();
talker.info('Started email update verification checker.');
```

#### UI Enhancements for Verification Status

In `account_info_card.dart`:

```dart
// Watch the email update verification checker
final isEmailUpdateVerified = ref.watch(emailUpdateVerificationCheckerProvider);

// Listen for email update verification
ref.listen(emailUpdateVerificationCheckerProvider, (previous, next) {
  if (next) {
    talker.info('AccountInfoCard: Email update verification detected');
    // Invalidate providers to refresh state
    ref.invalidate(authNotifierProvider);
    
    // Clear the pending email after verification is detected
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(emailUpdateNotifierProvider.notifier).clearPendingEmail();
    });
  }
});
```

UI implementation:

```dart
// Display Pending Email if present, with verification status
if (pendingEmail != null) ...[
  ListTile(
    leading: Icon(
      isEmailUpdateVerified 
          ? Icons.check_circle_outline
          : Icons.hourglass_top_rounded,
      color: isEmailUpdateVerified 
          ? colorScheme.tertiary 
          : colorScheme.secondary,
    ),
    title: Text(pendingEmail!,
        style: TextStyle(color: colorScheme.onSurfaceVariant)),
    subtitle: Text(
      isEmailUpdateVerified 
          ? 'Verification Complete' 
          : 'Pending Verification'
    ),
    trailing: Chip(
      label: Text(
        isEmailUpdateVerified ? 'Verified' : 'Unverified', 
        style: textTheme.labelSmall
      ),
      backgroundColor: isEmailUpdateVerified
          ? colorScheme.tertiaryContainer
          : colorScheme.secondaryContainer,
      labelStyle: TextStyle(
        color: isEmailUpdateVerified
            ? colorScheme.onTertiaryContainer
            : colorScheme.onSecondaryContainer
      ),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: BorderSide.none,
    ),
    dense: true,
  ),
],
```

## Testing Strategy

### 1. Basic Flow Testing

- Sign in with email/password
- Initiate email change
- Verify via link
- Confirm UI updates correctly without sign-out

### 2. Edge Cases

- Background app state during verification
- Linked Google account scenarios
- Multiple rapid email changes
- Deliberate token invalidation

### 3. Error Handling

- Network disconnection during verification
- Simultaneous operations (email + password change)
- Token expiration scenarios

## Implementation Considerations

### Code Quality

- Comprehensive error handling throughout the flow
- Detailed logging for debugging
- Clear separation of concerns

### User Experience

- Improved token refresh handling
- Better error messages
- Manual refresh option for edge cases
- **New:** Real-time verification status indicators
- **New:** Proactive verification checking

### Maintainability

- Error boundaries for robust state management
- Clear documentation of complex flows
- Consistent logging patterns

### Security

- Proper token invalidation handling
- Email enumeration protection
- Safe state cleanup

## File Structure

```plaintext
lib/
├── core/
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   └── email_update_verification_checker.dart (NEW)
│   └── services/
│       └── auth_service.dart
└── features/
    └── profile/
        └── presentation/
            ├── pages/
            │   └── account_settings_page.dart
            ├── widgets/
            │   └── account_info_card.dart
            └── providers/
                └── email_update_completion_provider.dart
```

## Best Practices Applied

1. **State Management**
   - Safe provider access
   - Local state copies
   - Proper cleanup

2. **Error Handling**
   - Specific error types
   - Graceful degradation
   - User-friendly messages

3. **Token Management**
   - Progressive refresh
   - Proper invalidation
   - Safe reloading

4. **UI Updates**
   - Delayed updates when needed
   - State synchronization
   - Manual refresh option
   - **New:** Real-time verification status indicators

5. **Active Monitoring**
   - **New:** Timer-based polling
   - **New:** Progressive token refresh
   - **New:** User reload to get latest state
   - **New:** Clean timer disposal

## Future Considerations

1. **Performance Optimization**
   - Monitor token refresh frequency
   - Optimize state updates
   - Review lifecycle checks
   - **New:** Tune polling interval based on real-world usage

2. **User Experience**
   - Add progress indicators
   - Improve error messages
   - Consider offline support
   - **New:** Consider push notifications for verification

3. **Testing**
   - Add unit tests for token handling
   - Add integration tests for the full flow
   - Add stress tests for edge cases
   - **New:** Test verification checker with slow network connections
