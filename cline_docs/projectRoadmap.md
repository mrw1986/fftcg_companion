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
   - [x] Fixed UI updates after linking Google authentication
   - [x] Improved email update messaging based on auth methods
   - [x] Fixed Google authentication display name not storing in Firestore
   - [ ] **Critical:** Fix Firestore permission issues during data migration
   - [ ] **Ongoing:** Testing and troubleshooting edge cases (e.g., Google linking redirect)
   - [x] Implemented settings migration (theme, display preferences)
   - [ ] **Pending:** Expand data migration to include deck data

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
- [x] Fixed Google authentication display name not storing in Firestore
- [ ] **Fix Firestore permission issues during data migration (Critical)**
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

1. **Fixed Google Authentication Display Name Issue (Objective 30)**
    - Fixed issue where Google display name wasn't storing in Firestore:
        - Added code to extract display name directly from Google provider data
        - Updated logic to prioritize Google provider display name
        - Enhanced logging to track display name at various stages
    - Successfully tested the solution:
        - Display name now correctly extracted from Google provider data
        - Display name properly stored in Firestore user document
        - UI correctly displays the name from Google
    - **Remaining Issue:**
        - Account Limits dialog appears after Google sign-in (separate concern)

2. **Data Migration and Firestore Rules Updates (Objective 27)**
    - Updated Firestore rules to handle migrations:
        - Added special case for collection updates during migration
        - Added permission for initial user document creation
        - Relaxed validation during migration to allow transferring data
    - Improved data migration process:
        - Create user document before attempting data migration
        - Handle all merge cases (discard, merge, overwrite)
        - Add better error handling and logging
        - Continue with sign-in even if migration fails
    - **Critical Issues Remaining:**
        - Permission denied errors during data migration
        - Need to verify and fix Firestore rules for all migration scenarios
        - Ensure proper user document creation timing

3. **Fixed Email Update Flow and UI Updates (Objective 26)**
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

### Previous Achievements

1. **Authentication System Rebuild**
   - Completed full rebuild of authentication system
   - Implemented all core authentication flows
   - Added data migration support
   - Fixed state management issues
   - Improved error handling

2. **UI/UX Improvements**
   - Enhanced dialog styling
   - Improved error messages
   - Added loading states
   - Fixed navigation issues

3. **Security Enhancements**
   - Implemented proper Firestore rules
   - Added re-authentication flows
   - Enhanced data protection

### Next Steps

1. **Address Account Limits Dialog Issue:**
   - [ ] Investigate why the Account Limits dialog appears after Google sign-in
   - [ ] Fix auth state transitions during the sign-out/sign-in process

2. **Fix Firestore permission issues during data migration (Critical)**
   - [ ] Review and update Firestore rules for all migration scenarios
   - [ ] Fix user document creation timing
   - [ ] Add proper error handling for permission denied cases
   - [ ] Test all data migration paths

3. **Continue testing and troubleshooting Authentication edge cases and flows (especially Google linking)**

4. **Expand data migration to handle all user data:**
   - [ ] Deck data migration
   - [ ] User settings migration
   - [ ] User preferences migration
   - [ ] Ensure data integrity during migration

5. Implement deck builder feature
6. Add card scanner functionality
7. Develop price tracking system
8. Add collection import/export
9. Implement collection sharing
10. Add favorites and wishlist
11. Enhance filtering options
12. Add batch operations

### Future Considerations

1. Performance Optimization
   - Implement caching for frequently accessed data
   - Optimize image loading and caching
   - Reduce unnecessary rebuilds

2. Offline Support
   - Implement offline-first architecture
   - Add sync queue for offline changes
   - Handle conflict resolution

3. Analytics and Monitoring
   - Add crash reporting
   - Implement usage analytics
   - Add performance monitoring

4. Testing
   - Add unit tests for core functionality
   - Implement integration tests
   - Add UI tests for critical flows
