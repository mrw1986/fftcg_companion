# Codebase Summary

## Recent Changes

### UI Improvements for Authentication

- Updated logo display in authentication screens:
  - Added a primary color container with rounded corners for the logo
  - Improved visibility in both light and dark modes
  - Removed the need for color inversion filters in light mode
  - Enhanced visual consistency across the app
  - Files updated:
    - lib/features/profile/presentation/pages/login_page.dart
    - lib/features/profile/presentation/pages/register_page.dart
    - lib/features/profile/presentation/pages/auth_page.dart

### Authentication Methods UI Improvements

- Updated Google authentication icon in profile page:
  - Improved compliance with Google's branding guidelines
  - Used official SVG assets for the Google icon
  - Increased icon size for better visibility (36x36)
  - Removed unnecessary container and shadow effects
  - Simplified the UI while maintaining brand compliance
  - Files updated:
    - lib/features/profile/presentation/widgets/profile_auth_methods.dart

### Email Display Simplification

- Removed redundant email display under "Account Information":
  - Simplified UI by removing duplicate email information
  - Kept email display only under "Authentication Methods"
  - Improved visual hierarchy and reduced clutter
  - Files updated:
    - lib/features/profile/presentation/widgets/account_info_card.dart
    - lib/features/profile/presentation/widgets/profile_auth_methods.dart

### Color Handling Improvements

- Updated all instances of `withAlpha()` to use the modern `withValues(alpha: value)` approach:
  - Replaced `withAlpha(179)` (70% opacity) with `withValues(alpha: 0.7)`
  - Replaced `withAlpha(51)` (20% opacity) with `withValues(alpha: 0.2)`
  - Created comprehensive color handling guidelines in `cline_docs/colorHandlingGuidelines.md`
  - Improved color handling in wide gamut environments
  - Enhanced visual consistency across different devices and screens
  - Files updated:
    - lib/core/routing/app_router.dart
    - lib/features/cards/presentation/pages/cards_page.dart
    - Various UI component files throughout the application

### Security Enhancements

- Implemented comprehensive security improvements:
  - Replaced hard-coded admin emails with a role-based access control system
  - Enhanced data validation in Firestore security rules
  - Added protection against data manipulation in deck and collection rules
  - Implemented limits for anonymous users
  - Added email verification enforcement for sensitive operations
  - Enhanced error handling with categorized errors and improved logging
  - Implemented environment-aware error messages for better security in production
  - Added account age-based security controls
  - Created migration script for setting up the admin collection
  - Updated user model to include collection count tracking
  - Files updated:
    - firestore.rules
    - lib/features/profile/domain/models/user_model.dart
    - lib/features/profile/data/repositories/user_repository.dart
    - lib/features/collection/data/repositories/collection_repository.dart
    - lib/core/services/auth_service.dart
    - lib/core/providers/security_migration_provider.dart
    - lib/core/migrations/security_migration.dart
    - lib/core/migrations/run_security_migration.dart

### Google Authentication Flow Improvements

- Fixed issues with Google authentication flow:
  - Updated register_page.dart to properly navigate to the profile page after successful Google sign-in
  - Modified auth_service.dart to sign out and sign in with Google when encountering the 'provider-already-linked' error
  - Updated login_page.dart to handle the 'provider-already-linked' error case
  - This ensures users are properly logged in after creating an account with Google and can sign in with Google after creating an account
  - Files updated:
    - register_page.dart
    - auth_service.dart
    - login_page.dart

### Account Deletion Flow Improvements

- Fixed issue where users still saw their display name and sign out option after account deletion:
  - Modified the _deleteAccount method in account_settings_page.dart to sign out the user after successful account deletion
  - Added navigation back to the profile page after account deletion
  - Updated the _reauthenticateAndDeleteAccount method to do the same for cases where re-authentication is required
  - This ensures that after account deletion, the user's state is reset to a blank slate and they are redirected to the default Profile screen
  - Files updated:
    - account_settings_page.dart

### Anonymous User Authentication Flow Improvements

- Fixed Forgot Password flow for anonymous users:
  - Modified reset_password_page.dart to only sign out authenticated users who are not anonymous
  - Changed the condition from `isUserAuthenticated = authState.isAuthenticated || authState.isAnonymous` to `isUserAuthenticated = authState.isAuthenticated && !authState.isAnonymous`
  - This ensures anonymous users don't see the "you will be logged out" message

- Implemented proper account linking for anonymous users:
  - Updated login_page.dart to use Firebase's linkWithCredential method for anonymous users
  - Updated register_page.dart to use linkWithEmailAndPassword and linkWithGoogle methods
  - Added proper error handling for cases where the account already exists
  - This preserves user data when an anonymous user converts to a permanent account
  - Files updated:
    - login_page.dart
    - register_page.dart
    - reset_password_page.dart

### Dialog Button Readability Improvements

- Updated all dialog buttons to use theme's primary color for better readability
- Ensured consistent styling across all dialog buttons in the app
- Replaced hardcoded colors with theme-based colors for better contrast
- Files updated:
  - account_settings_page.dart
  - collection_item_detail_page.dart
  - profile_account_actions.dart
  - auth_page.dart
  - profile_email_update.dart

### Email Update Authentication Fix

- Fixed issue where users would see their old email after changing email and restarting the app
- Modified `verifyBeforeUpdateEmail` method in `AuthService` to update both Firebase Auth and Firestore
- Ensured consistent state between authentication and database during email updates
- Files updated:
  - auth_service.dart

### Theme System Improvements

- Removed ContrastExtension dependency from all UI components
- Simplified theme handling by using standard Material ColorScheme
- Updated all affected files to use direct theme colors instead of extension
- Improved theme consistency across the application
- Files updated:
  - profile_page.dart
  - auth_page.dart
  - register_page.dart
  - account_settings_page.dart
  - login_page.dart
  - profile_auth_section.dart
  - google_sign_in_button.dart
  - styled_button.dart
  - theme_settings_page.dart

### SnackBar Theming Improvements

- Updated SnackBarHelper to use Material 3 container colors consistently
- Standardized snackbar appearance across the app:
  - Standard/Success snackbars use primaryContainer/onPrimaryContainer
  - Error snackbars use errorContainer/onErrorContainer
- Improved visual hierarchy and contrast with container colors
- Consolidated snackbar styling to match existing implementations
- Files updated:
  - snackbar_helper.dart
  - profile_display_name.dart
  - register_page.dart
  - login_page.dart
  - theme_settings_page.dart
  - account_settings_page.dart

### Authentication Improvements

- Enhanced email verification with proper UI updates
- Improved account deletion flow with confirmation dialogs
- Added better re-authentication handling
- Fixed token refresh issues in auth service
- Refactored profile page into smaller components for better maintainability
- Improved "Change Email" flow with proper logout and user messaging

### Key Components

#### Auth Service (lib/core/services/auth_service.dart)

- Handles Firebase Authentication operations
- Manages user state and verification
- Provides re-authentication for sensitive operations
- Handles token refresh and state updates
- Now ensures consistent state between Firebase Auth and Firestore during email updates
- Properly handles Google authentication and account linking
- Implements environment-aware error handling
- Categorizes authentication errors for better error management
- Provides secure error messages in production

#### Email Verification Checker (lib/core/providers/email_verification_checker.dart)

- Monitors email verification status
- Updates UI when verification completes
- Manages verification state with proper token refresh
- Provides user feedback during verification

#### Profile Page Components

- **ProfilePage** (lib/features/profile/presentation/pages/profile_page.dart)
  - Main container for profile functionality
  - Manages state for all profile components
  - Handles authentication state changes
  - Coordinates between different profile sections

- **ProfileAuthSection** (lib/features/profile/presentation/pages/profile_auth_section.dart)
  - Displays authentication-related UI
  - Shows email verification status
  - Provides sign-in/sign-up options for unauthenticated users
  - Displays user information for authenticated users

- **ProfileAccountInformation** (lib/features/profile/presentation/pages/profile_account_information.dart)
  - Shows account details like email and provider type
  - Displays user information in a card format

- **ProfileSettings** (lib/features/profile/presentation/pages/profile_settings.dart)
  - Manages app settings like theme
  - Provides navigation to other settings pages

- **ProfileReauthDialog** (lib/features/profile/presentation/pages/profile_reauth_dialog.dart)
  - Handles re-authentication for sensitive operations
  - Provides clear UI for entering credentials
  - Shows loading state during authentication

- **ProfileEmailUpdate** (lib/features/profile/presentation/pages/profile_email_update.dart)
  - Manages email update functionality
  - Provides clear messaging about logout requirement
  - Handles confirmation dialogs

- **ProfileAccountActions** (lib/features/profile/presentation/pages/profile_account_actions.dart)
  - Provides account actions like sign out and delete
  - Handles confirmation dialogs for sensitive operations
  - Manages re-authentication requirements

- **ProfileDisplayName** (lib/features/profile/presentation/pages/profile_display_name.dart)
  - Handles display name updates
  - Provides UI for entering new display name
  - Shows loading state during update

#### Authentication Pages

- **LoginPage** (lib/features/profile/presentation/pages/login_page.dart)
  - Handles user login with email/password and Google
  - Now properly links anonymous accounts using linkWithCredential
  - Provides error handling for existing accounts
  - Handles 'provider-already-linked' error case
  - Features improved logo display with primary color container

- **RegisterPage** (lib/features/profile/presentation/pages/register_page.dart)
  - Handles user registration with email/password and Google
  - Now properly links anonymous accounts using linkWithEmailAndPassword and linkWithGoogle
  - Provides consistent UI text for account linking
  - Properly navigates to profile page after successful Google sign-in
  - Features improved logo display with primary color container

- **ResetPasswordPage** (lib/features/profile/presentation/pages/reset_password_page.dart)
  - Handles password reset requests
  - Now properly handles anonymous users without showing logout message
  - Only signs out authenticated users who are not anonymous

- **AccountSettingsPage** (lib/features/profile/presentation/pages/account_settings_page.dart)
  - Manages user account settings
  - Handles account deletion with proper state reset
  - Now properly signs out and navigates back to profile page after account deletion
  - Features improved authentication methods display with proper Google branding

### Data Flow

1. Authentication Flow
   - User signs in/registers
   - Email verification is sent if needed
   - Verification checker monitors status
   - UI updates when verification completes

2. Account Deletion Flow
   - User initiates deletion
   - Confirmation dialog shown
   - Re-authentication handling if needed
   - Account and data deleted
   - User signed out to reset state
   - Redirected to profile page

3. Email Update Flow
   - User enters new email
   - Confirmation dialog informs about logout requirement
   - Re-authentication if needed
   - Email update initiated in both Firebase Auth and Firestore
   - User logged out
   - Redirected to Profile page with Sign In button
   - If app is restarted before verification, the new email is shown consistently

4. Anonymous Account Linking Flow
   - Anonymous user attempts to sign in or register
   - System attempts to link the anonymous account with the new credentials
   - If account already exists, user is signed out and signed in with existing account
   - If linking is successful, user data is preserved
   - UI provides clear guidance throughout the process

5. Google Authentication Flow
   - User clicks "Continue with Google" or "Sign in with Google"
   - If user is anonymous, system attempts to link the account
   - If provider is already linked, system signs out and signs in with Google
   - If credential is already in use by another account, system signs out and signs in with that account
   - User is navigated to profile page after successful authentication
   - UI provides clear feedback throughout the process

6. Security Enforcement Flow
   - System checks user's email verification status
   - System checks user's account age
   - System enforces appropriate security measures based on these factors
   - Anonymous users have limits on collection items
   - Email verification is required for sensitive operations after grace period

### External Dependencies

#### Firebase Authentication

- Used for user management
- Handles email verification
- Provides token management
- Supports multiple auth providers
- Supports anonymous authentication and account linking

#### Firestore

- Stores user data
- Tracks verification status
- Manages user preferences
- Handles data cleanup on deletion
- Enforces security rules for data access and validation
- Stores admin roles for role-based access control

### Recent Significant Changes

1. UI Improvements for Authentication
   - Added primary color container with rounded corners for the logo in authentication screens
   - Improved logo visibility in both light and dark modes
   - Removed color inversion filters in light mode
   - Enhanced visual consistency across the app
   - Updated Google authentication icon in profile page to comply with Google's branding guidelines
   - Simplified the authentication methods UI while maintaining brand compliance
   - Removed redundant email display under "Account Information"

2. Security Enhancements
   - Replaced hard-coded admin emails with a role-based access control system
   - Enhanced data validation in Firestore security rules
   - Added protection against data manipulation in deck and collection rules
   - Implemented limits for anonymous users
   - Added email verification enforcement for sensitive operations
   - Enhanced error handling with categorized errors and improved logging
   - Implemented environment-aware error messages for better security in production
   - Added account age-based security controls
   - Created migration script for setting up the admin collection
   - Updated user model to include collection count tracking

3. Google Authentication Flow Improvements
   - Fixed issues with Google authentication flow:
     - Updated register_page.dart to properly navigate to the profile page after successful Google sign-in
     - Modified auth_service.dart to sign out and sign in with Google when encountering the 'provider-already-linked' error
     - Updated login_page.dart to handle the 'provider-already-linked' error case
     - This ensures users are properly logged in after creating an account with Google and can sign in with Google after creating an account

4. Account Deletion Flow Improvements
   - Fixed issue where users still saw their display name and sign out option after account deletion:
     - Modified the _deleteAccount method in account_settings_page.dart to sign out the user after successful account deletion
     - Added navigation back to the profile page after account deletion
     - Updated the _reauthenticateAndDeleteAccount method to do the same for cases where re-authentication is required
     - This ensures that after account deletion, the user's state is reset to a blank slate and they are redirected to the default Profile screen

5. Anonymous User Authentication Flow Improvements
   - Fixed Forgot Password flow for anonymous users:
     - Modified reset_password_page.dart to only sign out authenticated users who are not anonymous
     - Changed the condition from `isUserAuthenticated = authState.isAuthenticated || authState.isAnonymous` to `isUserAuthenticated = authState.isAuthenticated && !authState.isAnonymous`
     - This ensures anonymous users don't see the "you will be logged out" message
   - Implemented proper account linking for anonymous users:
     - Updated login_page.dart to use Firebase's linkWithCredential method for anonymous users
     - Updated register_page.dart to use linkWithEmailAndPassword and linkWithGoogle methods
     - Added proper error handling for cases where the account already exists
     - This preserves user data when an anonymous user converts to a permanent account
     - Updated UI text to be consistent with the account linking approach

6. Dialog Button Readability Improvements
   - Updated all dialog buttons to use theme's primary color for better readability
   - Added `style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.primary)` to all dialog buttons
   - Replaced ElevatedButton instances with TextButton where appropriate for consistency
   - Ensured all dialog buttons use the theme's primary color for better readability
   - Fixed specific buttons:
     - "OK" buttons in confirmation dialogs
     - "Cancel" and "Continue" buttons in email update dialogs
     - "Cancel" and "Delete" buttons in collection item deletion dialogs
     - "Try Again", "Create Account", and "Reset Password" buttons in authentication dialogs
   - Replaced hardcoded red color for delete confirmation with theme-based primary color
   - Improved contrast and readability across different theme settings

7. Email Update Authentication Fix
   - Fixed issue where users would see their old email after changing email and restarting the app
   - Modified `verifyBeforeUpdateEmail` method in `AuthService` to:
     - Store the user ID before updating email
     - Update the email in Firebase Auth as before
     - Also update the email in Firestore using UserRepository.updateUserEmail
   - Ensured consistent state between authentication and database during email updates
   - Improved user experience by maintaining email consistency across app restarts

8. SnackBar Theming Consistency
   - Created centralized SnackBarHelper utility class
   - Implemented consistent Material 3 container colors:
     - primaryContainer/onPrimaryContainer for standard/success messages
     - errorContainer/onErrorContainer for error messages
   - Added support for centered text and custom widths
   - Enhanced visual feedback with proper contrast
   - Files updated:
     - snackbar_helper.dart (new utility)
     - All profile-related pages
     - Theme settings page

9. AppBar and Navigation Bar Theming Consistency
   - Created AppBarFactory utility class for consistent AppBar creation
   - Updated AppBar theme to use primary color consistently across the app
   - Enhanced NavigationBar theming with proper color scheme integration
   - Replaced hardcoded colors with theme-based alternatives
   - Maintained special case for Theme Settings page with dynamic AppBar color
   - Files updated:
     - app_theme.dart
     - app_router.dart (for NavigationBar)
     - All profile-related pages
     - Added new utility: app_bar_factory.dart

10. Theme System Simplification
    - Removed ContrastExtension dependency to simplify theme management
    - Updated all UI components to use standard Material ColorScheme
    - Improved theme consistency across the application
    - Enhanced theme settings page with interactive color selection
    - Fixed theme mode selection to properly use the selected theme color
    - Made theme changes apply immediately throughout the app

11. Profile and Account Settings Consolidation
    - Consolidated Profile and Account Settings pages into a single page
    - Removed redundant UI elements while maintaining all functionality
    - Updated navigation to remove the separate account page route
    - Improved user experience by having all settings in one place
    - Fixed related issues to ensure a seamless experience

12. Email Verification
    - Added proper token refresh
    - Improved UI updates
    - Enhanced error handling
    - Better user feedback

13. Account Management
    - Added confirmation dialogs
    - Improved re-authentication flow:
      - Added dedicated re-authentication dialog with clear explanations
      - Made re-auth dialog context-aware (deletion vs. email update)
      - Added automatic continuation of operation after successful re-auth
      - Fixed issue where `requires-recent-login` error was not correctly handled for email updates
    - Enhanced error handling:
      - User-friendly error messages
      - Improved detection of re-authentication requirements
      - Better state management during re-authentication
      - Proper error recovery with clear guidance
    - Fixed issue where updated email address was not reflected in Firestore:
      - Added `updateUserEmail` method to `UserRepository`.
      - Called `updateUserEmail` in `AuthService.verifyBeforeUpdateEmail` after successful verification.

14. UI Improvements
    - Consistent dialog styling
    - Better error presentation with specific messages
    - Improved loading states
    - Enhanced user feedback throughout sensitive operations

15. Fixed Multiple UI Refreshes
    - Removed redundant navigation calls in `email_verification_checker.dart` to prevent multiple UI refreshes after email verification.

16. Code Organization
    - Refactored profile page into smaller, more focused components
    - Improved separation of concerns
    - Enhanced maintainability with smaller files
    - Better state management between components

17. Profile UI Cleanup
    - Removed "Continue with Google" button from the Profile page for anonymous users
    - Simplified the UI for anonymous users
    - Reduced redundancy as users can still sign in with Google from the login page
    - Removed "Show Splash Screen" toggle from the Profile Settings
    - Simplified the settings UI
    - Removed a setting that was not essential for the user experience

### User Feedback Integration

1. Authentication Feedback
   - Error messages uses error container colors
   - Status updates uses primary container colors
   - Loading indicators
   - Success confirmations uses theme-consistent styling

2. Account Management Feedback
   - Confirmation dialogs
   - Progress indicators
   - Error explanations uses error container colors
   - Success notifications with primary container colors

3. Email Update Feedback
   - Clear messaging about logout requirement
   - Confirmation dialogs
   - Success notifications uses theme-consistent styling
   - Proper redirection after logout

4. Anonymous User Feedback
   - Clear messaging about account linking options
   - Proper error handling for existing accounts
   - Success notifications for account linking
   - Consistent UI text for account linking

5. Google Authentication Feedback
   - Clear messaging about account creation and sign-in
   - Proper error handling for provider-already-linked cases
   - Success notifications for account creation and sign-in
   - Proper navigation after successful authentication

## Core Features

[Previous core features remain unchanged...]

## Architecture

[Previous architecture details remain unchanged...]

## Future Development

1. ~~Perform comprehensive security assessment of authentication system~~ (Completed)
2. Deck Builder
3. Card Scanner
4. Price Tracking
5. Collection Import/Export
6. Collection Sharing
7. Favorites and Wishlist
8. Advanced Filtering
9. Batch Operations
