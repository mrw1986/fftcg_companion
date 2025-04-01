# Current Task

## Previous Objectives (Completed)

1. **Improve Email Verification UI and Profile Page Aesthetics (Objective 28)**
    * Updated `ProfilePage` to show standard account/app settings for unverified users, applied gradient background, and used Card widgets for structure. Fixed `withOpacity` usage.
    * Updated `AccountSettingsPage` to display a prominent banner for unverified users with limitations and a "Resend Verification Email" button. Fixed unnecessary null assertion.

2. **Data Migration and Firestore Rules Updates (Objective 27)**
    * Updated `firestore.rules`: Modified the `allow update` rule for `/users/{userId}` to permit updates where `collectionCount` is present but unchanged.
    * Updated `UserRepository.createUserFromAuth`: Modified the code to initialize `collectionCount: 0` directly when creating a *new* user document.
    * Updated `AuthService.linkGoogleToAnonymous`: Moved the `_userRepository.createUserFromAuth` call to occur *only after* the sign-out/sign-in process completes.
    * **Testing Still Required:** Verify fixes by testing anonymous sign-in, account deletion, and anonymous-to-Google linking flows.

3. **Fixed Email Update Flow and UI Updates (Objective 26)**
    * Fixed UI not updating after linking Google authentication.
    * Improved email update messaging based on auth methods.
    * Enhanced user experience with immediate UI updates and clearer messaging.

4. **Fixed Authentication State & UI Issues (Objective 26 - Ongoing Testing)**
    * Implemented security enhancements (50-card limit, 7-day verification grace period, daily limits dialog).
    * Fixed authentication method order consistency in UI.
    * Corrected provider unlinking logic and state invalidation.
    * Fixed state handling after account deletion.
    * Corrected Google sign-in logic fallback.
    * Fixed email display and pre-population issues.
    * Fixed profile page banner logic.
    * Implemented data migration for anonymous users linking with Google (collection only).
    * Refined Google linking state management.

5. **Authentication System Rebuild**
    * Completed full rebuild of authentication system.

6. **UI/UX Improvements**
    * Enhanced dialog styling, error messages, loading states.

7. **Security Enhancements**
    * Implemented proper Firestore rules, re-authentication flows.

## Current Objective 30 (Completed - Google Auth Display Name Fix)

Fix Google Authentication Display Name Not Storing in Firestore

### Context

When a user creates an account with Google authentication, the display name is correctly showing in the UI but was not being stored in Firestore. The `displayName` field in Firestore remained null despite the UI showing the correct name from Google.

### Goal

Ensure that when a user signs in with Google, their display name from Google is properly stored in the Firestore user document.

### Changes Made

1. **Enhanced Logging in `auth_service.dart`:**
   * Added detailed logging to track the display name at various stages of the Google sign-in process:
     * When the Google user is obtained: `talker.debug('Google user display name: ${googleUser.displayName}');`
     * When the Firebase user is created: `talker.debug('Firebase user display name: ${userCredential.user?.displayName}');`
     * After the user is reloaded: `talker.debug('Refreshed user display name: ${refreshedUser.displayName}');`
   * Similar logging was added to the Google linking process.

2. **Modified `UserRepository.createUserFromAuth` Method:**
   * Added code to extract the display name directly from the Google provider data:

   ```dart
   // Get the provider data to check for Google sign-in
   final providerData = authUser.providerData;
   String? googleDisplayName;
   
   // Check if user is signed in with Google
   for (var provider in providerData) {
     if (provider.providerId == 'google.com') {
       // Log the provider display name
       talker.debug('Google provider display name: ${provider.displayName}');
       googleDisplayName = provider.displayName;
       break;
     }
   }
   ```

   * Updated the logic to prioritize the Google provider display name:
     * For existing users: `displayName: (existingUser.displayName != null && existingUser.displayName!.isNotEmpty) ? existingUser.displayName : googleDisplayName ?? authUser.displayName`
     * For new users: `displayName: googleDisplayName ?? authUser.displayName`
   * This ensures that the display name from Google is correctly used when creating or updating the user document in Firestore.

### Testing Results

The changes were successful. When a user signs in with Google:

1. The display name is correctly extracted from the Google provider data
2. The display name is properly stored in the Firestore user document
3. The UI correctly displays the name from Google

There is a secondary issue with the Account Limits dialog appearing after Google sign-in, but that's a separate concern from the original display name problem which has been resolved.

## Next Steps

1. **Test Firestore Permission Fix (Critical - Objective 27):**
   * [ ] Test account deletion flow (triggers anonymous sign-in, check for user doc creation with `collectionCount: 0`).
   * [ ] **Test anonymous user linking to Google account (Primary test for this fix, check for user doc creation/update with `collectionCount`).**
   * [ ] Verify user document creation for new anonymous users (initial app start).
   * [ ] Test standard operations (collection add/update, settings changes) for both anonymous and authenticated users.
   * [ ] Specifically check Firestore logs for permission errors during these tests.

2. **Address Account Limits Dialog Issue (Completed - Objective 31):**
   * The Account Limits dialog no longer appears after cancelling Google sign-in or linking.
   * The fix involved modifying the auto-sign-in logic in `auto_auth_provider.dart` to pass `isInternalAuthFlow=true` when creating temporary anonymous users.
   * This ensures the dialog timestamp isn't reset during internal auth flows like Google sign-in.
   * The dialog now only appears for actual anonymous sign-ins, not during temporary auth state changes.

3. **Continue Authentication System Testing:**
   * [ ] Test Google linking flow thoroughly.
   * [ ] Verify all edge cases are handled.
   * [ ] Ensure proper state transitions.

4. **Expand Data Migration (If Step 1 Successful):**
   * [ ] Implement deck data migration.
   * [ ] Add user settings migration.
   * [ ] Include user preferences migration.
   * [ ] Add progress indicators.
   * [ ] Implement rollback mechanisms.

5. **Future Features (After Migration Fix):**
   * Implement deck builder feature
   * Add card scanner functionality
   * Develop price tracking system
   * Add collection import/export
   * Implement collection sharing
   * Add favorites and wishlist
   * Enhance filtering options
   * Add batch operations

## Completed Objective 31 (Account Limits Dialog Issue)**

Prevented the Account Limits dialog from appearing after cancelling Google sign-in or linking:

* Modified the auto-sign-in logic in `auto_auth_provider.dart` to pass `isInternalAuthFlow=true` when creating temporary anonymous users.
* This ensures the dialog timestamp isn't reset during internal auth flows like Google sign-in.
* The dialog will now only appear for actual anonymous sign-ins, not during temporary auth state changes.

Testing Results:

* When cancelling Google sign-in, the "Google sign-in was cancelled" SnackBar appears.
* The Account Limits dialog does not appear since the anonymous sign-in is part of an internal auth flow.
* The dialog still appears normally for actual anonymous users.
