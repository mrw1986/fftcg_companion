# Current Task

## Current Objective: Fix Update Password Dialog Resizing

### Context for Redirect Issue

- The "Update Password" dialog resized when the "New Password" field gained focus because the "Password Requirements" text was conditionally displayed. This created a slightly jarring user experience.

### Actions Taken for Redirect Issue

1. **Identified Cause:** Located the conditional rendering logic in `lib/features/profile/presentation/widgets/update_password_dialog.dart` based on the `_isPasswordFocused` state variable.
2. **Modified Dialog:** Removed the `if (_isPasswordFocused)` condition and related state management (`_isPasswordFocused`, `FocusNode` listener).
3. **Result:** The "Password Requirements" section is now always visible within the dialog, ensuring a consistent size regardless of field focus.

### Status of Redirect Fix

- Completed.

## Previous Objectives (Completed)

### Objective: Fix Redirect After Linking Google from Account Settings (Attempt 7)

### Context

- Using `setState` alone (Attempt 5) fixed the UI update delay but not the redirect. Re-adding selective invalidation (`firebaseUserProvider` in the linking provider - Attempt 4) also caused a redirect.
- The redirect seems linked to the timing of state updates and rebuilds after the linking operation completes.

### Actions Taken

1. **Removed Provider Invalidation (Again):** Ensured no explicit invalidation happens within `linkGoogleToEmailPasswordProvider`.
2. **Invalidate + Delay + Rebuild:** Modified `_linkWithGoogle` in `account_settings_page.dart`:
    - After successful `await` on the linking future:
    - Manually call `ref.invalidate(firebaseUserProvider)`.
    - Add a short `Future.delayed(const Duration(milliseconds: 100))`.
    - Call `setState(() {})` to force a local rebuild.
3. **Rationale:** Invalidate the user data provider, give a brief moment for state propagation/potential navigation events to settle, then force a local rebuild to hopefully pick up the correct, updated state without triggering the redirect.

### Status

- Completed. User testing confirmed this combination finally resolved the redirect issue while maintaining the UI update.

### Objective: Fix Redirect After Linking Google from Account Settings (Attempt 2)

- **Context:** Linking Google from Account Settings caused an unwanted redirect and `Duplicate GlobalKey` error due to the `StatefulShellRoute` rebuilding after the auth state change.
- **Action:** Moved the `/profile/account` route definition in `app_router.dart` outside the `StatefulShellRoute` branches. Reverted the `isLinkingProvider` attempt.
- **Status:** Completed. `GlobalKey` error resolved, but redirect issue persisted.

### Objective: Fix System Back Gesture from Auth/Register Pages (Final)

- **Context:** System back gesture didn't work correctly on `RegisterPage` after AppBar back button was fixed.
- **Action:** Corrected `PopScope` usage in `AuthPage` and `RegisterPage` using `onPopInvokedWithResult`.
- **Status:** Completed. System back gesture now navigates to `/profile` from `/auth` and `/register`.
