# Current Task

## Previous Objective (Completed)

Implement Firebase Authentication in the FFTCG Companion app with automatic anonymous authentication

## Current Objective

Implement theme customization in the FFTCG Companion app with support for light/dark modes and custom theme colors

## Authentication Context (Completed)

The app needed user authentication to maintain user settings, collections, decks, and other user-specific data across devices. We implemented Firebase Authentication with three authentication methods:

1. Google Sign-In
2. Email/Password authentication
3. Anonymous authentication (automatic)

This implementation allows users to:

- Create accounts with email/password or Google Sign-In
- Use the app anonymously without explicitly choosing to do so (automatic)
- Upgrade from anonymous to permanent accounts without losing data
- Manage their account settings
- Sign in across multiple devices with the same account

## Theme Customization Context

The app needed a comprehensive theming system to provide a personalized user experience and ensure good readability in both light and dark modes. We implemented a theme customization system with the following features:

1. Theme mode selection (Light, Dark, System)
2. Custom theme color selection with color picker
3. Predefined color schemes from FlexColorScheme
4. Contrast guarantees for text readability
5. Persistent theme settings across app restarts

## Authentication Implementation Plan (Completed)

### 1. Create Authentication Service

Location: lib/core/services/auth_service.dart

- Created a service class to handle all Firebase Authentication operations
- Implemented methods for each authentication provider
- Added user state management and persistence
- Implemented error handling for authentication operations
- Added methods to link anonymous accounts to permanent accounts

### 2. Create Authentication Provider

Location: lib/core/providers/auth_provider.dart

- Created Riverpod providers for authentication state
- Implemented AuthState class to represent different authentication states
- Added methods to expose authentication functionality to the UI

### 3. Implement Automatic Anonymous Authentication

Location: lib/core/providers/auto_auth_provider.dart

- Created a provider that automatically signs in anonymously if the user is not already signed in
- Integrated the auto-auth provider with the app initialization
- Removed explicit "Continue without an account" buttons from the UI

### 4. Create Authentication UI

- Created login page: lib/features/profile/presentation/pages/login_page.dart
- Created registration page: lib/features/profile/presentation/pages/register_page.dart
- Created password reset page: lib/features/profile/presentation/pages/reset_password_page.dart
- Created account management page: lib/features/profile/presentation/pages/account_page.dart
- Updated profile page to show different options based on authentication state

### 5. Update Authentication Routes

Location: lib/core/routing/app_router.dart

- Added routes for new authentication pages
- Updated imports to include new pages

### 6. Update Main.dart

Location: lib/main.dart

- Added Firebase Authentication import
- Ensured Firebase is properly initialized

### 7. Fix Account Linking Issues

- Modified login flow to check if the user is anonymous before signing in
- If the user is anonymous, link the new credentials to the anonymous account instead of creating a new account
- This ensures that user data from anonymous sessions is preserved when upgrading to a permanent account

## Theme Customization Implementation Plan

### 1. Create Theme System

Location: lib/app/theme/app_theme.dart

- Created a theme class to provide theme data for the application
- Implemented light and dark themes using FlexColorScheme
- Added support for custom primary colors
- Ensured proper contrast for text readability

### 2. Create Theme Extensions

Location: lib/app/theme/contrast_extension.dart

- Created a ContrastExtension to ensure text has sufficient contrast against backgrounds
- Implemented methods to calculate contrast-guaranteed colors
- Added support for light and dark mode contrast adjustments

### 3. Create Theme Provider

Location: lib/app/theme/theme_provider.dart

- Created Riverpod providers for theme mode and theme color
- Implemented persistence using Hive storage
- Added methods to update theme settings

### 4. Create Theme Settings Page

Location: lib/features/profile/presentation/pages/theme_settings_page.dart

- Created a UI for selecting theme mode (Light, Dark, System)
- Implemented color picker for custom theme colors
- Added predefined color schemes from FlexColorScheme
- Ensured colors have appropriate contrast in both light and dark modes
- Fixed null check error when accessing FlexColor.schemes by adding null safety check and fallback

### 5. Update Theme Routes

Location: lib/core/routing/app_router.dart

- Added route for theme settings page

## Files Modified for Authentication

1. lib/core/services/auth_service.dart (new)
2. lib/core/providers/auth_provider.dart (new)
3. lib/core/providers/auto_auth_provider.dart (new)
4. lib/features/profile/presentation/pages/login_page.dart (new)
5. lib/features/profile/presentation/pages/register_page.dart (new)
6. lib/features/profile/presentation/pages/reset_password_page.dart (new)
7. lib/features/profile/presentation/pages/account_page.dart (new)
8. lib/features/profile/presentation/pages/profile_page.dart (updated)
9. lib/core/routing/app_router.dart (updated)
10. lib/main.dart (updated)
11. lib/app/app.dart (updated)

## Files Modified for Theme Customization

1. lib/app/theme/app_theme.dart (updated)
2. lib/app/theme/contrast_extension.dart (new)
3. lib/app/theme/theme_provider.dart (new)
4. lib/app/theme/theme_extensions.dart (updated)
5. lib/features/profile/presentation/pages/theme_settings_page.dart (new)
6. lib/core/routing/app_router.dart (updated)
7. lib/app/app.dart (updated)

## Authentication Impact (Completed)

- Users are automatically signed in anonymously when they first open the app
- Users can create accounts and sign in using multiple authentication methods
- Anonymous users can upgrade to permanent accounts without losing their data
- User data can be synchronized across devices
- The Profile page shows different options based on authentication state
- Account management features are now available

## Theme Customization Impact

- Users can select between light, dark, or system theme modes
- Users can customize the app's primary color using a color picker
- Users can select from predefined color schemes
- Theme settings are persisted across app restarts
- Text has guaranteed readability with sufficient contrast
- The app respects system theme changes
- The Profile page includes a link to theme settings

## Authentication Status (Completed)

- Firebase Authentication has been implemented with Google Sign-In, Email/Password, and Anonymous authentication
- Automatic anonymous authentication has been implemented
- UI for authentication has been created
- Router has been updated to include new authentication routes
- Main.dart and app.dart have been updated to initialize Firebase Authentication and auto-auth
- Account linking has been fixed to preserve user data when upgrading from anonymous to permanent accounts

## Theme Customization Status

- Theme customization has been implemented with light, dark, and system modes
- Fixed null check error in ThemeSettingsPage when accessing FlexColor.schemes
  - Added null safety check when accessing predefined color schemes
  - Provided fallback to Material scheme when a scheme is not available
- Custom color selection has been implemented with a color picker
- Predefined color schemes have been added
- Theme settings are persisted using Hive storage
- Text contrast has been ensured for readability
- The router has been updated to include the theme settings route
- The Profile page has been updated to include a link to theme settings

## Authentication Testing Strategy (Completed)

1. Authentication Flow Test
   - Test each authentication provider (Google, Email/Password)
   - Verify that automatic anonymous authentication works
   - Verify user state persistence
   - Test upgrading from anonymous to permanent accounts

2. UI Test
   - Verify that the Profile page shows different options based on authentication state
   - Test login, registration, and password reset forms
   - Verify form validation works correctly

3. Error Handling Test
   - Test error handling for invalid credentials
   - Test error handling for network issues
   - Verify user feedback for errors

## Theme Customization Testing Strategy

1. Theme Mode Test
   - Verify that light, dark, and system modes work correctly
   - Test that the app responds to system theme changes
   - Verify theme persistence across app restarts

2. Color Customization Test
   - Test custom color selection with the color picker
   - Verify that predefined color schemes work correctly
   - Test color contrast adjustments for readability
   - Verify color persistence across app restarts

3. UI Test
   - Verify that all UI elements respect the selected theme
   - Test theme changes in different parts of the app
   - Verify that text remains readable in all themes

## Next Steps

1. Implement Firestore security rules to protect user data
2. Update collection and deck features to associate data with user accounts
3. Implement data migration when converting from anonymous to permanent accounts
4. Implement email verification
5. Implement collection management feature
6. Implement deck builder feature
