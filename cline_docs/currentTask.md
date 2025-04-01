# Current Task

## Previous Objectives (Completed)

1. **Data Migration and Firestore Rules Updates (Objective 27)**
    - Updated Firestore rules to handle migrations:
        - Added special case for collection updates during migration
        - Added permission for initial user document creation
        - Relaxed validation during migration to allow transferring data
    - Improved data migration process:
        - Create user document before attempting data migration
        - Handle all merge cases (discard, merge, overwrite)
        - Add better error handling and logging
        - Continue with sign-in even if migration fails

2. **Fixed Email Update Flow and UI Updates (Objective 26)**
    - Fixed UI not updating after linking Google authentication:
        - Added explicit provider invalidation after successful Google linking
        - Ensured UI immediately reflects newly linked authentication methods
        - Updated email update messaging to be dynamic based on auth methods
    - Improved email update messaging:
        - Note text and dialogs now show correct message based on auth methods
        - Users with Google auth are informed they'll remain logged in
        - Users with only email/password are informed they'll be logged out
    - Enhanced user experience:
        - UI updates immediately when linking/unlinking authentication methods
        - Messages adapt in real-time to authentication state changes
        - Clearer communication about email update consequences

3. **Fixed Authentication State & UI Issues (Objective 26 - Ongoing Testing)**
    - Implemented security enhancements and user notifications:
        - Added 50-card limit for anonymous users with collectionCount tracking
        - Added 7-day grace period for email verification
        - Created daily account limits dialog to inform users about:
          - Anonymous user card limits
          - Email verification requirements
          - Direct links to sign in, register, or resend verification
    - Fixed authentication method order consistency in UI:
        - Email/Password (or Add Email/Password) always appears first
        - Google (or Add Google) always appears second
        - Order remains consistent even after unlinking/relinking methods
    - Corrected provider unlinking logic in `AuthService` to prevent removing the last provider incorrectly.
    - Improved state invalidation in `auth_provider` for `unlinkProviderProvider` to ensure UI updates.
    - Fixed state handling after account deletion in `account_settings_page` to allow immediate anonymous sign-in.
    - Corrected Google sign-in logic in `auth_page.dart` to handle state transitions after sign-out more robustly (fallback from link to sign-in).
    - Fixed email display for password provider in `ProfileAuthMethods`.
    - Ensured `AccountSettingsPage` watches `currentUserProvider` for reliable UI updates.
    - Corrected email pre-population logic in `LinkEmailPasswordDialog` by passing data reliably from `AccountInfoCard`.
    - Fixed profile page banner logic (`profile_page.dart`) to only show email verification warning when appropriate (`AuthStatus.emailNotVerified`).
    - Implemented data migration for anonymous users linking with Google accounts:
        - Added `merge_data_decision_dialog.dart` for user confirmation
        - Created `collection_merge_helper.dart` for data migration logic
        - Fixed timing of data migration to occur after successful sign-in
        - Added proper BuildContext handling for async operations
        - Ensured anonymous user data is preserved until migration decision
        - **Note:** Data migration currently only handles collection data. Need to expand to include decks, settings, and preferences.
    - **Refined Google linking state management:**
        - Updated `auth_page.dart` to set `skipAutoAuthProvider` flag during Google linking.
        - Modified `auto_auth_provider.dart` to reset the flag only for fully authenticated users.
        - Updated `auth_service.dart` to explicitly sign out from Google and Firebase with delays, and added more logging during the sign-out/sign-in process for linking.

4. **Authentication System Rebuild**

- Completed full rebuild of authentication system
- Implemented all core authentication flows
- Added data migration support
- Fixed state management issues
- Improved error handling

1. **UI/UX Improvements**

- Enhanced dialog styling
- Improved error messages
- Added loading states
- Fixed navigation issues

1. **Security Enhancements**

- Implemented proper Firestore rules
- Added re-authentication flows
- Enhanced data protection

## Current Objective 27 (Fix Applied - Testing Needed)

Fix Firestore Permission Issues During Data Migration

### Context

After implementing data migration for anonymous users linking with Google accounts, we encountered permission denied errors during the migration process and also during initial user document creation for newly signed-in anonymous users (e.g., after account deletion). These issues appeared related to Firestore security rules not properly handling the initial document creation, or the application attempting writes that violated specific rule conditions.

### Goal

Resolve Firestore permission issues to ensure smooth user document creation and subsequent data migration when linking anonymous accounts, while maintaining proper security rules.

### Changes Made (Fix Attempt 4)

1. **Updated `firestore.rules`:**
    - **Identified Root Cause:** The `allow update` rule for `/users/{userId}` was too strict regarding the `collectionCount` field. It prevented updates (including those done via `set(..., merge: true)` when the document exists) if `collectionCount` was present in the request but its value was unchanged, which happens during the `createUserFromAuth` call after Google linking.
    - **Applied Fix:** Modified the `allow update` rule to explicitly permit the update if `collectionCount` is present in the request and its value is equal to the existing value (`request.resource.data.collectionCount == resource.data.collectionCount`).

2. **Updated `UserRepository.createUserFromAuth` (Previous Fix Attempt 3):**
    - Modified the code to initialize `collectionCount: 0` directly within the `UserModel` when creating a *new* user document. This ensures the field is included in the initial `create` operation (which the rules permit) and removes the problematic second write attempt.

3. **Updated `AuthService.linkGoogleToAnonymous` (Previous Fix Attempt 2):**
    - Moved the `_userRepository.createUserFromAuth` call to execute *only after* the sign-out/sign-in dance completes successfully. This ensures the Firestore write uses the correct, fully established Google user context.

### Implementation Plan (Revised)

1. **Test Firestore Permission Fix (Critical):**
    - Verify that new anonymous users (after deletion or initial sign-in) can successfully have their user document created *with* `collectionCount: 0`.
    - Test the account deletion flow again.
    - Test the anonymous-to-Google linking flow, ensuring the user document is correctly created/updated *after* the sign-out/sign-in process and includes `collectionCount`.
    - Ensure existing functionality (adding/updating collection items, decks, settings) still works correctly under the existing rules.
    - Verify security rules still prevent unauthorized access.

2. **Address Remaining Migration Issues (If Necessary):**
    - If permission errors persist specifically during the *data transfer* phase of migration (after user document creation is confirmed working), re-evaluate the rules for `/collections`, `/users/{userId}/settings`, etc., potentially requiring more specific migration rules or a Cloud Function approach.

3. **Improve Error Handling:**
    - Add better error messages for permission issues if they reappear.
    - Implement retry logic where appropriate.
    - Consider rollback capabilities for failed migrations.

### Authentication Flow Diagram (Relevant Portion - No Change Needed)

```mermaid
graph TD
    subgraph User Creation/Update
        A[User Signs In (New/Anon)] --> B{User Doc Exists?};
        B -- No --> C[App Tries to Create Doc (incl. collectionCount=0)];
        C -- Rules Allow? --> D[Create Success];
        C -- Rules Deny? --> E[PERMISSION DENIED];
        B -- Yes --> F[App Tries to Update Doc];
        F -- Rules Allow? --> G[Update Success];
        F -- Rules Deny? --> H[PERMISSION DENIED];
    end

    style C fill:#f9f,stroke:#333,stroke-width:2px
    style F fill:#ccf,stroke:#333,stroke-width:2px
    style E fill:#fdc,stroke:#333,stroke-width:2px
    style H fill:#fdc,stroke:#333,stroke-width:2px
    style D fill:#9f9,stroke:#333,stroke-width:2px
    style G fill:#9f9,stroke:#333,stroke-width:2px
```

## Next Steps

1. **Test Firestore Permission Fix (Critical):**
    - [ ] Test account deletion flow (triggers anonymous sign-in, check for user doc creation with `collectionCount: 0`).
    - [ ] **Test anonymous user linking to Google account (Primary test for this fix, check for user doc creation/update with `collectionCount`).**
    - [ ] Verify user document creation for new anonymous users (initial app start).
    - [ ] Test standard operations (collection add/update, settings changes) for both anonymous and authenticated users.
    - [ ] Specifically check Firestore logs for permission errors during these tests.

2. **Continue Authentication System Testing:**
    - [ ] Test Google linking flow thoroughly.
    - [ ] Verify all edge cases are handled.
    - [ ] Ensure proper state transitions.

3. **Expand Data Migration (If Step 1 Successful):**
    - [ ] Implement deck data migration.
    - [ ] Add user settings migration.
    - [ ] Include user preferences migration.
    - [ ] Add progress indicators.
    - [ ] Implement rollback mechanisms.

4. **Future Features (After Migration Fix):**
    - Implement deck builder feature
    - Add card scanner functionality
    - Develop price tracking system
    - Add collection import/export
    - Implement collection sharing
    - Add favorites and wishlist
    - Enhance filtering options
    - Add batch operations
