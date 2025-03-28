# Current Task

## Previous Objectives (Completed)

[Previous objectives remain unchanged...]

## Current Objective 26 (Completed)

Rebuild Authentication System for Simplicity and Robustness

### Context

Despite previous attempts to fix and enhance the Firebase Authentication system, ongoing issues and perceived over-engineering necessitated a rebuild. The goal was to create a simpler, more robust system from scratch while preserving the existing UI/UX.

### Goal

Implement a robust and simplified authentication system using Firebase Authentication (Email/Password, Anonymous, Google) covering all essential user flows.

### Implementation Outcome

1. **Refactored `AuthService` (`lib/core/services/auth_service.dart`):**
    * Rewrote the service focusing on direct, clear calls to the `FirebaseAuth.instance` SDK.
    * Implemented straightforward methods for each core flow:
        * Anonymous sign-in (`signInAnonymously`)
        * Email/Password sign-in (`signInWithEmailAndPassword`)
        * Email/Password registration (`createUserWithEmailAndPassword`)
        * Google sign-in/registration (`signInWithGoogle`)
        * Linking Email/Password to Anonymous (`linkEmailAndPasswordToAnonymous`)
        * Linking Google to Anonymous (`linkGoogleToAnonymous`)
        * Linking Email/Password to Google (`linkEmailPasswordToGoogle`)
        * Linking Google to Email/Password (`linkGoogleToEmailPassword`)
        * Password Reset (`sendPasswordResetEmail`)
        * Email Update (`verifyBeforeUpdateEmail`)
        * Password Update (`updatePassword`)
        * Sign Out (`signOut`)
        * Account Deletion (`deleteUser`)
        * Re-authentication (Email/Password: `reauthenticateWithEmailAndPassword`, Google: `reauthenticateWithGoogle`)
        * Provider Unlinking (`unlinkProvider`)
        * Profile Update (`updateProfile`)
        * Email Verification Check (`isEmailVerified`, `sendEmailVerification`, `handleEmailVerificationComplete`)
        * Account Age Check (`isAccountOlderThan`)
    * Simplified error handling using `AuthException` and `AuthErrorCategory`.
    * Maintained necessary interactions with `UserRepository`.
    * Added detailed logging using `Talker`.

2. **Reviewed/Updated State Management (Riverpod Providers):**
    * Corrected provider instantiations in `security_migration_provider.dart` to use the shared `authServiceProvider`.
    * Updated `auth_provider.dart` to align with the new `AuthService` method signatures (e.g., `unlinkProvider` return type, `linkEmailPasswordToGoogle` name).
    * Ensured `email_verification_checker.dart` correctly calls `handleEmailVerificationComplete` using the shared provider.

3. **UI Integration (No Visual Changes):**
    * Updated UI pages/widgets to call the refactored `AuthService` methods correctly:
        * `auth_page.dart`: Fixed `getReadableAuthError` calls, updated `linkGoogleToAnonymous` call.
        * `register_page.dart`: Fixed `getReadableAuthError` calls, updated `linkEmailAndPasswordToAnonymous` and `linkGoogleToAnonymous` calls.
        * `link_accounts_dialog.dart`: Updated `linkGoogleToEmailPassword` call.
        * `account_settings_page.dart`: Fixed `getReadableAuthError` calls, updated `linkGoogleToEmailPassword` and `linkEmailPasswordToGoogle` calls.
        * `login_page.dart`: Fixed `getReadableAuthError` calls, updated `linkGoogleToAnonymous` call.
        * `reset_password_page.dart`: Fixed `getReadableAuthError` call.
        * `link_email_password_dialog.dart`: Updated `linkEmailAndPasswordToAnonymous` and `linkEmailPasswordToGoogle` calls (via provider).
    * Ensured UI handling of loading states and errors aligns with the new service.

4. **Testing:**
    * Manual testing confirmed core flows are functional. (Further rigorous testing recommended).

5. **Documentation Update:**
    * Updated `currentTask.md` (this file).
    * Updated `projectRoadmap.md`.
    * Updated `codebaseSummary.md`.

### Authentication Flow Diagram

```mermaid
graph TD
    subgraph Entry Points
        A[App Start] --> B{User Signed In?};
        C[Login/Register Page] --> D{Choose Method};
    end

    subgraph Anonymous Flow
        B -- No --> AnonSignIn[Sign In Anonymously];
        AnonSignIn --> AuthState;
        Anon[Anonymous User] -- Link --> LinkChoice{Link Email/Pass or Google?};
        LinkChoice -- Email/Pass --> LinkEmailPass[Link Email/Pass Credential];
        LinkChoice -- Google --> LinkGoogle[Link Google Credential];
        LinkEmailPass --> AuthState;
        LinkGoogle --> AuthState;
    end

    subgraph Email/Password Flow
        D -- Email/Pass --> EmailChoice{Register or Login?};
        EmailChoice -- Register --> RegisterEmail[Register + Send Verification];
        EmailChoice -- Login --> LoginEmail[Login Email/Pass];
        RegisterEmail --> AuthState;
        LoginEmail --> AuthState;
        EmailUser[Email/Pass User] -- Forgot Password --> ResetPass[Password Reset Flow];
        EmailUser -- Update Email --> ReAuth1[Re-auth Needed];
        ReAuth1 -- Success --> UpdateEmail[Update Email Flow];
        EmailUser -- Update Password --> ReAuth2[Re-auth Needed];
        ReAuth2 -- Success --> UpdatePass[Update Password Flow];
        EmailUser -- Link Google --> LinkGoogle2[Link Google Credential];
        LinkGoogle2 --> AuthState;
        ResetPass --> LoginEmail;
        UpdateEmail --> AuthState;
        UpdatePass --> AuthState;
    end

    subgraph Google Flow
        D -- Google --> LoginGoogle[Login/Register with Google];
        LoginGoogle --> AuthState;
        GoogleUser[Google User] -- Link Email/Pass --> LinkEmailPass2[Link Email/Pass Credential];
        LinkEmailPass2 --> AuthState;
    end

    subgraph Common Actions
        B -- Yes --> SignedInUser;
        SignedInUser --> ActionChoice{Choose Action};
        ActionChoice -- Sign Out --> SignOut[Sign Out Flow];
        ActionChoice -- Delete Account --> ReAuth3[Re-auth Needed];
        ReAuth3 -- Success --> DeleteAcct[Delete Account Flow];
        SignOut --> B;
        DeleteAcct --> B;
    end

    subgraph State & UI
        AuthState[Update Auth State] --> UpdateUI[Update UI];
    end

    style AnonSignIn fill:#f9f,stroke:#333,stroke-width:2px
    style AuthState fill:#ccf,stroke:#333,stroke-width:2px
    style ReAuth1 fill:#fdc,stroke:#333,stroke-width:1px
    style ReAuth2 fill:#fdc,stroke:#333,stroke-width:1px
    style ReAuth3 fill:#fdc,stroke:#333,stroke-width:1px
```

## Next Steps

1. Implement deck builder feature (Objective from Roadmap)
2. Add card scanner functionality
3. Develop price tracking system
4. Add collection import/export
5. Implement collection sharing
6. Add favorites and wishlist
7. Enhance filtering options
8. Add batch operations
