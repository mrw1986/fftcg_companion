# Codebase Summary

## Recent Changes

### Authentication State & UI Fixes (Objective 26 - Ongoing Testing)

- Corrected provider unlinking logic in `AuthService` to prevent removing the last provider incorrectly.
- Improved state invalidation in `auth_provider` for `unlinkProviderProvider` to ensure UI updates after unlinking.
- Fixed state handling after account deletion in `account_settings_page` by removing the suppression of automatic anonymous sign-in, ensuring a consistent state for subsequent actions.
- Corrected Google sign-in logic in `auth_page.dart` to handle state transitions after sign-out more robustly by adding a fallback from linking to standard sign-in if the user is not anonymous.
- Fixed email display for the password provider in `ProfileAuthMethods`.
- Ensured `AccountSettingsPage` watches `currentUserProvider` and passes the updated user object down to children (`AccountInfoCard`, `AccountActionsCard`) for reliable UI updates and data propagation.
- Corrected email pre-population logic in `LinkEmailPasswordDialog` by having it receive the initial email via constructor parameter from `AccountInfoCard`, which now gets the latest user data from `AccountSettingsPage`.
- Fixed profile page banner logic (`profile_page.dart`) to only show the email verification warning when the `authState.status` is specifically `AuthStatus.emailNotVerified`.
- Implemented data migration for anonymous users linking with Google accounts:
  - Added `merge_data_decision_dialog.dart` for user confirmation
  - Created `collection_merge_helper.dart` for data migration logic
  - Fixed timing of data migration to occur after successful sign-in
  - Added proper BuildContext handling for async operations
  - Ensured anonymous user data is preserved until migration decision
- **Refined Google linking state management:**
  - Updated `auth_page.dart` to set `skipAutoAuthProvider` flag during Google linking.
  - Modified `auto_auth_provider.dart` to reset the flag only for fully authenticated users.
  - Updated `auth_service.dart` to explicitly sign out from Google and Firebase with delays, and added more logging during the sign-out/sign-in process for linking.
- **Note:** Authentication system is still undergoing testing and troubleshooting, particularly for edge cases like the Google linking redirect issue.

### Authentication System Rebuild (Completed - Objective 26)

- **Completed a full rebuild of the authentication system** (`AuthService` and related UI/provider integrations) for simplicity, robustness, and adherence to best practices.
- Implemented a clean foundation covering Anonymous, Email/Password, and Google providers, including all linking, update, re-authentication, and deletion flows as per the defined plan.
- Preserved the existing UI/UX while refactoring the backend logic.
- Corrected numerous method calls and provider interactions across the affected files (`auth_page.dart`, `register_page.dart`, `login_page.dart`, `account_settings_page.dart`, `reset_password_page.dart`, `link_accounts_dialog.dart`, `link_email_password_dialog.dart`, `auth_provider.dart`, `security_migration_provider.dart`, `email_verification_checker.dart`).
- **This rebuild supersedes many previous incremental fixes** (Objectives 17, 18, 20, 21, 22, 23, 25). Details of those fixes are retained below for historical context but the core logic is now part of the unified rebuild.

### Firebase Authentication Fixes (Superseded by Rebuild)

- (Historical context retained) Fixed several issues with Firebase Authentication flows.

### UI Improvements for Authentication

- Updated logo display in authentication screens.
- Updated Google authentication icon in profile page.

### Email Display Simplification

- Removed redundant email display under "Account Information".

### Color Handling Improvements

- Updated all instances of `withAlpha()` to use the modern `withValues(alpha: value)` approach.

### Security Enhancements (Partially Superseded by Rebuild)

- Implemented security improvements in Firestore rules (role-based access, validation, limits).
- (AuthService logic related to security was handled within the rebuild).

### Google Authentication Flow Improvements (Superseded by Rebuild)

- (Historical context retained) Fixed issues with Google authentication flow.

### Account Deletion Flow Improvements (Superseded by Rebuild)

- (Historical context retained) Fixed issue where users still saw their display name after deletion.

### Anonymous User Authentication Flow Improvements (Superseded by Rebuild)

- (Historical context retained) Fixed Forgot Password flow and account linking for anonymous users.

### Dialog Button Readability Improvements

- Updated all dialog buttons to use theme's primary color.

### Email Update Authentication Fix (Superseded by Rebuild)

- (Historical context retained) Fixed issue with inconsistent email state.

### Theme System Improvements

- Removed ContrastExtension dependency.
- Simplified theme handling using standard Material ColorScheme.

### SnackBar Theming Improvements

- Created centralized SnackBarHelper utility class.
- Implemented consistent Material 3 container colors.

### AppBar and Navigation Bar Theming Consistency

- Created AppBarFactory utility class.
- Updated AppBar and NavigationBar theming.

### Profile and Account Settings Consolidation

- Consolidated Profile and Account Settings pages.

### Other Authentication Improvements (Superseded by Rebuild)

- (Historical context retained) Enhanced email verification, account deletion, re-authentication, token refresh, error messages, and profile page structure.

### Key Components

#### Auth Service (lib/core/services/auth_service.dart) - **(Rebuilt & Refined - Testing)**

- **Status:** Rebuilt for simplicity and robustness, with recent refinements to Google linking state management. **Currently undergoing testing and troubleshooting.**
- **Functionality:** Provides clear, direct methods for all core authentication flows using the `FirebaseAuth.instance` SDK.
- **Error Handling:** Uses custom `AuthException` with `AuthErrorCategory`. Includes specific handling for `not-anonymous` errors during linking attempts.
- **Dependencies:** Interacts with `UserRepository`, uses `Talker`.
- **Data Migration:** Handles anonymous user data migration when linking with existing Google accounts:
  - Stores anonymous user ID before sign-in
  - Prompts for data migration after successful sign-in
  - Uses `CollectionRepository` and `collection_merge_helper.dart` for data transfer
  - Ensures BuildContext safety with mounted checks
- **State Management:** Includes explicit sign-out from Google/Firebase with delays and detailed logging to manage state transitions during linking.

#### Riverpod Providers (lib/core/providers/)

- **`auth_provider.dart`:** Defines `authServiceProvider`, `currentUserProvider`, `authStateProvider`, and action providers (`unlinkProviderProvider`, etc.). `unlinkProviderProvider` now awaits the reloaded user before invalidating state. `authStateProvider` logic updated to prioritize `isAnonymous` check.
- **`email_verification_checker.dart`:** Monitors verification status.
- **`auto_auth_provider.dart`:** Handles automatic anonymous sign-in (no longer skipped during deletion). Logic updated to reset `skipAutoAuthProvider` flag only for fully authenticated users.

#### Profile Page Components

- **`profile_page.dart`:** Main profile view. Logic corrected to only show email verification banner when `authState.status == AuthStatus.emailNotVerified`.
- **`account_settings_page.dart`:** Manages account details. Now watches `currentUserProvider` to ensure child widgets receive updated user data. Correctly handles state after account deletion (allows auto-anonymous sign-in).
- **`AccountInfoCard.dart`:** Displays auth methods via `ProfileAuthMethods`. Now receives user object reliably from `AccountSettingsPage`. Passes correct email to `LinkEmailPasswordDialog`.
- **`ProfileAuthMethods.dart`:** Displays individual auth methods. Fixed email display for password provider. Watches `currentUserProvider` for better reactivity after unlinks.
- **`LinkEmailPasswordDialog.dart`:** Fixed to receive `initialEmail` via constructor and keep the field editable.
- **Other Dialogs/Cards:** (`ProfileHeaderCard`, `AccountActionsCard`, `ProfileReauthDialog`, `UpdatePasswordDialog`, etc.)

#### Authentication Pages

- **`auth_page.dart`:** Handles sign-in. Google sign-in logic improved to handle `not-anonymous` errors by falling back to standard sign-in and sets `skipAutoAuthProvider` flag during linking.
- **`register_page.dart`:** Handles registration and linking anonymous users. Google linking logic improved to handle `not-anonymous` errors.
- **`login_page.dart`:** Handles login and linking anonymous users.
- **`reset_password_page.dart`:** Handles password reset.

### Data Flow

- **Authentication Flow (Rebuilt & Refined - Testing)**

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
        LinkGoogle -- Exists --> MergePrompt{Merge Data?};
        MergePrompt -- Yes --> MigrateData[Migrate Collection Data];
        MergePrompt -- No --> DiscardData[Keep Google Account Data];
        MigrateData --> SignOutSignIn[Sign Out & Sign In w/ Google];
        DiscardData --> SignOutSignIn;
        LinkEmailPass --> AuthState;
        LinkGoogle -- Success --> SignOutSignIn;
        SignOutSignIn --> AuthState;
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
    style MergePrompt fill:#9f9,stroke:#333,stroke-width:2px
    style MigrateData fill:#9f9,stroke:#333,stroke-width:2px
    style SignOutSignIn fill:#ffcc99,stroke:#333,stroke-width:2px
```

- State management relies on Riverpod providers (`authStateProvider`, `currentUserProvider`) watching changes from the rebuilt `AuthService`.
- UI components react to state changes provided by these providers. `AccountSettingsPage` now explicitly watches `currentUserProvider` to ensure timely updates are passed down.

### External Dependencies

#### Firebase Authentication

- Core service for user management, verification, token handling, multiple providers, anonymous auth, and linking. Leveraged directly by the rebuilt `AuthService`.

#### Firestore

- Stores user profile data (`users` collection), managed by `UserRepository`.
- `AuthService` interacts with `UserRepository` to ensure data consistency (e.g., creating user doc on sign-up/link, updating email, deleting user doc).
- Security rules enforce access control based on authentication status and user roles.

### Recent Significant Changes (Consolidated)

1. **Authentication System Rebuild & Refinements (Objective 26 - Ongoing Testing):** Completed a full rebuild and subsequent fixes addressing state management, UI refresh issues (especially after unlinking), error handling edge cases (sign-in after sign-out), dialog behavior (email pre-population), data migration for anonymous users, and Google linking state management. **Currently testing and troubleshooting.**
2. UI Improvements for Authentication (Logo, Google Icon).
3. Email Display Simplification in Profile.
4. Color Handling Improvements (`withValues`).
5. Security Enhancements (Firestore Rules).
6. Dialog Button Readability Improvements.
7. Theme System Simplification.
8. SnackBar Theming Consistency.
9. AppBar and Navigation Bar Theming Consistency.
10. Profile and Account Settings Consolidation.

- *(Previous auth-specific fixes are now considered part of the rebuild context)*

### User Feedback Integration

- (Remains largely unchanged, focusing on clear SnackBars, dialogs, and loading states, now driven by the rebuilt `AuthService`'s error handling and state updates).

## Core Features

[Previous core features remain unchanged...]

## Architecture

[Previous architecture details remain unchanged...]

## Future Development

1. Deck Builder
2. Card Scanner
3. Price Tracking
4. Collection Import/Export
5. Collection Sharing
6. Favorites and Wishlist
7. Advanced Filtering
8. Batch Operations
