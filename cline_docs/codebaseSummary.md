# Codebase Summary

## Recent Changes

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

### Data Flow

1. Authentication Flow
   - User signs in/registers
   - Email verification is sent if needed
   - Verification checker monitors status
   - UI updates when verification completes

2. Account Deletion Flow
   - User initiates deletion
   - Confirmation dialog shown
   - Re-authentication handling:
     - Detects when re-auth is needed
     - Shows re-auth dialog with proper state management
   - Account and data deleted

3. Email Update Flow
   - User enters new email
   - Confirmation dialog informs about logout requirement
   - Re-authentication if needed
   - Email update initiated
   - User logged out
   - Redirected to Profile page with Sign In button

### External Dependencies

#### Firebase Authentication

- Used for user management
- Handles email verification
- Provides token management
- Supports multiple auth providers

#### Firestore

- Stores user data
- Tracks verification status
- Manages user preferences
- Handles data cleanup on deletion

### Recent Significant Changes

1. SnackBar Theming Consistency
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

2. AppBar and Navigation Bar Theming Consistency
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

3. Theme System Simplification
   - Removed ContrastExtension dependency to simplify theme management
   - Updated all UI components to use standard Material ColorScheme
   - Improved theme consistency across the application
   - Enhanced theme settings page with interactive color selection
   - Fixed theme mode selection to properly use the selected theme color
   - Made theme changes apply immediately throughout the app

4. Profile and Account Settings Consolidation
   - Consolidated Profile and Account Settings pages into a single page
   - Removed redundant UI elements while maintaining all functionality
   - Updated navigation to remove the separate account page route
   - Improved user experience by having all settings in one place
   - Fixed related issues to ensure a seamless experience

5. Email Verification
   - Added proper token refresh
   - Improved UI updates
   - Enhanced error handling
   - Better user feedback

6. Account Management
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

7. UI Improvements
   - Consistent dialog styling
   - Better error presentation with specific messages
   - Improved loading states
   - Enhanced user feedback throughout sensitive operations

8. Fixed Multiple UI Refreshes
   - Removed redundant navigation calls in `email_verification_checker.dart` to prevent multiple UI refreshes after email verification.

9. Code Organization
   - Refactored profile page into smaller, more focused components
   - Improved separation of concerns
   - Enhanced maintainability with smaller files
   - Better state management between components

10. Profile UI Cleanup

- Removed "Continue with Google" button from the Profile page for anonymous users
- Simplified the UI for anonymous users
- Reduced redundancy as users can still sign in with Google from the login page
- Removed "Show Splash Screen" toggle from the Profile Settings
- Simplified the settings UI
- Removed a setting that was not essential for the user experience

### User Feedback Integration

1. Authentication Feedback
   - Error messages

- uses error container colors
  - Status updates
- uses primary container colors
  - Loading indicators
  - Success confirmations
- uses theme-consistent styling

1. Account Management Feedback
   - Confirmation dialogs
   - Progress indicators
   - Error explanations

- uses error container colors
  - Success notifications with primary container colors

1. Email Update Feedback
   - Clear messaging about logout requirement
   - Confirmation dialogs
   - Success notifications

- uses theme-consistent styling
  - Proper redirection after logout

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
