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

## Current Objective 29 (Completed - Bug Fix & Enhancement)

Fix Display Name Update and Preserve Name During Google Link

### Context

1. **Update Bug:** When updating the display name via the profile settings, the change was reflected in Firebase Auth but not immediately updated in the corresponding Firestore user document. The Firestore update only occurred on a subsequent attempt.
2. **Linking Enhancement:** When linking a Google account to an existing Email/Password account that already had a custom display name set, the linking process would overwrite the custom name with the Google account's name.

### Goal

1. Ensure that updating the display name in the profile settings correctly updates both Firebase Auth and the Firestore user document simultaneously.
2. Preserve the user's existing custom display name in Firestore when they link a Google account, only using the Google name if no custom name was previously set.

### Changes Made

1. **Added `UserRepository.updateUserProfileData`:**
    * Created a new method specifically for updating profile fields (`displayName`, `photoURL`) in the Firestore user document using `_usersCollection.doc(userId).update()`. This avoids overwriting other fields unnecessarily.

2. **Modified `AuthService.updateProfile`:**
    * Changed the method to call the new `_userRepository.updateUserProfileData` after successfully updating the Firebase Auth profile (`currentUser.updateDisplayName`). This ensures the Firestore document is updated correctly with the new display name.

3. **Modified `UserRepository.createUserFromAuth`:**
    * Updated the logic within the `existingUser != null` block.
    * When constructing the `updatedUser` using `copyWith`, it now checks if `existingUser.displayName` is already set (not null and not empty).
    * If an existing name is present, it's preserved (`displayName: existingUser.displayName`).
    * If no existing name is set, it falls back to using the name from the `authUser` (e.g., the newly linked Google account's name) (`displayName: authUser.displayName`).

### Implementation Plan

1. **Test Display Name Update Fix:**
    * Sign in with an existing account (or create one).
    * Go to Account Settings.
    * Change the Display Name and tap Update.
    * Verify the success SnackBar appears.
    * **Crucially, check Firestore immediately** to confirm the `displayName` field in the user document has been updated correctly on the *first* attempt.
    * Refresh the Account Settings page (e.g., navigate away and back) and verify the updated name is displayed.

2. **Test Display Name Preservation During Google Link:**
    * **Scenario A (Existing Name):**
        * Create an account with Email/Password.
        * Set a custom Display Name in Account Settings (e.g., "MyCustomName"). Verify it saves to Firestore.
        * Link a Google account via Account Settings.
        * After linking, check Firestore: the `displayName` should still be "MyCustomName", not the Google account name.
        * Verify the UI also shows "MyCustomName".
    * **Scenario B (No Existing Name):**
        * Create an account with Email/Password.
        * Do *not* set a custom Display Name (leave it as null or empty in Firestore).
        * Link a Google account via Account Settings.
        * After linking, check Firestore: the `displayName` should now be populated with the Google account's name.
        * Verify the UI shows the Google account name.

## Next Steps

1. **Test Display Name Update Fix (Critical - Objective 29).**
2. **Test Display Name Preservation During Google Link (Critical - Objective 29).**
3. **Test New Email Verification UI Flow (Critical - Objective 28).**
4. **Test Profile Page Visuals (Objective 28).**
5. **Test Firestore Permission Fix (Critical - Objective 27):**
    * [ ] Test account deletion flow (triggers anonymous sign-in, check for user doc creation with `collectionCount: 0`).
    * [ ] **Test anonymous user linking to Google account (Primary test for this fix, check for user doc creation/update with `collectionCount`).**
    * [ ] Verify user document creation for new anonymous users (initial app start).
    * [ ] Test standard operations (collection add/update, settings changes) for both anonymous and authenticated users.
    * [ ] Specifically check Firestore logs for permission errors during these tests.

6. **Continue Authentication System Testing:**
    * [ ] Test Google linking flow thoroughly.
    * [ ] Verify all edge cases are handled.
    * [ ] Ensure proper state transitions.

7. **Expand Data Migration (If Step 5 Successful):**
    * [ ] Implement deck data migration.
    * [ ] Add user settings migration.
    * [ ] Include user preferences migration.
    * [ ] Add progress indicators.
    * [ ] Implement rollback mechanisms.

8. **Future Features (After Migration Fix):**
    * Implement deck builder feature
    * Add card scanner functionality
    * Develop price tracking system
    * Add collection import/export
    * Implement collection sharing
    * Add favorites and wishlist
    * Enhance filtering options
    * Add batch operations
