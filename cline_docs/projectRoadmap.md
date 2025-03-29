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
   - [x] Fixed authentication method order consistency in UI
   - [ ] **Ongoing:** Testing and troubleshooting edge cases (e.g., Google linking redirect)
   - [ ] **Pending:** Expand data migration to include all user data (decks, settings, preferences)

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
- [x] Fixed authentication method order consistency in UI
- [ ] **Ensure all edge cases and state transitions are handled correctly (Ongoing Testing)**
- [ ] **Implement comprehensive data migration for all user data (Pending)**

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
    - **Note:** Authentication system is still undergoing testing and troubleshooting, particularly for edge cases like the Google linking redirect issue.

[Previous entries remain unchanged...]

### Next Steps

1. **Continue testing and troubleshooting Authentication edge cases and flows (especially Google linking)**
2. **Expand data migration to handle all user data:**
   - [ ] Deck data migration
   - [ ] User settings migration
   - [ ] User preferences migration
   - [ ] Ensure data integrity during migration
3. Implement deck builder feature
4. Add card scanner functionality
5. Develop price tracking system
6. Add collection import/export
7. Implement collection sharing
8. Add favorites and wishlist
9. Enhance filtering options
10. Add batch operations

[Future Considerations section remains unchanged...]
