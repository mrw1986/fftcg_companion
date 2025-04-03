# Codebase Summary

## Recent Changes

### Fix Riverpod Error After Google Linking & Subsequent Analyzer Issues (Objective 46) - Completed (Testing Needed)

- **Context:** Google linking caused a Riverpod error (`Providers are not allowed to modify...`) due to `authStateProvider` modifying `emailVerificationDetectedProvider` during build. Fixing this revealed a dependency cycle and other analyzer errors.
- **Changes:**
  - **Riverpod Cycle Fix:** Removed incorrect `authStateListenerProvider`. Integrated logic to reset `emailVerificationDetectedProvider` into `firestoreUserSyncProvider`'s `ref.listen` callback, triggering on appropriate state changes (sign-out, verified, anonymous, error).
  - **Analyzer Fixes:** Added null safety checks in `auto_auth_provider.dart`. Added explicit types and null checks in `email_verification_checker.dart`. Added extra `mounted` check before navigation in `account_settings_page.dart` (`_handleSuccessfulDeletion`).
- **Status:** Fixes applied. Testing required for Google linking, email verification flow, and potential regressions.

### Refine Account Deletion Flow & Add Confirmation (Objective 45) - Completed (Testing Needed)

- **Context:** Account deletion required re-authentication but unnecessarily retried Firestore deletion. No success confirmation existed. The "Account Limits" dialog appeared after deletion. Firebase "Delete User Data" extension handles Firestore cleanup. A persistent analyzer error blocked `SnackbarHelper` usage. `use_build_context_synchronously` lint appeared.
- **Changes:**
  - Simplified `AuthService.deleteUser` to only delete the Auth user, relying on the Firebase extension for Firestore data. Handles `requires-recent-login` and `user-not-found`.
  - Updated `AccountSettingsPage` re-authentication logic (`_reauthenticateAndDeleteAccount`, `_reauthenticateWithGoogle`) to call the simplified `deleteUser` after successful re-auth.
  - Added `_handleSuccessfulDeletion` helper in `AccountSettingsPage` for Snackbar confirmation (using `display_name.showThemedSnackBar` as a workaround), sign-out (using `skipAccountLimitsDialog: true`), and navigation. **Added extra `if (mounted)` check before navigation (Obj 46).**
- **Status:** Fixes applied. Testing required.

### Fix "Unverified" Chip Logic (Objective 44) - Completed (Testing Needed)

- **Context:** The "Unverified" chip in `AccountSettingsPage` didn't update immediately after email verification, unlike the banner.
- **Changes:** Aligned the logic for the `isEmailNotVerified` parameter passed to `AccountInfoCard` to use the same condition as the verification banner (`authState.status == AuthStatus.emailNotVerified && !verificationDetected`).
- **Status:** Fix applied. Testing required to confirm consistent UI updates for both banner and chip.

### Fix Email Verification UI Update Delay (Objective 42 - Attempt 2) - Completed (Testing Needed)

- **Context:** Verification banner in `AccountSettingsPage` didn't update immediately.
- **Changes:** Implemented a hybrid approach using immediate Firestore update and `emailVerificationDetectedProvider`.
- **Status:** Fix applied. Testing required. (Chip logic addressed in Obj 44)

### Diagnose Google Linking Error and Consolidate User Creation Logic (Objective 41) - Completed

- **Context:** Google linking failed (`credential-already-in-use`), duplicated Firestore update logic. Riverpod error occurred during linking.
- **Changes:** Centralized Firestore updates via `firestoreUserSyncProvider`. Added router `redirect`/`errorBuilder`.
- **Result:** Google linking error resolved. Navigation fixed. Router improved. Revealed email verification UI delay (Obj 42). **Riverpod error during linking fixed in Obj 46.**

### Prevent Anonymous Dialog After Password Reset (Objective 40) - Completed

- **Context:** "Account Limits" dialog appeared after authenticated user password reset.
- **Changes:** Added `skipAccountLimitsDialog` flag to `AuthService.signOut`.
- **Status:** Implemented.

### Email Verification Status Update Fix (Objective 39) - Completed

- **Context:** Inconsistent Firestore `isVerified` field updates.
- **Changes:** Modified `email_verification_checker.dart` and `AuthService.handleEmailVerificationComplete`. (Flow further refined in Obj 41/42, state reset logic refined in Obj 46).
- **Status:** Implemented (UI timing addressed in Obj 42/44, state reset logic refined in Obj 46).

### Authentication Flow and Firestore Data Issues (Objective 38) - Superseded by Objective 41

- **Status:** Superseded.

### Fix Registration Routing Error (Objective 36) - Completed

- **Conclusion:** Navigation path correct.

### Update Registration Confirmation Text & Verify Navigation (Objective 35) - Completed

- **Conclusion:** Text consistent. Navigation correct.

### Correct Account Deletion Order (Objective 34) - Superseded by Objective 45

- **Conclusion:** Deletion flow order and error handling corrected and simplified in Objective 45.

### Ensure Firestore User Document is Fully Populated During Authentication (Objective 33)

- **Conclusion:** Implementation largely correct. Testing recommended.

### Fixed Google Authentication Display Name Issue (Objective 30)

- **Results:** Display name correctly stored.

### Firestore Permission Issues During Data Migration (Objective 27 - Fix Applied)

- **Pending Fixes:** Testing required.

### Email Update Flow and UI Improvements (Objective 26)

- Fixed UI not updating after linking Google.
- Improved email update messaging.

### Authentication State & UI Fixes (Objective 26 - Ongoing Testing)

- Corrected provider unlinking logic, state invalidation, state handling after deletion, Google sign-in fallback, email display/pre-population, profile banner logic.
- Implemented anonymous-to-Google data migration (collection only).
- Refined Google linking state management.

### Authentication System Rebuild (Completed - Objective 26)

- Completed full rebuild of `AuthService` and related integrations.

## Key Components

### Auth Service (lib/core/services/auth_service.dart) - **Refactored & Updated (Obj 45)**

- **Status:** Centralized Firestore user document creation/updates via `firestoreUserSyncProvider` (listening to `firebaseUserProvider`), *except* for `linkEmailAndPasswordToAnonymous`. `handleEmailVerificationComplete` no longer updates Firestore directly. `signOut` accepts `skipAccountLimitsDialog`. **`deleteUser` now *only* deletes the Firebase Auth user (relying on Firebase Extension for Firestore data) and specifically ignores `user-not-found` errors during Auth deletion.**
- **Pending:** Test deletion flow.

### User Repository (lib/features/profile/data/repositories/user_repository.dart)

- **Status:** `createUserFromAuth` handles initialization/updates. `deleteUser` removes Firestore doc. Called by `firestoreUserSyncProvider`, `AuthService.linkEmailAndPasswordToAnonymous`, and `email_verification_checker`. **No longer called directly by `AuthService.deleteUser`.**
- **Pending:** Testing required.

### Firestore Rules (firestore.rules) - **Refined**

- **Status:** Updated `allow update` rule for `/users/{userId}`.
- **Pending:** Testing required, especially regarding deletion permissions (though less critical now with the Firebase Extension handling data deletion).

#### Riverpod Providers (lib/core/providers/)

- **`auth_provider.dart`:** **Updated (Objective 46)**
  - `authStateProvider`: Calculates `AuthState` based on `firebaseUserProvider`. No longer attempts to modify other providers directly.
  - `firestoreUserSyncProvider`: Listens to `firebaseUserProvider`. Handles Firestore sync **and** resets `emailVerificationDetectedProvider` based on user state changes (sign-out, verified, anonymous, error).
  - Removed incorrect `authStateListenerProvider`.
- **`email_verification_checker.dart`:** **Updated (Objective 42 - Attempt 2, Obj 46)** Polls `user.reload()`. Updates Firestore immediately and sets `emailVerificationDetectedProvider` on verification. Added null safety checks. **Testing needed.**
- **`firestoreUserSyncProvider`:** Listens to `firebaseUserProvider` for eventual consistency updates. **Also handles resetting `emailVerificationDetectedProvider` (Obj 46).**
- **`emailVerificationDetectedProvider`:** **NEW (Objective 42 - Attempt 2)** Simple `StateProvider<bool>` for immediate UI banner hiding. Reset logic moved to `firestoreUserSyncProvider`.
- **`auto_auth_provider.dart`:** **Updated (Objective 46)** Added null safety checks in listener.
- Core auth state and action providers.

#### Profile Page Components

- **`account_settings_page.dart`:** **Updated (Objective 42, 44, 45, 46)** Manages account details, re-auth. Watches providers for verification banner. Added `if (mounted)` checks (including extra check before navigation in `_handleSuccessfulDeletion`). **Aligned "Unverified" chip logic with banner logic.** **Added `_handleSuccessfulDeletion` helper for Snackbar confirmation (using workaround), sign-out (using `skipAccountLimitsDialog: true`), and navigation.** Calls simplified `AuthService.deleteUser` directly and after re-auth.

#### Authentication Pages

- **`register_page.dart`:** Relies on router redirect logic.
- **`reset_password_page.dart`:** **Updated** to call `signOut` with `skipAccountLimitsDialog: true`.

## Data Flow (Refactored & Updated)

- **Authentication Flow (Rebuilt & Refined - Testing)**
- **Firestore User Document Creation/Update:** (Flow unchanged)
    1. Firebase Auth state changes.
    2. `firebaseUserProvider` emits `User`.
    3. `firestoreUserSyncProvider` detects change.
    4. Calls `UserRepository.createUserFromAuth`.
    5. `UserRepository` updates Firestore.
    6. **Exception:** `AuthService.linkEmailAndPasswordToAnonymous` calls `UserRepository.createUserFromAuth` directly.
- **Email Verification Flow (Fixed - Attempt 2 - Testing Needed - Obj 42, 44, 46)**
    1. Checker polls `user.reload()`.
    2. Detects `emailVerified == true`.
    3. Checker calls `UserRepository.createUserFromAuth`.
    4. Checker sets `emailVerificationDetectedProvider` to `true`.
    5. Checker cancels timer.
    6. UI hides banner **and "Unverified" chip** via `emailVerificationDetectedProvider` and `authStateProvider` status check.
    7. Firebase stream eventually emits updated `User`.
    8. `firestoreUserSyncProvider` listener detects verified user, resets `emailVerificationDetectedProvider` to `false`.
    9. `authStateProvider` updates based on stream.
- **Password Reset Flow (Updated)** (Flow unchanged)
    1. User initiates reset.
    2. UI calls `AuthService.sendPasswordResetEmail()`.
    3. UI calls `AuthService.signOut(skipAccountLimitsDialog: true)`.
    4. `AuthService` signs out, skipping timestamp reset.
- **Account Deletion Flow (Updated - Objective 45 & 46 - Simplified)**
    1. User initiates deletion.
    2. UI calls `AuthService.deleteUser()`.
    3. `AuthService` attempts to delete Auth user (`currentUser.delete()`). **(Firestore data handled by Firebase Extension)**.
    4. **If Auth delete fails:**
        - **If error is `user-not-found`:** Log warning, **do not rethrow**. Treat as success.
        - **If error is `requires-recent-login`:** Rethrow error. UI handles re-auth prompt -> Retry step 2.
        - **If other Auth error:** Rethrow error. UI handles error.
    5. **If Auth delete succeeds (or `user-not-found` ignored):** `AuthService` completes successfully. UI calls `_handleSuccessfulDeletion` helper (shows Snackbar, signs out using `skipAccountLimitsDialog: true`, navigates with extra `mounted` check).
    6. `AccountSettingsPage` includes `if (mounted)` checks before `setState` calls in the re-authentication flow.

```mermaid
graph TD
    subgraph Entry Points
        A[App Start] --> B{User Signed In?};
        C[Login/Register Page] --> D{Choose Method};
    end

    subgraph Auth State Listener (firestoreUserSyncProvider)
        ListenAuthState[Listen to firebaseUserProvider] --> UserEvent{User Data Changed?};
        UserEvent -- Yes --> CheckResetFlag{Need to Reset Verification Flag?};
        CheckResetFlag -- Yes --> ResetFlag[Reset emailVerificationDetectedProvider=false];
        CheckResetFlag -- No --> CheckSyncNeeded{Need Firestore Sync?};
        ResetFlag --> CheckSyncNeeded;
        CheckSyncNeeded -- Yes --> CallCreateUser[Call UserRepository.createUserFromAuth(user)];
        CallCreateUser --> FirestoreUpdate[Firestore Doc Updated];
        CheckSyncNeeded -- No --> NoOp[No Firestore Action];
        UserEvent -- No --> NoOp;
    end

    subgraph Anonymous Flow
        B -- No --> AnonSignIn[Sign In Anonymously];
        AnonSignIn --> AuthState;
        Anon[Anonymous User] -- Link --> LinkChoice{Link Email/Pass or Google?};
        LinkChoice -- Email/Pass --> LinkEmailPass[AuthService.linkEmailAndPasswordToAnonymous];
        LinkEmailPass --> UpdateFirestoreAnon[Immediate Firestore Update in AuthService];
        UpdateFirestoreAnon --> AuthState;
        LinkChoice -- Google --> LinkGoogle[AuthService.linkGoogleToAnonymous];
        LinkGoogle -- Exists --> MergePrompt{Merge Data?};
        MergePrompt -- Yes --> MigrateData[Migrate Data];
        MergePrompt -- No --> DiscardData[Keep Google Data];
        MigrateData --> SignOutSignIn[Sign Out & Sign In w/ Google];
        DiscardData --> SignOutSignIn;
        LinkGoogle -- Success --> SignOutSignIn;
        SignOutSignIn --> AuthState;
    end

    subgraph Email/Password Flow
        D -- Email/Pass --> EmailChoice{Register or Login?};
        EmailChoice -- Register --> RegisterEmail[Register + Send Verification];
        EmailChoice -- Login --> LoginEmail[Login Email/Pass];
        RegisterEmail --> ShowVerifyDialog[Show Verification Dialog];
        ShowVerifyDialog -- OK Clicked --> StartChecker[Start Email Verification Checker];
        StartChecker --> AuthState;
        LoginEmail --> AuthState;
        EmailUser[Email/Pass User] -- Actions --> OtherActions[Other Account Actions];
        EmailUser -- Unverified --> StartChecker2[Start Email Verification Checker];
    end

    subgraph Email Verification Check Flow (Fixed - Attempt 2 - Testing Needed - Obj 42, 44, 46)
        StartChecker --> LoopCheck{Checker: Periodically Reload User};
        StartChecker2 --> LoopCheck;
        LoopCheck -- Verified? --> IsVerified{emailVerified == true?};
        IsVerified -- No --> LoopCheck;
        IsVerified -- Yes --> UpdateFirestoreChecker[Checker: Update Firestore Immediately];
        UpdateFirestoreChecker --> SetDetectionFlag[Checker: Set emailVerificationDetectedProvider=true];
        SetDetectionFlag --> CancelTimer[Checker: Cancel Timer];
        SetDetectionFlag --> UpdateUIImmediate[UI Hides Banner & Chip Immediately];
        CancelTimer --> StreamEmit{Firebase Stream Emits Updated User};
        StreamEmit --> AuthState;
    end

    subgraph Google Flow
        D -- Google --> LoginGoogle[Login/Register with Google];
        LoginGoogle --> AuthState;
        GoogleUser[Google User] -- Actions --> OtherActions2[Other Account Actions];
    end

    subgraph Password Reset Flow
        ResetPage[Reset Password Page] -- Authenticated User --> SendResetEmail[UI Calls AuthService.sendPasswordResetEmail];
        SendResetEmail --> SignOutWithFlag[UI Calls AuthService.signOut(skipAccountLimitsDialog=true)];
        SignOutWithFlag --> SkipTimestampReset[AuthService: Skips Hive Timestamp Reset];
        SkipTimestampReset --> SignOutFirebase[AuthService: Signs out Firebase/Google];
        SignOutFirebase --> AuthState;
        ResetPage -- Unauthenticated User --> SendResetEmail2[UI Calls AuthService.sendPasswordResetEmail];
        SendResetEmail2 --> ShowSuccessMessage[UI Shows Success Message];
    end

    subgraph Common Actions
        B -- Yes --> SignedInUser;
        SignedInUser --> ActionChoice{Choose Action};
        ActionChoice -- Sign Out --> SignOutNormal[UI Calls AuthService.signOut];
        SignOutNormal --> ResetTimestamp[AuthService: Resets Hive Timestamp];
        ResetTimestamp --> SignOutFirebase2[AuthService: Signs out Firebase/Google];
        SignOutFirebase2 --> AuthState;
        ActionChoice -- Delete Account --> AttemptDelete[UI Calls AuthService.deleteUser];
        AttemptDelete --> DeleteAuth{AuthService: Delete Auth User}; %% Removed Firestore Step
        DeleteAuth -- Success --> HandleSuccess[UI Calls _handleSuccessfulDeletion Helper];
        DeleteAuth -- Failure --> HandleAuthError{Auth Error?};
        HandleAuthError -- user-not-found --> LogWarning[Log Warning (Ignore Error)];
        LogWarning --> HandleSuccess; %% Treat as success
        HandleAuthError -- requires-recent-login --> HandleReauth[UI Handles Re-auth Prompt];
        HandleAuthError -- Other --> HandleOtherAuthError[UI Handles Error];
        HandleReauth -- User Re-authenticates --> AttemptDelete; %% Retry the same simplified delete
        HandleReauth -- User Cancels --> SignedInUser;
        HandleSuccess --> ShowSnackbar[Helper: Show Success Snackbar];
        ShowSnackbar --> FinalSignOut[Helper: Sign Out User (skipAccountLimitsDialog=true)]; %% Updated Node Text
        FinalSignOut --> NavigateAway[Helper: Navigate Away (with mounted check)]; %% Updated Node Text
        NavigateAway --> AuthState;
    end

    subgraph State & UI
        AuthState[Auth State Change] --> ListenAuthState;
        AuthState --> UpdateUIMain[Update UI via AuthState];
        AuthState --> RouterRedirect[Router Redirect Logic];
    end

    style NavigateToAccount1 fill:#c9ffc9,stroke:#333,stroke-width:1px
    style NavigateToAccount2 fill:#c9ffc9,stroke:#333,stroke-width:1px
    style NavigateToAccount3 fill:#c9ffc9,stroke:#333,stroke-width:1px
    style NavigateToAccount4 fill:#c9ffc9,stroke:#333,stroke-width:1px
    style ShowVerifyDialog fill:#ffffcc,stroke:#333,stroke-width:1px
    style DeleteAuth fill:#ffcccc,stroke:#333,stroke-width:2px
    style HandleReauth fill:#fdc,stroke:#333,stroke-width:2px
    style LoopCheck fill:#e0f7fa,stroke:#00796b,stroke-width:1px
    style IsVerified fill:#fff9c4,stroke:#fbc02d,stroke-width:2px
    style UpdateFirestoreChecker fill:#ffcc80,stroke:#ef6c00,stroke-width:2px
    style SetDetectionFlag fill:#ffecb3,stroke:#ffa000,stroke-width:1px
    style CancelTimer fill:#ffecb3,stroke:#ffa000,stroke-width:1px
    style UpdateUIImmediate fill:#c8e6c9,stroke:#388e3c,stroke-width:2px
    style StreamEmit fill:#dcedc8,stroke:#689f38,stroke-width:1px
    style SignOutWithFlag fill:#cce5ff,stroke:#005cb2,stroke-width:1px
    style SkipTimestampReset fill:#cce5ff,stroke:#005cb2,stroke-width:1px
    style SignOutFirebase fill:#cce5ff,stroke:#005cb2,stroke-width:1px
    style SignOutNormal fill:#e1f5fe,stroke:#0277bd,stroke-width:1px
    style ResetTimestamp fill:#e1f5fe,stroke:#0277bd,stroke-width:1px
    style SignOutFirebase2 fill:#e1f5fe,stroke:#0277bd,stroke-width:1px
    style ListenAuthState fill:#d1c4e9,stroke:#512da8,stroke-width:2px
    style UserEvent fill:#d1c4e9,stroke:#512da8,stroke-width:1px
    style CallCreateUser fill:#d1c4e9,stroke:#512da8,stroke-width:1px
    style FirestoreUpdate fill:#b39ddb,stroke:#512da8,stroke-width:1px
    style NoOp fill:#eee,stroke:#999,stroke-width:1px
    style UpdateFirestoreAnon fill:#ffcc80,stroke:#ef6c00,stroke-width:2px
    style UpdateUIMain fill:#e1f5fe,stroke:#0277bd,stroke-width:1px
    style HandleAuthError fill:#ffebcc,stroke:#ff8f00,stroke-width:2px
    style LogWarning fill:#fff9c4,stroke:#fbc02d,stroke-width:1px
    style HandleSuccess fill:#c8e6c9,stroke:#388e3c,stroke-width:2px
    style ShowSnackbar fill:#c8e6c9,stroke:#388e3c,stroke-width:1px
    style FinalSignOut fill:#c8e6c9,stroke:#388e3c,stroke-width:1px
    style NavigateAway fill:#c8e6c9,stroke:#388e3c,stroke-width:1px
    style CheckResetFlag fill:#d1c4e9,stroke:#512da8,stroke-width:1px
    style ResetFlag fill:#ffecb3,stroke:#ffa000,stroke-width:1px
    style CheckSyncNeeded fill:#d1c4e9,stroke:#512da8,stroke-width:1px
