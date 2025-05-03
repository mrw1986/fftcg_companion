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
    - [x] **Fixed Firestore permission errors during add/update** (Corrected `CollectionItem.toMap()` serialization)
    - [x] **Implemented card deletion when quantity reaches zero**
    - [x] **Implemented robust `collectionCount` tracking** (using transactions and verification)
    - [x] **UI: Added text input for quantity on edit page**
    - [x] **UI: Fixed grading label capitalization on detail page**

### In Progress Features

1. Authentication (Rebuilt - Testing & Troubleshooting)
    - [x] Email/password authentication
    - [x] Google Sign-In
    - [x] Email verification
    - [x] Account deletion
    - [x] Re-authentication flow (**Verified working**)
    - [x] Provider management (linking/unlinking)
    - [x] Anonymous accounts
    - [x] Email update with proper logout flow
    - [x] Fixed Forgot Password flow for anonymous users
    - [x] Proper account linking for anonymous users
    - [x] Fixed account deletion flow with proper state reset
    - [x] Google authentication flow functional (linking & sign-in)
    - [x] Simplified and robust AuthService implementation
    - [x] Fixed provider unlinking logic and UI refresh
    - [x] Fixed email pre-population in link dialog
    - [x] Fixed state handling after sign-out/deletion
    - [x] Implemented data migration for anonymous users linking with Google accounts (Collection only)
    - [x] Added merge confirmation dialog for data preservation
    - [x] Fixed BuildContext handling in async operations
    - [x] Improved Google linking state management (skipAutoAuth flag, sign-out/sign-in process)
    - [x] Fixed authentication method order consistency in UI
    - [x] Fixed UI updates after linking Google authentication
    - [x] Improved email update messaging based on auth methods
    - [x] Fixed Google authentication display name not storing in Firestore
    - [x] Fixed navigation after registration to show Account Settings page
    - [x] **Fixed Firestore permission issues during data migration** (Resolved as part of general collection permission fix)
    - [x] **Fixed post-sign-in redirect issue** (Verified working)
    - [ ] **Ongoing:** Resolve `GlobalKey` conflicts and `ref` disposal errors during auth flow. Address count verification edge cases.
    - [x] Implemented settings migration (theme, display preferences)
    - [ ] **Pending:** Expand data migration to include deck data (See Phase 3, Item 17)

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
    - [ ] Deck Export (CSV, XML, JSON)
    - [ ] Advanced Deck Export (HTML/PDF with analysis)

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
- [x] Implement re-authentication (Rebuilt & Verified)
- [x] Support anonymous accounts (Rebuilt)
- [x] Implement proper email update flow with logout (Rebuilt)
- [x] Fix Forgot Password flow for anonymous users (Rebuilt)
- [x] Implement proper account linking for anonymous users (Rebuilt)
- [x] Fix account deletion flow with proper state reset (Rebuilt)
- [x] Fix Google authentication flow (Functional, pending error resolution)
- [x] Implement data migration for anonymous users (Rebuilt - Collection only)
- [x] Improved Google linking state management (Rebuilt)
- [x] Fixed authentication method order consistency in UI
- [x] Fixed Google authentication display name not storing in Firestore
- [x] **Fixed Firestore permission issues during data migration (Resolved)**
- [x] **Fixed post-sign-in redirect issue (Verified)**
- [ ] **Resolve `GlobalKey` / `ref` disposal errors during auth flow (Ongoing)**
- [ ] **Implement comprehensive data migration for all user data (Pending - See Phase 3, Item 17)**

### Recently Completed Tasks

1. **Investigate Reauthentication & Sign-in Redirect Issues (Current Session)**
    - Investigated blank reauthentication screen (not reproduced) and post-sign-in redirect failure.
    - Added and removed diagnostic logging in `AuthNotifier` and `ProfileReauthDialog`.
    - Confirmed router listener notification and redirect logic are working correctly.
    - Issues appear resolved or intermittent.

2. **Auth Flow Stability & Linking Fixes (Previous Session)**
    - Resolved `GlobalKey` conflict and incorrect navigation after unlinking providers by introducing `authStatusProvider` and refining router logic.
    - Fixed email pre-population regression in the link dialog.
    - Ensured UI updates correctly after linking Email/Password to Google by adding provider invalidation.
    - Added delay to Google unlink process in `AuthService` to improve stability.
    - Resolved various analysis errors and `use_build_context_synchronously` warnings.
    - Refactored `linkGoogleToAnonymous` merge conflict logic.

3. **Analysis Errors & Provider Refactoring (Previous Session)**
    - Addressed multiple analysis errors (`unused_import`, `invalid_use_of_protected_member`, `deprecated_member_use`, `use_super_parameters`, `unused_local_variable`).
    - Refactored `cardSearchQueryProvider`, `collectionSpecificFilterProvider`, and `collectionSearchQueryProvider` from `StateProvider` to `NotifierProvider` to correctly handle state persistence and side effects (fixing `listenSelf` deprecation).
    - Updated UI components to interact correctly with the refactored `NotifierProvider`s using their methods.
4. **Collection Management Fixes & Enhancements (Objective 50)**
    - Fixed Firestore `PERMISSION_DENIED` errors when adding/updating collection items by correcting `CollectionItem.toMap()` serialization (`cardId` type, `null` map handling).
    - Implemented robust `collectionCount` tracking in `UserRepository` using Firestore transactions and added a verification/correction mechanism triggered on auth sync.
    - Implemented automatic deletion of collection items when both regular and foil quantities are updated to zero (`CollectionRepository`).
    - Added `TextField` for direct quantity input on the collection edit page.
    - Fixed capitalization of "Regular"/"Foil" labels in the grading section of the collection item detail page.

5. **Fixed Account Limits Dialog Issue After Google Sign-In (Objective 31)**
    - Prevented the Account Limits dialog from appearing after cancelling Google sign-in or linking:
        - Modified the auto-sign-in logic in `auto_auth_provider.dart` to pass `isInternalAuthFlow=true` when creating temporary anonymous users.
        - This ensures the dialog timestamp isn't reset during internal auth flows like Google sign-in.
        - The dialog will now only appear for actual anonymous sign-ins, not during temporary auth state changes.
    - Successfully tested the solution:
        - When cancelling Google sign-in, the "Google sign-in was cancelled" SnackBar appears.
        - The Account Limits dialog does not appear since the anonymous sign-in is part of an internal auth flow.
        - The dialog still appears normally for actual anonymous users.

### Collection Management ✓

- [x] Track card quantities
- [x] Track card conditions
- [x] Support professional grading
- [x] Provide collection statistics
- [x] Enable filtering and sorting
- [x] Implement search functionality
- [x] Support offline access
- [x] **Delete card document when quantity is zero**
- [x] **Accurate unique card count (`collectionCount`)**
- [x] **Fixed permission errors**

### Theme System ✓

- [x] Support light/dark modes with Material 3 ColorScheme
- [x] Custom color selection with flex_color_picker integration
- [x] Dynamic color generation using ColorScheme.fromSeed
- [x] Built-in contrast handling with Material 3
- [x] Theme persistence with Hive storage
- [x] System theme support with automatic switching
- [x] Consistent Material 3 dialog styling

## Progress Tracking

### Recently Completed

1. **Investigate Reauthentication & Sign-in Redirect Issues (Current Session)**
    - Investigated blank reauthentication screen (not reproduced) and post-sign-in redirect failure.
    - Added and removed diagnostic logging in `AuthNotifier` and `ProfileReauthDialog`.
    - Confirmed router listener notification and redirect logic are working correctly.
    - Issues appear resolved or intermittent.

2. **Auth Flow Stability & Linking Fixes (Previous Session)**
    - Resolved `GlobalKey` conflict and incorrect navigation after unlinking providers.
    - Fixed email pre-population regression in the link dialog.
    - Fixed UI update failure after linking Email/Password to Google.
    - Added delay to Google unlink process for stability.
    - Resolved various analysis errors and `use_build_context_synchronously` warnings.
    - Refactored `linkGoogleToAnonymous` merge conflict logic.

3. **Analysis Errors & Provider Refactoring (Previous Session)**
    - Addressed multiple analysis errors (`unused_import`, `invalid_use_of_protected_member`, `deprecated_member_use`, `use_super_parameters`, `unused_local_variable`).
    - Refactored `cardSearchQueryProvider`, `collectionSpecificFilterProvider`, and `collectionSearchQueryProvider` from `StateProvider` to `NotifierProvider` to correctly handle state persistence and side effects (fixing `listenSelf` deprecation).
    - Updated UI components to interact correctly with the refactored `NotifierProvider`s using their methods.
4. **Collection Management Fixes & Enhancements (Objective 50)**
    - Fixed Firestore permission errors during add/update.
    - Implemented transactional `collectionCount` updates and verification.
    - Implemented delete-on-zero-quantity logic.
    - Added quantity text input UI.
    - Fixed grading label capitalization UI.

5. **Fixed Google Authentication Display Name Issue (Objective 30)**
    - Fixed issue where Google display name wasn't storing in Firestore:
        - Added code to extract display name directly from Google provider data
        - Updated logic to prioritize Google provider display name
        - Enhanced logging to track display name at various stages
    - Successfully tested the solution:
        - Display name now correctly extracted from Google provider data
        - Display name properly stored in Firestore user document
        - UI correctly displays the name from Google
    - **Remaining Issue:**
        - Account Limits dialog appears after Google sign-in (separate concern - Fixed in Obj 31)

6. **Data Migration and Firestore Rules Updates (Objective 27)**
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
        - Permission denied errors during data migration **(Resolved in Obj 50)**
        - Need to verify and fix Firestore rules for all migration scenarios **(Partially addressed in Obj 50)**
        - Ensure proper user document creation timing

7. **Fixed Email Update Flow and UI Updates (Objective 26)**
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

### Detailed Development Plan (Phased Approach)

#### Phase 1: Bug Fixes, Core Usability & Setup (Highest Priority)

- [x] **1. Fix App Check Token Issue:** Address `No AppCheckProvider installed` error. (User Handled/Deferred)
- [x] **2. Fix Card Details Page Flicker/Lag:** Fix initial card display and swipe/button responsiveness issues.
- [x] **3. Maintain Screen State:** Preserve filters/sort/search on navigation.
- [x] **4. Finish Favorite/Wishlist Features:** Implement UI (filters, icons).

#### Phase 2: Collection Management & Key Enhancements (High Priority)

- [ ] **5. Multiple Copies of Same Card Handling:** Implement **Solution C (Subcollection per Card)**.
- [x] **6. Delete Card on Zero Quantity:** Delete Firestore doc when quantities are zeroed out.
- [ ] **7. Tablet/Foldable Layout:** Implement adaptive layouts (start with master-detail).

#### Phase 3: New Features & UI Refinements (Medium Priority)

- [ ] **8. User Avatar Upload:** Allow users to upload profile pictures.
- [ ] **9. Add Card Page for Non-Cards (`isNonCard = true`):** Adapt UI for non-card items.
- [ ] **10. Search Result Sorting:** Implement specified sorting logic.
- [ ] **11. Card Description Formatting:** Bold keywords, add crystal cost icons.
- [ ] **12. EX BURST Filter:** Add filter for `ex_burst = true`.
- [ ] **13. Collection Import/Export Feature:** Add CSV, XML, JSON import/export.
- [ ] **14. Theme Settings Page Refinement:** Simplify color picker (Primary/Accent shades only), adjust spacing, ensure responsiveness.
- [ ] **15. Create About Page:** Add static About page.
- [ ] **16. Add Batch Operations:** Implement batch actions for collection management (e.g., add/delete multiple cards).
- [ ] **17. Expand Data Migration:** Implement migration for deck data, user settings, and preferences, ensuring data integrity.

#### Phase 4: Major Features & Infrastructure (Medium-Low Priority)

- [ ] **18. Implement Deck Builder:** Core features - creation, editing, analysis, standard export (CSV, XML, JSON).
- [ ] **19. Add Advanced Deck Analysis Export:** Generate HTML/PDF output with element distribution, cost curves, etc.
- [ ] **20. Add Card Scanner Functionality:** Image recognition, bulk scanning.
- [ ] **21. Collection Price Tracking:** Integrate `fl_chart`, design UI (requires price data source).
- [ ] **22. Google Auth Photo URL Logic:** Prioritize existing Firestore photoURL.
- [ ] **23. Implement Analytics, Crashlytics, Performance Monitoring:** Integrate Firebase services.
- [x] **24. Grading Info Casing:** Correct "Regular"/"Foil" casing.
- [ ] **25. Collection Page Spacing:** Adjust spacing on empty collection page.

#### Phase 5: Modern UI/UX Overhaul & Social (Lower Priority)

- [ ] **26. Modernize UI/UX:** Implement motion, elevation, rounded inputs. Create an onboarding experience (parallax, feature highlights, auth options). Review overall aesthetic.
- [ ] **27. Implement Collection Sharing:** Allow users to share their collections (view-only initially).

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
