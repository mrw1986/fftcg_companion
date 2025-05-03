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
```plaintext

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
│   │   └── auth_provider.dart
│   └── services/
│       └── auth_service.dart
└── features/
    └── profile/
        └── presentation/
            ├── pages/
            │   └── account_settings_page.dart
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

## Future Considerations

1. **Performance Optimization**
   - Monitor token refresh frequency
   - Optimize state updates
   - Review lifecycle checks

2. **User Experience**
   - Add progress indicators
   - Improve error messages
   - Consider offline support

3. **Testing**
   - Add unit tests for token handling
   - Add integration tests for the full flow
   - Add stress tests for edge cases
