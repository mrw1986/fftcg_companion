# Codebase Summary

## Recent Changes

### Prevent Anonymous Dialog After Password Reset (Objective 40) - Completed

- **Context:** Fixed issue where the "Account Limits" dialog appeared confusingly after an authenticated user initiated a password reset and was logged out.
- **Changes:**
  - Modified `AuthService.signOut` to accept a `skipAccountLimitsDialog` flag. When true, the Hive timestamp for the dialog is not reset.
  - Updated the `signOut` call in `reset_password_page.dart` (after sending the reset email) to pass `skipAccountLimitsDialog: true`.
- **Status:** Implemented.
- **Next Steps:** Test the password reset flow for authenticated users as detailed in `currentTask.md`.

### Email Verification Status Update Fix (Objective 39) - Completed

- **Context:** Fixed inconsistency in Firestore `isVerified` field updates after email verification.
- **Changes:**
  - Enhanced `email_verification_checker.dart` to stop immediately after verification and pass the verified `User` object directly to `AuthService`.
  - Modified `AuthService.handleEmailVerificationComplete` to accept the verified `User` object, ensuring consistent state for Firestore updates.
- **Status:** Implemented.
- **Next Steps:** Test email verification and email update flows as detailed in `currentTask.md`.

### Authentication Flow and Firestore Data Issues (Objective 38) - In Progress

- **Context:** Changes made during registration routing fix (Objective 36) have caused issues with user document creation and state management.
- **Issues:**
  - User document creation now occurs in multiple places:
    - AuthService's createUserWithEmailAndPassword
    - AuthService's signInWithGoogle
    - Direct UserRepository calls in RegisterPage
  - Potential race conditions between Auth state and Firestore updates
  - UI state inconsistencies after registration
- **Status:** Under investigation
- **Next Steps:** Centralize user document creation in AuthService, remove direct repository calls

### Fix Registration Routing Error (Objective 36) - Completed

- **Context:** A `GoException: no routes for location: /profile/account-settings` error occurred after registration.
- **Analysis:** Reviewed `app_router.dart` and found the correct path for `AccountSettingsPage` is `/profile/account`. Reviewed `register_page.dart` and found three instances where `context.go('/profile/account-settings')` was used incorrectly.
- **Changes Made:** Corrected the navigation paths in `register_page.dart` to use `context.go('/profile/account')` in the `_registerWithEmailAndPassword` and `_signInWithGoogle` methods.
- **Conclusion:** The navigation path after registration is now correct.

### Update Registration Confirmation Text & Verify Navigation (Objective 35) - Completed

- **Context:** The confirmation message after email/password registration was misleading, and navigation needed verification.
- **Changes Made:**
  - Updated the confirmation dialog text in `register_page.dart`'s `_registerWithEmailAndPassword` method to accurately state that the user is signed in but unverified with limited capabilities until verification, matching the text in `account_settings_page.dart`.
- **Analysis:**
  - Reviewed navigation logic in `register_page.dart` for both `_registerWithEmailAndPassword` and `_signInWithGoogle` methods.
  - **Correction:** While Objective 32 aimed to fix navigation, the routing error persisted. Objective 36 correctly identified and fixed the path issue. Navigation logic now correctly targets `/profile/account`.
- **Conclusion:** Registration confirmation text is consistent and accurate. Navigation logic is now confirmed correct after the fix in Objective 36.

### Correct Account Deletion Order (Objective 34)

- **Context:** The previous account deletion flow deleted Firestore data before the Firebase Auth user.
- **Changes Made:**
  - Modified `AuthService.deleteUser`: Reversed the order of operations (Auth delete first, then Firestore).
- **Analysis:** Confirmed UI (`account_settings_page.dart`) handles re-authentication correctly before calling `deleteUser`.
- **Conclusion:** Deletion flow is now safer. Testing recommended.

### Ensure Firestore User Document is Fully Populated During Authentication (Objective 33)

- **Context:** Verify `UserModel` data population during auth flows.
- **Analysis:** Confirmed existing implementation correctly populates/updates user documents.
- **Changes Made:** Refined `firestore.rules` to prevent `createdAt` updates.
- **Conclusion:** Implementation largely correct. Testing recommended.

### Fixed Google Authentication Display Name Issue (Objective 30)

- **Issue:** Google display name wasn't storing in Firestore.
- **Changes Made:** Enhanced logging, modified `UserRepository.createUserFromAuth`.
- **Results:** Display name correctly stored.

### Firestore Permission Issues During Data Migration (Objective 27 - Fix Applied)

- **Issue:** Permission denied errors during user document creation/update.
- **Changes Made:** Updated `firestore.rules`, `UserRepository.createUserFromAuth`, `AuthService.linkGoogleToAnonymous`.
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

### Auth Service (lib/core/services/auth_service.dart) - **Updated**

- **Status:** `handleEmailVerificationComplete` now accepts a verified `User` object. `signOut` now accepts a `skipAccountLimitsDialog` flag to prevent resetting the dialog timestamp in specific scenarios (like password reset). `deleteUser` method now deletes Firebase Auth user *before* deleting Firestore data.
- **Pending:** Testing required for deletion flow and Firestore permission fixes.

### User Repository (lib/features/profile/data/repositories/user_repository.dart)

- **Status:** `createUserFromAuth` handles initialization/updates, including `isVerified` status. `deleteUser` removes Firestore doc.
- **Pending:** Testing required.

### Firestore Rules (firestore.rules) - **Refined**

- **Status:** Updated `allow update` rule for `/users/{userId}`.
- **Pending:** Testing required.

#### Riverpod Providers (lib/core/providers/)

- **`email_verification_checker.dart`:** **Updated** to stop timer immediately upon verification and pass the verified `User` object to `AuthService`.
- Core auth state and action providers.

#### Profile Page Components

- **`account_settings_page.dart`:** Manages account details. Handles re-auth before deletion. Contains source-of-truth verification banner text. Route: `/profile/account`.

#### Authentication Pages

- **`register_page.dart`:** Handles registration/linking. **Confirmation text updated. Navigation logic corrected to use `/profile/account`.**
- **`reset_password_page.dart`:** **Updated** to call `signOut` with `skipAccountLimitsDialog: true` to prevent the anonymous dialog from showing after reset for an authenticated user.

## Data Flow

- **Authentication Flow (Rebuilt & Refined - Testing)**
- **Email Verification Flow (Updated)**
    1. User registers with Email/Password.
    2. `email_verification_checker` starts polling `user.reload()` and `user.emailVerified`.
    3. User clicks verification link in email.
    4. `email_verification_checker` detects `refreshedUser.emailVerified == true`.
    5. Checker cancels its timer.
    6. Checker calls `AuthService.handleEmailVerificationComplete(refreshedUser)`.
    7. `AuthService` calls `UserRepository.createUserFromAuth(refreshedUser)` using the passed-in verified user.
    8. `UserRepository` updates Firestore document `isVerified` field to `true`.
    9. Checker invalidates `authStateProvider` and refreshes router.
- **Password Reset Flow (Updated)**
    1. Authenticated user initiates reset from `reset_password_page.dart`.
    2. UI calls `AuthService.sendPasswordResetEmail()`.
    3. UI calls `AuthService.signOut(skipAccountLimitsDialog: true)`.
    4. `AuthService` signs out Firebase/Google.
    5. `AuthService` **skips** resetting the Hive timestamp for the limits dialog.
    6. Auth state changes, app likely falls back to anonymous state.
    7. Limits dialog condition is not met immediately due to timestamp not being reset.
- **Account Deletion Flow (Updated)**
    1. User initiates deletion.
    2. UI calls `AuthService.deleteUser()`.
    3. `AuthService` attempts Auth delete.
    4. **If Auth fails (re-auth):** UI handles re-auth prompt -> Retry step 2.
    5. **If Auth succeeds:** `AuthService` attempts Firestore delete (logs errors).
    6. UI handles final state.

```mermaid
graph TD
    subgraph Entry Points
        A[App Start] --> B{User Signed In?};
        C[Login/Register Page] --> D{Choose Method};
    end

    subgraph Anonymous Flow
        B -- No --> AnonSignIn[Sign In Anonymously];
        AnonSignIn --> CreateAnonDoc[Create Anon User Doc];
        CreateAnonDoc --> AuthState;
        Anon[Anonymous User] -- Link --> LinkChoice{Link Email/Pass or Google?};
        LinkChoice -- Email/Pass --> LinkEmailPass[Link Email/Pass Credential];
        LinkChoice -- Google --> LinkGoogle[Link Google Credential];
        LinkGoogle -- Exists --> MergePrompt{Merge Data?};
        MergePrompt -- Yes --> MigrateData[Migrate Data];
        MergePrompt -- No --> DiscardData[Keep Google Data];
        MigrateData --> SignOutSignIn[Sign Out & Sign In w/ Google];
        DiscardData --> SignOutSignIn;
        LinkEmailPass --> UpdateLinkedEmailDoc[Update Linked User Doc];
        UpdateLinkedEmailDoc --> NavigateToAccount1[Navigate to /profile/account];
        NavigateToAccount1 --> AuthState;
        LinkGoogle -- Success --> SignOutSignIn;
        SignOutSignIn --> UpdateGoogleDoc[Update Google User Doc];
        UpdateGoogleDoc --> NavigateToAccount2[Navigate to /profile/account];
        NavigateToAccount2 --> AuthState;
    end

    subgraph Email/Password Flow
        D -- Email/Pass --> EmailChoice{Register or Login?};
        EmailChoice -- Register --> RegisterEmail[Register + Send Verification];
        EmailChoice -- Login --> LoginEmail[Login Email/Pass];
        RegisterEmail --> CreateEmailDoc[Create User Doc];
        CreateEmailDoc --> ShowVerifyDialog[Show Verification Dialog (Updated Text)];
        ShowVerifyDialog -- OK Clicked --> NavigateToAccount3[Navigate to /profile/account];
        NavigateToAccount3 --> StartChecker[Start Email Verification Checker];
        StartChecker --> AuthState;
        LoginEmail --> UpdateEmailDoc[Update User Doc];
        UpdateEmailDoc --> AuthState;
        EmailUser[Email/Pass User] -- Actions --> OtherActions[Other Account Actions];
        EmailUser -- Unverified --> StartChecker2[Start Email Verification Checker];
    end

    subgraph Email Verification Check Flow
        StartChecker --> LoopCheck{Checker: Periodically Reload User};
        StartChecker2 --> LoopCheck;
        LoopCheck -- Verified? --> IsVerified{emailVerified == true?};
        IsVerified -- No --> LoopCheck;
        IsVerified -- Yes --> CancelTimer[Checker: Cancel Timer];
        CancelTimer --> CallHandler[Checker: Call AuthService.handleEmailVerificationComplete(verifiedUser)];
        CallHandler --> UpdateFirestore[AuthService: Update Firestore 'isVerified'];
        UpdateFirestore --> InvalidateProviders[Checker: Invalidate Auth Providers];
        InvalidateProviders --> RefreshRouter[Checker: Refresh Router];
        RefreshRouter --> AuthState;
    end

    subgraph Google Flow
        D -- Google --> LoginGoogle[Login/Register with Google];
        LoginGoogle --> ExtractGoogleName[Extract Google Name];
        ExtractGoogleName --> CreateOrUpdateGoogleDoc[Create/Update User Doc];
        CreateOrUpdateGoogleDoc --> NavigateToAccount4[Navigate to /profile/account];
        NavigateToAccount4 --> AuthState;
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
        AttemptDelete --> DeleteAuth{AuthService: Delete Auth User};
        DeleteAuth -- Success --> DeleteFirestore[AuthService: Delete Firestore Doc];
        DeleteAuth -- Failure (e.g. Re-auth Needed) --> HandleReauth[UI Handles Re-auth Prompt];
        HandleReauth -- User Re-authenticates --> AttemptDelete;
        HandleReauth -- User Cancels --> SignedInUser;
        DeleteFirestore --> FinalSignOut[UI Signs Out User];
        FinalSignOut --> AuthState;
    end

    subgraph State & UI
        AuthState[Update Auth State] --> UpdateUI[Update UI];
    end

    style NavigateToAccount1 fill:#c9ffc9,stroke:#333,stroke-width:1px
    style NavigateToAccount2 fill:#c9ffc9,stroke:#333,stroke-width:1px
    style NavigateToAccount3 fill:#c9ffc9,stroke:#333,stroke-width:1px
    style NavigateToAccount4 fill:#c9ffc9,stroke:#333,stroke-width:1px
    style ShowVerifyDialog fill:#ffffcc,stroke:#333,stroke-width:1px
    style DeleteAuth fill:#ffcccc,stroke:#333,stroke-width:2px
    style DeleteFirestore fill:#ffe6cc,stroke:#333,stroke-width:1px
    style HandleReauth fill:#fdc,stroke:#333,stroke-width:2px
    style LoopCheck fill:#e0f7fa,stroke:#00796b,stroke-width:1px
    style IsVerified fill:#fff9c4,stroke:#fbc02d,stroke-width:2px
    style CancelTimer fill:#ffecb3,stroke:#ffa000,stroke-width:1px
    style CallHandler fill:#ffecb3,stroke:#ffa000,stroke-width:1px
    style UpdateFirestore fill:#ffecb3,stroke:#ffa000,stroke-width:1px
    style InvalidateProviders fill:#ffecb3,stroke:#ffa000,stroke-width:1px
    style RefreshRouter fill:#ffecb3,stroke:#ffa000,stroke-width:1px
    style SignOutWithFlag fill:#cce5ff,stroke:#005cb2,stroke-width:1px
    style SkipTimestampReset fill:#cce5ff,stroke:#005cb2,stroke-width:1px
    style SignOutFirebase fill:#cce5ff,stroke:#005cb2,stroke-width:1px
    style SignOutNormal fill:#e1f5fe,stroke:#0277bd,stroke-width:1px
    style ResetTimestamp fill:#e1f5fe,stroke:#0277bd,stroke-width:1px
    style SignOutFirebase2 fill:#e1f5fe,stroke:#0277bd,stroke-width:1px
