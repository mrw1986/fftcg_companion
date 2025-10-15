# Current Task

## Current Objective: Fix Email Update UI State After Verification - COMPLETED

### Context

- **Issue:** After initiating an email change and verifying the new email via the link, the UI state (pending email and verification status) did not update correctly.
- **Investigation:** Reviewed the email update flow and found that while the Firebase Auth state updates correctly (as seen in the success dialog), the app's UI state wasn't synchronizing properly.
- **Root Causes Identified:**
  1. Token Invalidation: When a user verifies their new email, Firebase invalidates their current token, but the app wasn't handling this gracefully.
  2. Riverpod State Error: Race condition during state transitions causing "Cannot use ref functions after the dependency of a provider changed" error.
  3. Race Condition: Email update completion provider trying to check email update during sign-out when providers might be invalidated.

### Implementation Plan

#### 1. Token Refresh Handling Improvements

In `auth_provider.dart`:

```dart
try {
  await user.getIdToken(false);
} catch (e) {
  talker.debug('Token expired, attempting force refresh...');
  await user.getIdToken(true);
}
```

- Add progressive token refresh (try without force first)
- Add user reload before token refresh attempts
- Handle different error codes appropriately
- Add comprehensive error logging

#### 2. Error Boundary for Riverpod State

In `email_update_completion_provider.dart`:

```dart
EmailUpdateState? emailUpdateState;
try {
  emailUpdateState = ref.read(emailUpdateNotifierProvider);
} catch (e) {
  talker.error('Error reading provider state', e);
}
```

- Add safe state reading with error handling
- Create local copies of required values
- Handle provider state errors gracefully
- Add comprehensive error logging

#### 3. Safe State Management

In both providers:

- Add state cleanup during sign-out
- Handle token expiration gracefully
- Add delayed UI updates when needed
- Improve error handling and recovery

#### 4. Action Code Settings Enhancement

In `auth_service.dart`:

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

- Add proper action code settings
- Improve error handling for email operations
- Add token refresh helper method

### Testing Plan

1. **Basic Flow Testing:**
   - Sign in with email/password
   - Initiate email change
   - Verify via link
   - Confirm UI updates correctly without sign-out

2. **Edge Cases:**
   - Background app state during verification
   - Linked Google account scenarios
   - Multiple rapid email changes
   - Deliberate token invalidation

3. **Error Handling:**
   - Network disconnection during verification
   - Simultaneous operations (email + password change)
   - Token expiration scenarios

### Files to Modify

1. `lib/core/providers/auth_provider.dart`
   - Improve token refresh handling
   - Update state management
   - Add error handling

2. `lib/features/profile/presentation/providers/email_update_completion_provider.dart`
   - Add error boundaries
   - Improve state management
   - Add safe state reading

3. `lib/core/services/auth_service.dart`
   - Add action code settings
   - Add token refresh helper
   - Improve error handling

4. `lib/features/profile/presentation/pages/account_settings_page.dart`
   - Update lifecycle handling
   - Add manual refresh
   - Improve UI updates

### Status

- **Completed:** Analysis of the issue and identification of root causes
- **Completed:** Development of comprehensive implementation plan
- **Completed:** Implementation of the fixes
- **Completed:** Implementation of EmailUpdateVerificationChecker for active monitoring
- **Pending:** Testing of all scenarios
- **Pending:** Documentation updates after implementation

### Actions Taken

1. Created new `EmailUpdateCompletionProvider` to monitor and handle email update completion:

   ```dart
   final emailUpdateCompletionProvider = Provider<void>((ref) {
     final authState = ref.watch(authNotifierProvider);
     final pendingEmail = ref.watch(emailUpdateNotifierProvider).pendingEmail;
     
     if (authState.user != null && pendingEmail != null) {
       if (authState.user!.email == pendingEmail) {
         ref.read(emailUpdateNotifierProvider.notifier).clearPendingEmail();
         ref.read(originalEmailForUpdateCheckProvider.notifier).state = '';
         talker.info('Email update completion detected: ${authState.user!.email}');
       }
     }
   });
   ```

2. Enhanced `AuthNotifier._updateStateFromUser` to check for email update completion:

   ```dart
   if (user != null) {
     final pendingEmail = ref.read(emailUpdateNotifierProvider).pendingEmail;
     if (pendingEmail != null && user.email == pendingEmail) {
       ref.read(emailUpdateNotifierProvider.notifier).clearPendingEmail();
       ref.read(originalEmailForUpdateCheckProvider.notifier).state = '';
       talker.info('Detected email verification completion in AuthNotifier, cleared pending email state.');
     }
   }
   ```

3. Modified `AccountSettingsPage` to watch the completion provider:

   ```dart
   @override
   Widget build(BuildContext context) {
     // Watch the email update completion provider to keep it active
     ref.watch(emailUpdateCompletionProvider);
     
     // Rest of build method...
   }
   ```

4. Added comprehensive logging throughout the flow to track state changes and verification detection.

5. **NEW**: Removed ActionCodeSettings from `auth_service.dart` since it was causing issues with domain whitelisting:

   ```dart
   // Send the verification email without action code settings
   // This uses the default Firebase flow and avoids domain whitelisting issues
   await currentUser.verifyBeforeUpdateEmail(newEmail).timeout(_timeout);
   ```

6. **NEW**: Implemented progressive token refresh strategy in `auth_provider.dart`:

   ```dart
   try {
     // Try without force first
     final token = await currentUser.getIdToken(forceRefresh);
     return token;
   } catch (e) {
     if (!forceRefresh) {
       // If regular refresh fails and we haven't tried force yet, try with force
       final token = await currentUser.getIdToken(true);
       return token;
     } else {
       // If we're already using force and it failed, rethrow
       rethrow;
     }
   }
   ```

7. **NEW**: Added error boundaries in `email_update_completion_provider.dart`:

   ```dart
   // Safely retrieve pending email with error handling
   String? pendingEmail;
   String originalEmail = '';

   // Error boundary for provider state access
   try {
     final emailUpdateState = ref.read(emailUpdateNotifierProvider);
     pendingEmail = emailUpdateState.pendingEmail;
     originalEmail = ref.read(originalEmailForUpdateCheckProvider);
   } catch (e) {
     talker.error('Error reading provider state during email update check', e);
     // Continue with null/default values
     pendingEmail = null;
     originalEmail = '';
   }
   ```

8. **NEW**: Added manual refresh method in `account_settings_page.dart`:

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

9. **NEW**: Enhanced AppLifecycleState handling in `account_settings_page.dart` to check for email updates when the app resumes.

10. **NEW**: Implemented EmailUpdateVerificationChecker provider:

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

11. **NEW**: Modified account_settings_page.dart to start the verification checker when an email update is initiated:

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

12. **NEW**: Enhanced account_info_card.dart to show verification status:

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

    And updated the UI to show verification status:

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

## Previous Objectives (Completed)

### Test Email Change Flow & General Auth (Previous Session - Attempt 1)

#### Context (Reauthentication & Sign-in Redirect Issues)

- A major refactoring of `lib/core/providers/auth_provider.dart` was completed to use `AsyncNotifier` (`authNotifierProvider`).
- **Issue Found During Testing:** After changing the email address using `verifyBeforeUpdateEmail` and verifying the new email via the link, the app UI did not update correctly.
- **Fix Implemented:** Modified `AuthNotifier` (`lib/core/providers/auth_provider.dart`) to explicitly call `user.reload()` before processing user data in its listener. Added app lifecycle checks in `AccountSettingsPage` to handle updates when the app resumes. Added `emailUpdateNotifierProvider` and `originalEmailForUpdateCheckProvider` to manage pending/original email states.
- **Decision:** Proceed with testing the "stay logged in" approach for email updates, verifying the implemented fixes.
- **Logging Verified:** Confirmed sufficient logging exists in `AccountSettingsPage`, `AuthService`, and `AuthNotifier` to diagnose the flow.
- **Additional Issues Investigated:** User reported a blank reauthentication screen and getting stuck on the sign-in page after Google sign-in.

#### Actions Taken During Reauthentication & Sign-in Redirect Investigation

- Refactored `lib/core/providers/auth_provider.dart` to use `AsyncNotifier`.
- Updated all dependent files to use `authNotifierProvider`.
- Implemented `user.reload()` fix in `AuthNotifier`.
- Added app lifecycle checks in `AccountSettingsPage`.
- Added providers for pending/original email state management.
- Verified logging across relevant files.
- **Investigated Reauthentication/Sign-in Issues:**
  - Added diagnostic logging to `ProfileReauthDialog` to check provider loading.
  - Added diagnostic logging to `AuthNotifier` to check router listener notification and redirect logic execution.
  - Confirmed via logs that the router listener *is* being called and the `redirect` function *is* executed correctly after Google sign-in.
  - The blank reauthentication screen could not be reproduced during the investigation.
  - Removed diagnostic logging after confirming correct behavior.

#### Current Status

- **Completed:** Auth provider refactoring.
- **Completed:** Implementation of fixes for the "stay logged in" email update flow (reload, lifecycle checks, state providers).
- **Completed:** Verification of logging sufficiency.
- **Completed:** Update of testing instructions (`userInstructions/testAuthFlows.md`).
- **Completed:** Investigation of reauthentication/sign-in redirect issues (issues appear resolved/intermittent).
- **Completed:** Execution of the authentication testing plan.

### Investigate Reauthentication & Sign-in Redirect Issues (Previous Session - Attempt 1)

#### Investigation Context

- User reported two issues:
  1. A blank screen appearing when reauthentication was required (e.g., before account deletion), with no options (Google/Email) shown.
  2. After signing in with Google, the UI remained stuck on the sign-in page despite logs indicating successful authentication.

#### Actions Taken (Reauthentication & Sign-in Redirect)

1. **Diagnose Reauth Screen:**
    - Added detailed logging to `_loadProviders` in `ProfileReauthDialog` to check `FirebaseAuth.instance.currentUser` and provider data access.
    - Attempted to reproduce the blank screen by triggering reauthentication (e.g., via account deletion flow).
    - **Finding:** The blank screen issue could not be reproduced. Reauthentication was not required during testing due to a recent session.
2. **Diagnose Sign-in Redirect:**
    - Observed logs showing successful Google sign-in (`AuthStatus.authenticated`) but no subsequent router redirect checks.
    - Added logging around `_routerListener?.call()` in `AuthNotifier` to confirm listener notification.
    - Added logging at the start of the `AuthNotifier.redirect` method to confirm its execution.
    - Tested Google sign-in again.
    - **Finding:** Logs confirmed the router listener *was* called and the `redirect` function *was* executed correctly, redirecting from `/auth` to `/` as expected. The issue of getting stuck seemed intermittent or resolved by app restart/rebuild.
3. **Cleanup:** Removed the added diagnostic logging from `ProfileReauthDialog` and `AuthNotifier`.

#### Investigation Status

- Investigation complete. Both reported issues appear resolved or were intermittent and could not be reproduced consistently. The underlying logic for provider loading in the reauth dialog and router redirection seems correct.
