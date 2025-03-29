# Project Roadmap

## High-Level Goals

1. Create a comprehensive card collection management system
2. Provide robust user authentication and account management
3. Implement deck building and analysis tools
4. Add card scanning capabilities
5. Implement price tracking and market analysis
6. Enable collection sharing and social features

## Key Features

### Completed Features ✓

1. Theme Customization
   - [x] Light/dark mode support
   - [x] Custom color selection
   - [x] Theme persistence
   - [x] Contrast guarantees
   - [x] Consistent dialog button styling

2. Collection Management
   - [x] Card tracking (regular/foil)
   - [x] Condition tracking
   - [x] Purchase information
   - [x] Professional grading
   - [x] Collection statistics
   - [x] Grid/list views
   - [x] Filtering and sorting
   - [x] Search functionality

### In Progress Features

1. Authentication (Rebuilt - Testing & Troubleshooting)
   - [x] Email/password authentication
   - [x] Google Sign-In
   - [x] Email verification
   - [x] Account deletion
   - [x] Re-authentication flow
   - [x] Provider management (linking/unlinking)
   - [x] Anonymous accounts
   - [x] Email update with proper logout flow
   - [x] Fixed Forgot Password flow for anonymous users
   - [x] Proper account linking for anonymous users
   - [x] Fixed account deletion flow with proper state reset
   - [x] Fixed Google authentication flow
   - [x] Simplified and robust AuthService implementation
   - [x] Fixed provider unlinking logic and UI refresh
   - [x] Fixed email pre-population in link dialog
   - [x] Fixed state handling after sign-out/deletion
   - [x] Implemented data migration for anonymous users linking with Google accounts
   - [x] Added merge confirmation dialog for data preservation
   - [x] Fixed BuildContext handling in async operations
   - [x] Improved Google linking state management (skipAutoAuth flag, sign-out/sign-in process)
   - [ ] **Ongoing:** Testing and troubleshooting edge cases (e.g., Google linking redirect)

2. Card Database
   - [x] Card browsing
   - [x] Search functionality
   - [x] Filtering options
   - [ ] Advanced search features
   - [ ] Card relationships

### Planned Features

1. Deck Builder
   - [ ] Deck creation and editing
   - [ ] Deck analysis
   - [ ] Deck sharing
   - [ ] Deck statistics

2. Card Scanner
   - [ ] Image recognition
   - [ ] Bulk scanning
   - [ ] Collection import

3. Price Tracking
   - [ ] Market price tracking
   - [ ] Price history
   - [ ] Price alerts
   - [ ] Collection value analysis

4. Social Features
   - [ ] Collection sharing
   - [ ] Deck sharing
   - [ ] User profiles
   - [ ] Community features

## Completion Criteria

### Authentication System (In Progress - Rebuilt & Testing)

- [x] Implement secure user authentication (Rebuilt)
- [x] Support multiple auth providers (Rebuilt)
- [x] Handle email verification (Rebuilt)
- [x] Manage user accounts (Rebuilt)
- [x] Provide secure account deletion (Rebuilt)
- [x] Implement re-authentication (Rebuilt)
- [x] Support anonymous accounts (Rebuilt)
- [x] Implement proper email update flow with logout (Rebuilt)
- [x] Fix Forgot Password flow for anonymous users (Rebuilt)
- [x] Implement proper account linking for anonymous users (Rebuilt)
- [x] Fix account deletion flow with proper state reset (Rebuilt)
- [x] Fix Google authentication flow (Rebuilt)
- [x] Implement data migration for anonymous users (Rebuilt)
- [x] Improved Google linking state management (Rebuilt)
- [ ] **Ensure all edge cases and state transitions are handled correctly (Ongoing Testing)**

### Collection Management ✓

- [x] Track card quantities
- [x] Track card conditions
- [x] Support professional grading
- [x] Provide collection statistics
- [x] Enable filtering and sorting
- [x] Implement search functionality
- [x] Support offline access

### Theme System ✓

- [x] Support light/dark modes
- [x] Allow custom colors
- [x] Ensure text contrast
- [x] Persist settings
- [x] Support system theme
- [x] Consistent dialog button styling

## Progress Tracking

### Recently Completed

1. **Fixed Authentication State & UI Issues (Objective 26 - Ongoing Testing)**
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
    - **Refined Google linking state management:**
        - Updated `auth_page.dart` to set `skipAutoAuthProvider` flag during Google linking.
        - Modified `auto_auth_provider.dart` to reset the flag only for fully authenticated users.
        - Updated `auth_service.dart` to explicitly sign out from Google and Firebase with delays, and added more logging during the sign-out/sign-in process for linking.
    - **Note:** Authentication system is still undergoing testing and troubleshooting, particularly for edge cases like the Google linking redirect issue.

2. **Rebuilt Authentication System (Objective 26)**
    - Refactored `AuthService` for simplicity and robustness.
    - Implemented clear methods for all core flows (Anonymous, Email/Pass, Google, Linking, Updates, Deletion, Re-auth).
    - Simplified error handling with `AuthException`.
    - Updated Riverpod providers (`auth_provider`, `security_migration_provider`, `email_verification_checker`) to use the new service correctly.
    - Updated UI pages (`auth_page`, `register_page`, `login_page`, `account_settings_page`, `reset_password_page`, `link_accounts_dialog`, `link_email_password_dialog`) to integrate with the refactored service and fix method calls.
    - Ensured Firestore data consistency via `UserRepository`.
    - Added detailed logging.
    - Implemented data migration system for anonymous users:
        - Store anonymous user ID before sign-in
        - Prompt for data migration after successful sign-in
        - Use `CollectionRepository` for data transfer
        - Ensure BuildContext safety with mounted checks

3. Fixed Firebase Authentication issues (Superseded by Rebuild):
    - Fixed Google authentication in register flow to properly detect existing accounts
    - Improved re-authentication handling with better token refreshing
    - Enhanced error handling for specific Firebase Authentication errors
    - Fixed code structure for consistent error handling
    - Eliminated misleading success messages when signing in with existing credentials

4. Fixed Google authentication flow (Superseded by Rebuild):
    - Updated register_page.dart to properly navigate to the profile page after successful Google sign-in
    - Modified auth_service.dart to sign out and sign in with Google when encountering the 'provider-already-linked' error
    - Updated login_page.dart to handle the 'provider-already-linked' error case
    - Ensured users are properly logged in after creating an account with Google

5. Fixed account deletion flow (Superseded by Rebuild):
    - Updated account deletion to properly sign out the user after deletion
    - Added navigation back to the profile page after account deletion
    - Ensured the user's state is reset to a blank slate after deletion
    - Fixed the same issues in the re-authentication flow for account deletion

6. Fixed Forgot Password flow for anonymous users (Superseded by Rebuild):
    - Modified reset_password_page.dart to only sign out authenticated users who are not anonymous
    - Updated login_page.dart to use Firebase's linkWithCredential method for anonymous users
    - Updated register_page.dart to use linkWithEmailAndPassword and linkWithGoogle methods
    - Ensured anonymous user data is preserved when converting to a permanent account

7. Improved dialog button readability across the app:
    - Updated all dialog buttons to use theme's primary color
    - Ensured consistent styling across all dialog buttons
    - Replaced hardcoded colors with theme-based colors
    - Fixed specific buttons in authentication, account settings, and collection dialogs

8. Fixed Email Update Authentication Issue (Superseded by Rebuild):
    - Modified verifyBeforeUpdateEmail method to update both Firebase Auth and Firestore
    - Ensured consistent state between authentication and database
    - Fixed issue where users would see their old email after restarting the app

9. Improved Authentication Security and Code Quality (Superseded by Rebuild):
    - Removed deprecated fetchSignInMethodsForEmail method
    - Updated error handling to prevent email enumeration
    - Improved account linking security
    - Enhanced error messages and user feedback

10. Simplified theme system by removing ContrastExtension dependency
11. Fixed Profile screen redundancies and improved UI layout
12. Enhanced theme settings page with interactive color selection
13. Improved theme consistency across the application
14. Updated all UI components to use standard Material ColorScheme

15. Enhanced email verification with proper UI updates
16. Improved account deletion flow with confirmation dialogs
17. Added better re-authentication handling
18. Fixed token refresh issues in auth service
19. Improved error messages and user feedback
20. Refactored profile page into smaller components for better maintainability

### Next Steps

1. **Continue testing and troubleshooting Authentication edge cases and flows (especially Google linking)**
2. Implement deck builder feature
3. Add card scanner functionality
4. Develop price tracking system
5. Add collection import/export
6. Implement collection sharing
7. Add favorites and wishlist
8. Enhance filtering options
9. Add batch operations

## Future Considerations

1. Performance Optimization
   - [ ] Implement lazy loading
   - [ ] Add caching mechanisms
   - [ ] Optimize image loading
   - [ ] Reduce network requests

2. Offline Support
   - [ ] Enhance offline capabilities
   - [ ] Implement sync queue
   - [ ] Add conflict resolution
   - [ ] Support offline edits

3. Analytics and Monitoring
   - [ ] Add usage analytics
   - [ ] Implement error tracking
   - [ ] Monitor performance
   - [ ] Track user engagement

4. Security Enhancements
   - [ ] Implement advanced security measures
   - [ ] Add multi-factor authentication
   - [ ] Enhance data encryption
   - [ ] Implement secure data backup
