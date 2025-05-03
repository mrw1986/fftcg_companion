# Codebase Summary

## Recent Changes

### Comprehensive Email Update Flow Fix (Current Session)

- **Context:** After initiating an email change and verifying the new email via the link, the UI state (pending email and verification status) did not update correctly.
- **Root Causes:**
  1. Token Invalidation: Firebase invalidates the auth token after email verification, but the app wasn't handling this gracefully.
  2. Riverpod State Error: Race condition during state transitions causing provider dependency errors.
  3. Race Condition: Email update completion provider trying to check email update during sign-out.
- **Changes:**
  - **Token Refresh Handling (`auth_provider.dart`):**
    - Added progressive token refresh strategy (try without force first)
    - Added user reload before token refresh attempts
    - Added comprehensive error handling for different error codes
    - Added detailed logging throughout the flow
  - **Error Boundary (`email_update_completion_provider.dart`):**
    - Added safe state reading with error handling
    - Added local value copies to prevent state access during transitions
    - Added graceful error recovery mechanisms
    - Added comprehensive logging for debugging
  - **Action Code Settings (`auth_service.dart`):**
    - Added proper action code settings for better UX
    - Added token refresh helper method
    - Improved error handling for email operations
  - **Lifecycle Management (`account_settings_page.dart`):**
    - Added app resume handling for pending email updates
    - Added safe token refresh and user reload
    - Added UI state synchronization with delays
    - Added manual refresh capability
- **Documentation:**
  - Created `emailUpdateFlowFix.md` with detailed implementation documentation
  - Updated `currentTask.md` with implementation plan and status
- **Status:** Fix implemented. Testing required.

### Fix Account Settings UI Update After Linking (Attempt 3 - Previous Session)

- **Context:** The "Change Password" option still didn't appear immediately after linking, even with user reload and provider invalidation. The `User` object used in the build (`userForUI`) might not be reflecting the absolute latest state immediately after invalidation.
- **Changes:**
  - Modified `lib/features/profile/presentation/widgets/account_info_card.dart`: Converted to `ConsumerWidget` to directly watch `authNotifierProvider` and get the `User` object. Removed the `user` parameter.
  - Modified `lib/features/profile/presentation/pages/account_settings_page.dart`: Removed the `user` parameter from the `AccountInfoCard` constructor call. Removed the erroneous error handling block that referenced `authState.error`.
- **Status:** Fix implemented. Testing required.

### Fix Account Settings UI Update After Linking (Attempt 2 - Previous Session)

- **Context:** The "Change Password" option still didn't appear immediately after linking, even with user reload and provider invalidation. The `User` object used in the build (`userForUI`) might not be reflecting the absolute latest state immediately after invalidation.
- **Changes:**
  - Modified `lib/features/profile/presentation/pages/account_settings_page.dart`:
    - Simplified user object retrieval in `build` method to rely solely on `authState.user` from the `authNotifierProvider`.
    - Removed the error-prone fallback to `firebaseUserProvider.value`.
    - Added a short `Future.delayed(const Duration(milliseconds: 50))` followed by `setState(() {})` after the `reload()` and `invalidate()` calls in `_linkWithGoogle` and `_linkWithEmailPassword`. This forces a delayed rebuild, potentially allowing the invalidated provider state to fully propagate.
- **Status:** Fix implemented but did not resolve the issue based on user feedback and logs. Superseded by Attempt 3.

### Fix Account Settings UI Update After Linking (Attempt 1 - Previous Session)

- **Context:** The "Change Password" option in `AccountSettingsPage` did not appear immediately after linking an Email/Password provider because the `User` object's `providerData` wasn't updated in the UI promptly.
- **Changes:**
  - Modified `_linkWithGoogle` and `_linkWithEmailPassword` in `lib/features/profile/presentation/pages/account_settings_page.dart` to include `FirebaseAuth.instance.currentUser?.reload()` followed by `ref.invalidate(authNotifierProvider)`. This did not fully resolve the issue.
- **Status:** Fix implemented but did not resolve the issue based on user feedback and logs. Superseded by Attempt 2.

### Investigate Reauthentication & Sign-in Redirect Issues (Previous Session)

- **Context:** User reported a blank reauthentication screen and getting stuck on the sign-in page after Google sign-in.
- **Changes:**
  - Added diagnostic logging to `ProfileReauthDialog` and `AuthNotifier`.
  - Tested reauthentication and sign-in flows.
  - Logs confirmed correct provider loading in `ProfileReauthDialog` (though the blank screen issue wasn't reproduced).
  - Logs confirmed correct router listener notification and redirect execution in `AuthNotifier` after Google sign-in.
  - Removed diagnostic logging.
- **Status:** Investigation complete. Issues appear resolved or intermittent. Core logic confirmed to be working correctly.

### Fix Redirect After Linking Google from Account Settings (Previous Session - Attempt 7)

- **Context:** Adding a delay before `setState` (Attempt 6) still resulted in a redirect, although the UI did update correctly before the redirect. The timing of state propagation and router reaction remains problematic.
- **Changes:**
  - Removed the delay before `setState`.
  - Re-added `ref.invalidate(firebaseUserProvider)` in `_linkWithGoogle` *after* the `await` but *before* the `setState`.
  - Added a short `Future.delayed` *between* the invalidation and the `setState`.
- **Rationale:** Invalidate the necessary provider, allow a brief moment for system processing/potential navigation triggers to settle, then force the local rebuild to hopefully catch the updated state without the redirect.
- **Status:** Completed. Testing needed.

### Fix Redirect After Linking Google from Account Settings (Previous Session - Attempt 6)

- **Context:** Using `setState` alone (Attempt 5) fixed the UI update delay but not the redirect.
- **Changes:**
  - Kept provider invalidation removed from `linkGoogleToEmailPasswordProvider`.
  - Added a short `Future.delayed` before the `setState` call in `_linkWithGoogle` within `account_settings_page.dart`.
- **Status:** Completed. Fixed UI update, but redirect persisted.

### Fix UI Update After Linking Google from Account Settings (Previous Session - Attempt 5)

- **Context:** Removing provider invalidations (Attempt 3) fixed the redirect but caused the UI on the Account Settings page to not update immediately after linking Google. Attempting selective invalidation (`firebaseUserProvider` only - Attempt 4) still resulted in a redirect.
- **Changes:**
  - Re-added `ref.invalidate(firebaseUserProvider)` to the `linkGoogleToEmailPasswordProvider` in `lib/core/providers/auth_provider.dart`.
  - Intentionally did *not* re-add `ref.invalidate(authStateProvider)` to avoid triggering the router redirect.
- **Status:** Completed. Testing needed to confirm UI updates correctly without redirecting.

### Fix Redirect After Linking Google from Account Settings (Previous Session - Attempt 4)

- **Context:** Removing explicit invalidations (Attempt 3) fixed the redirect but caused the UI on the Account Settings page to not update immediately after linking Google.
- **Changes:**
  - Re-added `ref.invalidate(firebaseUserProvider)` to the `linkGoogleToEmailPasswordProvider` in `lib/core/providers/auth_provider.dart`.
  - Intentionally did *not* re-add `ref.invalidate(authStateProvider)` to avoid triggering the router redirect.
- **Status:** Completed. Testing needed to confirm UI updates correctly without redirecting.

### Fix Redirect After Linking Google from Account Settings (Previous Session - Attempt 3)

- **Context:** Even after moving `/profile/account` outside the `StatefulShellRoute` (Attempt 2), linking Google still caused a redirect away from the Account Settings page.
- **Changes:**
  - Removed explicit `ref.invalidate(firebaseUserProvider)` and `ref.invalidate(authStateProvider)` calls from `linkGoogleToEmailPasswordProvider` in `lib/core/providers/auth_provider.dart`.
- **Status:** Completed. Fixed redirect, but broke immediate UI update.

### Fix Redirect After Linking Google from Account Settings (Previous Session - Attempt 2)

- **Context:** Linking Google from Account Settings caused an unwanted redirect and `Duplicate GlobalKey` error due to the `StatefulShellRoute` rebuilding after the auth state change.
- **Changes:**
  - Reverted the previous attempt using `isLinkingProvider`.
  - Moved the `/profile/account` route definition in `app_router.dart` outside the `StatefulShellRoute` branches, making it a top-level route.
- **Status:** Completed. `GlobalKey` error resolved, but redirect persisted.

### Fix Email Verification UI (Chip/Banner) (Previous Session - Attempts 3, 4, 5)

- **Context:** After linking Email/Password to Google, the "Unverified" chip appeared correctly (Attempt 3), but the top banner also appeared incorrectly (Attempt 4). After fixing the banner, the chip then failed to disappear after email verification (Attempt 5).
- **Changes:**
  - **Attempt 3:** Corrected `authStateProvider` logic (`lib/core/providers/auth_provider.dart`) to return `AuthStatus.emailNotVerified` if `hasPasswordProvider && !user.emailVerified`, regardless of other providers.
  - **Attempt 4:** Refined banner visibility logic in `AccountSettingsPage` to only show if the *sole* auth method is unverified email/password.
  - **Attempt 5:** Refined chip visibility logic in `AccountSettingsPage` to hide the chip immediately when `emailVerificationDetectedProvider` becomes true (`showUnverifiedChip = authState.emailNotVerified && !verificationDetected`). Fixed related debug log and lint error.
- **Status:** Banner logic fixed. Chip logic fixed. **Testing needed** to confirm the chip now disappears correctly after verification.

### Fix Email Verification Status Update After Linking (Previous Session)

- **Context:** After linking Email/Password to Google and verifying the email, the UI state didn't update to show the verified status because the `EmailVerificationChecker` wasn't running when the `AuthState` was `authenticated` (due to Google), even if the linked email was unverified.
- **Changes:**
  - Modified the listener logic in `emailVerificationCheckerProvider` (`lib/core/providers/email_verification_checker.dart`).
  - The checker now starts polling if the `AuthState` is `emailNotVerified` OR if it's `authenticated` and the `user.emailVerified` flag is false.
  - Updated the initial check logic in the provider to match this condition.
- **Status:** Completed. Testing needed.

### Display Pending Email Update (Previous Session)

- **Context:** Improve user feedback after initiating an email change by showing the pending email address in Account Settings.
- **Changes:**
  - Created `emailUpdateNotifierProvider` to store the pending email.
  - Updated `account_settings_page.dart` to set the pending email state on initiating verification and clear it on sign-out/deletion.
  - Updated `account_info_card.dart` to display the pending email with a chip.
  - Updated `firestoreUserSyncProvider` in `auth_provider.dart` to automatically clear the pending state when the user's email updates in Firebase Auth or on sign-out/error.
- **Status:** Completed.

### Removed Account Limits Dialog (Previous Session)

- **Context:** The `AccountLimitsDialog` (previously shown to anonymous/unverified users) is being removed in favor of a future onboarding experience. This involved removing the dialog widget, its invocation logic, and related parameters/logic in the authentication service.
- **Changes:**
  - Deleted `lib/features/profile/presentation/widgets/account_limits_dialog.dart`.
  - Removed calls to `AccountLimitsDialog.showIfNeeded` and associated Hive timestamp reset logic from `lib/app/loading_wrapper.dart`.
  - Removed the `skipAccountLimitsDialog` parameter and related Hive timestamp logic from `AuthService.signOut` in `lib/core/services/auth_service.dart`.
  - Removed the `skipAccountLimitsDialog` argument from `signOut` calls in `lib/features/profile/presentation/pages/account_settings_page.dart` and `lib/features/profile/presentation/pages/reset_password_page.dart`.
- **Status:** Completed.

### Auth Flow Stability & Linking Fixes (Previous Session)

- **Context:** Resolved several issues related to provider linking/unlinking, including incorrect navigation after unlinking, `GlobalKey` conflicts, email pre-population regressions, and UI update failures.
- **Changes:**
  - Introduced `authStatusProvider` to decouple router redirects from internal `User` object changes.
  - Updated GoRouter `redirect` logic to watch `authStatusProvider`.
  - Added a delay to `AuthService.unlinkProvider` for Google unlinking to prevent timing issues.
  - Corrected email lookup logic in `AccountInfoCard` for pre-population.
  - Added provider invalidation to `linkEmailPasswordToGoogleProvider` for UI updates.
  - Removed explicit navigation from `_unlinkProvider` in `account_settings_page.dart`.
- **Status:** Completed. All reported auth flow issues (unlinking navigation, linking UI updates, email pre-population) are resolved.

### Analysis Errors & Provider Refactoring (Previous Session)

- **Context:** Addressed various analysis errors (`unused_import`, `invalid_use_of_protected_member`, `deprecated_member_use`, `use_super_parameters`, `unused_local_variable`) and refactored providers using deprecated `listenSelf` for persistence.
- **Changes:**
  - Removed unused imports and local variables.
  - Fixed `use_super_parameters` warnings.
  - Refactored `cardSearchQueryProvider`, `collectionSpecificFilterProvider`, and `collectionSearchQueryProvider` from `StateProvider` to `NotifierProvider` to correctly handle state persistence via Hive and resolve `listenSelf` deprecation warnings.
  - Updated UI components (`cards_page.dart`, `card_app_bar_actions.dart`, `card_search_bar.dart`, `collection_edit_page.dart`, `collection_page.dart`, `collection_filter_bar.dart`, `collection_filter_dialog.dart`) to use the appropriate methods (`setQuery`, `clearFilters`, `setFilter`, `removeFilter`) on the refactored notifiers instead of accessing `.state` directly.
- **Status:** Completed.

### Independent Screen States (Cards vs. Collection)

- **Context:** The Cards page and Collection page previously shared the same state for filters, search query, and view preferences.
- **Requirement:** Implement independent state management for these UI aspects for each feature.
- **Changes:**
  - **Filter State:** Duplicated `filter_provider.dart` -> `collection_filter_provider.dart`. Renamed providers/notifiers (`cardFilterProvider`, `collectionFilterProvider`). Added `collectionSpecificFilterProvider` (now `NotifierProvider`). Updated UI widgets.
  - **Search State:** Duplicated `search_provider.dart` -> `collection_search_provider.dart`. Renamed providers (`cardSearchQueryProvider`, `collectionSearchQueryProvider`). Updated UI widgets. **Refactored both to `NotifierProvider` for persistence.**
  - **View Preferences State:** Duplicated `view_preferences_provider.dart` -> `collection_view_preferences_provider.dart`. Renamed providers/notifiers (`cardViewPreferencesProvider`, `collectionViewPreferencesProvider`). Updated Hive keys. Updated UI widgets.
  - **Build Runner:** Executed.
- **Status:** Refactoring complete. Persistence logic for duplicated filter providers (StateNotifierProviders) still needs implementation (TODOs added). Search/Specific filter persistence handled by NotifierProvider refactor.

### Model Migration: Freezed to Dart Mappable (Objective 51 - Completed)

- **Context:** Encountered persistent build errors and complexity related to the `freezed` code generation for models.
- **Changes:** Replaced `freezed` with `dart_mappable`. Migrated models, updated serialization calls (`fromMap`/`toMap`), updated Hive adapters.
- **Status:** Migration complete. **Extensive testing required.**

### Collection Management Fixes & UI Enhancements (Objective 50) - Completed

- **Context:** Resolved Firestore permission errors, inaccurate `collectionCount`, missing delete-on-zero-quantity logic, and addressed UI requests for quantity input and label capitalization.
- **Changes:** Fixed `CollectionItem.toMap()` serialization. Refactored `UserRepository.updateCollectionCount` to use atomic transactions. Modified `CollectionRepository.addOrUpdateCard` to delete on zero quantity. Added quantity `TextField` and fixed grading labels in UI.
- **Status:** Fixes and enhancements applied. Testing recommended.

### Fix Initialization Error During Set Count Preload (Objective 47) - Completed (Testing Needed)

- **Context:** App initialization failed with `NoSuchMethodError` on `.ignore()`.
- **Changes:** Replaced `.ignore()` with `await` on the future in `initialization_provider.dart`.
- **Status:** Fix applied. Testing required.

### Fix Riverpod Error After Google Linking & Subsequent Analyzer Issues (Objective 46) - Completed (Testing Needed)

- **Context:** Google linking caused Riverpod error and revealed other issues.
- **Changes:** Removed incorrect listener provider. Integrated logic into `firestoreUserSyncProvider`. Fixed analyzer errors with null checks and `mounted` checks.
- **Status:** Fixes applied. Testing required.

### Refine Account Deletion Flow & Add Confirmation (Objective 45) - Completed (Testing Needed)

- **Context:** Deletion flow issues, no confirmation, analyzer errors.
- **Changes:** Simplified `AuthService.deleteUser` (relies on Firebase Extension). Updated re-auth logic. Added `_handleSuccessfulDeletion` helper with Snackbar (workaround), sign-out, navigation, and `mounted` check.
- **Status:** Fixes applied. Testing required.

### Fix "Unverified" Chip Logic (Objective 44) - Completed (Testing Needed)

- **Context:** "Unverified" chip didn't update consistently with banner.
- **Changes:** Aligned chip logic with banner logic using `emailVerificationDetectedProvider`.
- **Status:** Fix applied. Testing required.

### Fix Email Verification UI Update Delay (Objective 42 - Attempt 2) - Completed (Testing Needed)

- **Context:** Verification banner didn't update immediately.
- **Changes:** Implemented hybrid approach (Firestore update + `emailVerificationDetectedProvider`).
- **Status:** Fix applied. Testing required. (Chip logic addressed in Obj 44)

### Diagnose Google Linking Error and Consolidate User Creation Logic (Objective 41) - Completed

- **Context:** Google linking failed (`credential-already-in-use`), duplicated logic, Riverpod error.
- **Changes:** Centralized Firestore updates via `firestoreUserSyncProvider`. Added router logic.
- **Result:** Linking error resolved. Navigation fixed. Router improved. Revealed email verification UI delay (Obj 42). Riverpod error fixed (Obj 46).

### Prevent Anonymous Dialog After Password Reset (Objective 40) - Completed (Now Removed)

- **Context:** "Account Limits" dialog appeared after authenticated user password reset.
- **Changes:** Added `skipAccountLimitsDialog` flag to `AuthService.signOut`. **This flag and related logic have now been removed.**
- **Status:** Logic removed as part of Account Limits Dialog removal.

### Email Verification Status Update Fix (Objective 39) - Completed

- **Context:** Inconsistent Firestore `isVerified` field updates.
- **Changes:** Modified `email_verification_checker.dart` and `AuthService.handleEmailVerificationComplete`. (Flow further refined in Obj 41/42/46).
- **Status:** Implemented (UI timing addressed in Obj 42/44, state reset logic refined in Obj 46).

## Key Components

### Auth Service (lib/core/services/auth_service.dart) - **Updated**

- **Status:** Centralized Firestore user document creation/updates via `firestoreUserSyncProvider`. `deleteUser` only deletes the Firebase Auth user. Linking/unlinking logic handled via providers/service methods. **Removed `skipAccountLimitsDialog` parameter and related Hive logic from `signOut` method.**
- **Pending:** None directly related to recent changes.

### User Repository (lib/features/profile/data/repositories/user_repository.dart) - **Updated (Obj 50)**

- **Status:** `createUserFromAuth` handles initialization/updates. `deleteUser` removes Firestore doc. **`updateCollectionCount` refactored to use atomic transactions.** **Added `verifyAndCorrectCollectionCount` method.**
- **Pending:** Testing required for count verification.

### Collection Repository (lib/features/collection/data/repositories/collection_repository.dart) - **Updated (Obj 50)**

- **Status:** Handles fetching, adding, updating, and removing collection items. **`addOrUpdateCard` now checks for zero quantity and calls `removeCard` accordingly.** Calls transactional `UserRepository.updateCollectionCount`.
- **Pending:** Testing required for zero quantity deletion.

### Collection Item Model (lib/features/collection/domain/models/collection_item.dart) - **Updated (Obj 50)**

- **Status:** Defines the structure for collection items. **`toMap()` method updated.**
- **Pending:** None.

### Firestore Rules (firestore.rules) - **Updated (Obj 50)**

- **Status:** Updated `allow update` rule for `/users/{userId}`. **Corrected `isValidCollectionItem` quantity check.**
- **Pending:** Testing required.

#### Riverpod Providers (lib/core/providers/ & lib/features/profile/presentation/providers/) - **Updated**

- **`auth_provider.dart`:**
  - `authNotifierProvider` (NotifierProvider) manages core auth state (`AuthState`) and notifies router via `Listenable`.
  - `firestoreUserSyncProvider` logic integrated into `AuthNotifier`'s `_triggerFirestoreSync`.
  - `linkEmailPasswordToGoogleProvider`, `unlinkProviderProvider`, etc. (FutureProviders) handle specific auth operations and invalidate `authNotifierProvider`.
- **`email_verification_checker.dart`:** Polls, updates Firestore, sets detection flag.
- **`emailVerificationDetectedProvider`:** Simple `StateProvider<bool>`. Reset logic in `AuthNotifier`.
- **`auto_auth_provider.dart`:** Handles initial anonymous sign-in logic.
- **`email_update_provider.dart`:** `emailUpdateNotifierProvider` (NotifierProvider) manages the state of a pending email update (`pendingEmail`).
- Core auth state and action providers.

#### Cards Feature Providers (lib/features/cards/presentation/providers/) - **Refactored**

- **`filter_provider.dart`:** Renamed to `cardFilterProvider` (StateNotifierProvider). Manages filters **for Cards page**. (TODO: Implement persistence).
- **`search_provider.dart`:** Renamed to `cardSearchQueryProvider` (**Refactored to NotifierProvider**). Manages search state **for Cards page**. Handles persistence via Hive. `cardSearchControllerProvider` (StateProvider) remains for UI controller.
- **`view_preferences_provider.dart`:** Renamed to `cardViewPreferencesProvider` (NotifierProvider). Manages view preferences **for Cards page**. Persists state to Hive.
- **`filter_options_provider.dart`:** Unchanged. Provides available filter options.
- **`filtered_search_provider.dart`:** Updated to use `cardFilterProvider` and `cardSearchQueryProvider`. Combines filtering/searching for Cards page.
- **`set_card_count_provider.dart`:** Updated to use `cardFilterProvider`. Calculates filtered counts per set.

#### Collection Feature Providers (lib/features/collection/presentation/providers/) - **NEW/Refactored**

- **`collection_filter_provider.dart`:** **NEW** `collectionFilterProvider` (StateNotifierProvider). Manages shared card filters **for Collection page**. (TODO: Implement persistence).
- **`collection_search_provider.dart`:** **NEW** `collectionSearchQueryProvider` (**Refactored to NotifierProvider**). Manages search state **for Collection page**. Handles persistence via Hive. `collectionSearchControllerProvider` (StateProvider) remains for UI controller.
- **`collection_view_preferences_provider.dart`:** **NEW** `collectionViewPreferencesProvider` (NotifierProvider). Manages view preferences **for Collection page**. Persists state to Hive.
- **`collection_providers.dart`:**
  - **NEW:** `collectionSpecificFilterProvider` (**Refactored to NotifierProvider**). Manages collection-only filters (type, graded). Handles persistence via Hive.
  - Updated `filteredCollectionProvider` and `searchedCollectionProvider` to use `collectionFilterProvider`, `collectionSpecificFilterProvider`, and `collectionSearchQueryProvider`.

#### Profile Page Components - **Updated**

- **`account_settings_page.dart`:** **Updated.** Manages account details, re-auth, linking/unlinking calls. Uses root context for SnackBars. Corrected `mounted` checks. Removed `skipAccountLimitsDialog` from `signOut` call. **Now sets/clears `emailUpdateNotifierProvider` state and passes `pendingEmail` to `AccountInfoCard`. Added user reload and provider invalidation after successful linking operations. Simplified user object retrieval in `build` method. Added delayed `setState` after linking. Removed erroneous error handling block.**
- **`account_info_card.dart`:** **Updated.** Converted to `ConsumerWidget` to directly watch `authNotifierProvider`. Removed `user` parameter. Added optional `pendingEmail` parameter. Displays pending email using a `ListTile` and `Chip`.
- **`account_limits_dialog.dart`:** **DELETED.**
- **`profile_reauth_dialog.dart`:** **Updated.** Loads available providers (`password`, `google.com`) and conditionally displays UI elements. Diagnostic logging added and removed.

#### Collection Page Components - **Updated**

- **`collection_item_detail_page.dart`:** **Updated (Obj 50)** Displays details. **Fixed grading labels.**
- **`collection_edit_page.dart`:** **Updated (Obj 50)** Add/edit items. **Added quantity `TextField`.** Updated to use `cardSearchQueryProvider`. **Fixed interaction with refactored `cardSearchQueryProvider`.**
- **`collection_page.dart`:** Updated to use `collectionViewPreferencesProvider` and `collectionSearchQueryProvider`. **Fixed interaction with refactored `collectionSearchQueryProvider`.**
- **`collection_filter_dialog.dart`:** Updated to use `collectionFilterProvider` and `collectionSpecificFilterProvider`. **Fixed interaction with refactored `collectionSpecificFilterProvider`.**
- **`collection_filter_bar.dart`:** Updated to use `collectionSpecificFilterProvider`. **Fixed interaction with refactored `collectionSpecificFilterProvider` and removed unused variables.**

#### Cards Page Components - **Updated**

- **`cards_page.dart`:** Updated to use `cardViewPreferencesProvider` and `cardSearchQueryProvider`. **Fixed interaction with refactored `cardSearchQueryProvider`.**
- **`card_app_bar_actions.dart`:** Updated to use `cardViewPreferencesProvider` and `cardSearchQueryProvider`. **Fixed interaction with refactored `cardSearchQueryProvider`.**
- **`card_search_bar.dart`:** Updated to use `cardSearchQueryProvider`. **Fixed interaction with refactored `cardSearchQueryProvider`.**
- **`filter_dialog.dart`:** Updated to use `cardFilterProvider`.
- **`sort_bottom_sheet.dart`:** Updated to use `cardFilterProvider` and `cardSearchQueryProvider`.

#### Authentication Pages

- **`register_page.dart`:** Relies on router redirect logic.
- **`reset_password_page.dart`:** **Updated** to remove `skipAccountLimitsDialog` from `signOut` call.

#### App Initialization

- **`loading_wrapper.dart`:** **Updated.** Removed calls to `AccountLimitsDialog.showIfNeeded` and related Hive timestamp logic.

## Data Flow (Refactored & Updated)

- **Authentication Flow (Rebuilt & Refined)**
  - **Linking:** **Updated.** Now includes user reload, provider invalidation, and a delayed `setState` to ensure immediate UI updates.
  - **Unlinking:** **Incorrect redirect and GlobalKey error persist.**
  - **Deletion:** Works correctly, including SnackBar context.
  - **Reauthentication:** Logic exists, UI (`ProfileReauthDialog`) loads providers correctly. Blank screen issue not reproduced.
  - **Sign-in Redirect:** Router listener notification and redirect logic confirmed working correctly after Google sign-in. Issue of getting stuck on `/auth` appears resolved/intermittent.
- **Firestore User Document Creation/Update:** Triggers count verification.
- **Collection Add/Update Flow:** Deletes on zero quantity.
- **Email Verification Flow:** Hybrid approach implemented.
- **Password Reset Flow:** Updated. No longer skips dialog timestamp reset (logic removed).
- **Account Deletion Flow:** Simplified, uses helper for cleanup. No longer skips dialog timestamp reset (logic removed). **Now clears pending email state.**
- **Email Update Flow:** **Updated.** Initiating an update now sets a pending email state (`emailUpdateNotifierProvider`). The UI (`AccountInfoCard`) displays this pending email. The state is cleared automatically by `AuthNotifier` upon successful verification or sign-out/error.
- **Cards/Collection Filtering/Search/View:** (Flow Refactored)
  - Each feature uses its own providers.
  - State changes isolated to the respective feature.
  - Persistence for search/specific filters handled by `NotifierProvider`s. Filter persistence (StateNotifier) is TODO.

```mermaid
graph TD
    subgraph Entry Points
        A[App Start] --> B{User Signed In?};
        C[Login/Register Page] --> D{Choose Method};
    end

    subgraph Auth State Listener (AuthNotifier)
        ListenAuthState[Listen to Firebase Auth Stream] --> UserEvent{User Data Changed?};
        UserEvent -- Yes --> ReloadUser[Reload User Data];
        ReloadUser -- Success --> DetermineState{Determine AuthState};
        ReloadUser -- Failure --> LogError[Log Reload Error];
        LogError --> DetermineState; %% Proceed with potentially stale data
        DetermineState --> StateChanged{State Status Changed?};
        StateChanged -- Yes --> UpdateInternalState[Update AuthNotifier State];
        UpdateInternalState --> SyncAndNotify[Sync Firestore & Notify Router];
        StateChanged -- No --> CheckUserChanged{User Object Changed?};
        CheckUserChanged -- Yes --> SyncOnly[Sync Firestore Only];
        CheckUserChanged -- No --> NoOp[No Action];
        SyncAndNotify --> RouterRedirect[Router Redirect Logic];
        SyncOnly --> NoOp;
    end

    subgraph Firestore Sync (_triggerFirestoreSync in AuthNotifier)
        SyncAndNotify --> VerifyToken[Verify ID Token];
        SyncOnly --> VerifyToken;
        VerifyToken -- Valid --> CreateOrUpdateUser[Call UserRepository.createUserFromAuth];
        CreateOrUpdateUser --> VerifyCount[Call UserRepository.verifyAndCorrectCollectionCount];
        VerifyCount --> CheckPendingEmail{User Email Matches Pending?};
        CheckPendingEmail -- Yes --> ClearPendingEmail[Clear Pending Email State];
        CheckPendingEmail -- No --> SyncComplete[Sync Complete];
        ClearPendingEmail --> SyncComplete;
        VerifyToken -- Invalid --> ForceSignOut[Force Sign Out];
        ForceSignOut --> AuthState;
    end

    subgraph Anonymous Flow
        B -- No --> AnonSignIn[Sign In Anonymously];
        AnonSignIn --> AuthState;
        Anon[Anonymous User] -- Link --> LinkChoice{Link Email/Pass or Google?};
        LinkChoice -- Email/Pass --> LinkEmailPass[UI Calls _linkWithEmailPassword]; %% Changed Trigger
        LinkEmailPass --> LinkEmailPassProvider[Provider: linkEmailAndPasswordToAnonymous]; %% Changed Provider
        LinkEmailPassProvider --> ReloadInvalidateSetState1[Reload User, Invalidate AuthNotifier, Delayed SetState]; %% NEW
        ReloadInvalidateSetState1 --> AuthState; %% NEW
        LinkChoice -- Google --> LinkGoogle[AuthService.linkGoogleToAnonymous];
        LinkGoogle -- Exists --> MergePrompt{Merge Data?};
        MergePrompt -- Yes --> MigrateData[Migrate Data];
        MergePrompt -- No --> DiscardData[Keep Google Data];
        MigrateData --> SignOutSignIn[Sign Out & Sign In w/ Google];
        DiscardData --> SignOutSignIn;
        LinkGoogle -- Success --> SignOutSignIn;
        SignOutSignIn --> AuthState;
    end

    subgraph Email/Password Flow
        D -- Email/Pass --> EmailChoice{Register or Login?};
        EmailChoice -- Register --> RegisterEmail[Register + Send Verification];
        EmailChoice -- Login --> LoginEmail[Login Email/Pass];
        RegisterEmail --> ShowVerifyDialog[Show Verification Dialog];
        ShowVerifyDialog -- OK Clicked --> StartChecker[Start Email Verification Checker];
        StartChecker --> AuthState;
        LoginEmail --> AuthState;
        EmailUser[Email/Pass User] -- Actions --> OtherActions[Other Account Actions];
        EmailUser -- Unverified --> StartChecker2[Start Email Verification Checker];
    end

    subgraph Email Verification Check Flow (Fixed - Attempt 2 - Testing Needed - Obj 42, 44, 46)
        StartChecker --> LoopCheck{Checker: Periodically Reload User};
        StartChecker2 --> LoopCheck;
        LoopCheck -- Verified? --> IsVerified{emailVerified == true?};
        IsVerified -- No --> LoopCheck;
        IsVerified -- Yes --> UpdateFirestoreChecker[Checker: Update Firestore Immediately];
        UpdateFirestoreChecker --> SetDetectionFlag[Checker: Set emailVerificationDetectedProvider=true];
        SetDetectionFlag --> CancelTimer[Checker: Cancel Timer];
        SetDetectionFlag --> UpdateUIImmediate[UI Hides Banner & Chip Immediately];
        CancelTimer --> StreamEmit{Firebase Stream Emits Updated User};
        StreamEmit --> AuthState;
    end

    subgraph Google Flow
        D -- Google --> LoginGoogle[Login/Register with Google];
        LoginGoogle --> AuthState;
        GoogleUser[Google User] -- Actions --> OtherActions2[Other Account Actions];
        GoogleUser -- Link Email/Pass --> LinkEmailPassToGoogle[UI Calls _linkWithEmailPassword];
        LinkEmailPassToGoogle --> LinkProviderCall[Provider: linkEmailPasswordToGoogle];
        LinkProviderCall --> ReloadInvalidateSetState2[Reload User, Invalidate AuthNotifier, Delayed SetState]; %% NEW
        ReloadInvalidateSetState2 --> AuthState; %% NEW
    end

    subgraph Password Reset Flow
        ResetPage[Reset Password Page] -- Authenticated User --> SendResetEmail[UI Calls AuthService.sendPasswordResetEmail];
        SendResetEmail --> SignOutAfterReset[UI Calls AuthService.signOut]; %% Removed skip flag
        SignOutAfterReset --> SignOutFirebase[AuthService: Signs out Firebase/Google]; %% Removed skip timestamp step
        SignOutFirebase --> AuthState;
        ResetPage -- Unauthenticated User --> SendResetEmail2[UI Calls AuthService.sendPasswordResetEmail];
        SendResetEmail2 --> ShowSuccessMessage[UI Shows Success Message];
    end

    subgraph Common Actions
        B -- Yes --> SignedInUser;
        SignedInUser --> ActionChoice{Choose Action};
        ActionChoice -- Sign Out --> SignOutNormal[UI Calls AuthService.signOut];
        SignOutNormal --> SignOutFirebase2[AuthService: Signs out Firebase/Google]; %% Removed timestamp reset step
        SignOutFirebase2 --> AuthState;
        ActionChoice -- Delete Account --> AttemptDelete[UI Calls AuthService.deleteUser];
        AttemptDelete --> DeleteAuth{AuthService: Delete Auth User}; %% Removed Firestore Step
        DeleteAuth -- Success --> HandleSuccess[UI Calls _handleSuccessfulDeletion Helper];
        DeleteAuth -- Failure --> HandleAuthError{Auth Error?};
        HandleAuthError -- user-not-found --> LogWarning[Log Warning (Ignore Error)];
        LogWarning --> HandleSuccess; %% Treat as success
        HandleAuthError -- requires-recent-login --> HandleReauth[UI Handles Re-auth Prompt];
        HandleAuthError -- Other --> HandleOtherAuthError[UI Handles Error];
        HandleReauth -- User Re-authenticates --> AttemptDelete; %% Retry the same simplified delete
        HandleReauth -- User Cancels --> SignedInUser;
        HandleSuccess --> ShowSnackbar[Helper: Show Success Snackbar];
        ShowSnackbar --> FinalSignOut[Helper: Sign Out User]; %% Removed skip flag
        FinalSignOut --> NavigateAway[Helper: Navigate Away (with mounted check)];
        NavigateAway --> AuthState;
        ActionChoice -- Link Google --> LinkGoogleFromSettings[UI Calls _linkWithGoogle];
        LinkGoogleFromSettings --> LinkGoogleProviderCall[Provider: linkGoogleToEmailPassword];
        LinkGoogleProviderCall --> ReloadInvalidateSetState3[Reload User, Invalidate AuthNotifier, Delayed SetState]; %% NEW
        ReloadInvalidateSetState3 --> AuthState; %% NEW
    end

    subgraph State & UI
        AuthState[Auth State Change] --> ListenAuthState;
        AuthState --> UpdateUIMain[Update UI via AuthState];
        AuthState --> RouterRedirect;
    end

    style NavigateToAccount1 fill:#c9ffc9,stroke:#333,stroke-width:1px
    style NavigateToAccount2 fill:#c9ffc9,stroke:#333,stroke-width:1px
    style NavigateToAccount3 fill:#c9ffc9,stroke:#333,stroke-width:1px
    style NavigateToAccount4 fill:#c9ffc9,stroke:#333,stroke-width:1px
    style ShowVerifyDialog fill:#ffffcc,stroke:#333,stroke-width:1px
    style DeleteAuth fill:#ffcccc,stroke:#333,stroke-width:2px
    style HandleReauth fill:#fdc,stroke:#333,stroke-width:2px
    style LoopCheck fill:#e0f7fa,stroke:#00796b,stroke-width:1px
    style IsVerified fill:#fff9c4,stroke:#fbc02d,stroke-width:2px
    style UpdateFirestoreChecker fill:#ffcc80,stroke:#ef6c00,stroke-width:2px
    style SetDetectionFlag fill:#ffecb3,stroke:#ffa000,stroke-width:1px
    style CancelTimer fill:#ffecb3,stroke:#ffa000,stroke-width:1px
    style UpdateUIImmediate fill:#c8e6c9,stroke:#388e3c,stroke-width:2px
    style StreamEmit fill:#dcedc8,stroke:#689f38,stroke-width:1px
    style SignOutAfterReset fill:#cce5ff,stroke:#005cb2,stroke-width:1px %% Updated node name
    style SignOutFirebase fill:#cce5ff,stroke:#005cb2,stroke-width:1px
    style SignOutNormal fill:#e1f5fe,stroke:#0277bd,stroke-width:1px
    style SignOutFirebase2 fill:#e1f5fe,stroke:#0277bd,stroke-width:1px
    style ListenAuthState fill:#d1c4e9,stroke:#512da8,stroke-width:2px
    style UserEvent fill:#d1c4e9,stroke:#512da8,stroke-width:1px
    style ReloadUser fill:#e8eaf6,stroke:#3f51b5,stroke-width:1px
    style DetermineState fill:#e8eaf6,stroke:#3f51b5,stroke-width:1px
    style StateChanged fill:#e8eaf6,stroke:#3f51b5,stroke-width:1px
    style UpdateInternalState fill:#e8eaf6,stroke:#3f51b5,stroke-width:1px
    style SyncAndNotify fill:#e8eaf6,stroke:#3f51b5,stroke-width:1px
    style CheckUserChanged fill:#e8eaf6,stroke:#3f51b5,stroke-width:1px
    style SyncOnly fill:#e8eaf6,stroke:#3f51b5,stroke-width:1px
    style VerifyToken fill:#b39ddb,stroke:#512da8,stroke-width:1px
    style CreateOrUpdateUser fill:#b39ddb,stroke:#512da8,stroke-width:1px
    style VerifyCount fill:#b39ddb,stroke:#512da8,stroke-width:1px
    style CheckPendingEmail fill:#b39ddb,stroke:#512da8,stroke-width:1px
    style ClearPendingEmail fill:#b39ddb,stroke:#512da8,stroke-width:1px
    style SyncComplete fill:#b39ddb,stroke:#512da8,stroke-width:1px
    style ForceSignOut fill:#ffcdd2,stroke:#c62828,stroke-width:1px
    style NoOp fill:#eee,stroke:#999,stroke-width:1px
    style UpdateFirestoreAnon fill:#ffcc80,stroke:#ef6c00,stroke-width:2px
    style UpdateUIMain fill:#e1f5fe,stroke:#0277bd,stroke-width:1px
    style HandleAuthError fill:#ffebcc,stroke:#ff8f00,stroke-width:2px
    style LogWarning fill:#fff9c4,stroke:#fbc02d,stroke-width:1px
    style HandleSuccess fill:#c8e6c9,stroke:#388e3c,stroke-width:2px
    style ShowSnackbar fill:#c8e6c9,stroke:#388e3c,stroke-width:1px
    style FinalSignOut fill:#c8e6c9,stroke:#388e3c,stroke-width:1px
    style NavigateAway fill:#c8e6c9,stroke:#388e3c,stroke-width:1px
    style ReloadInvalidateSetState1 fill:#a5d6a7,stroke:#2e7d32,stroke-width:2px %% NEW
    style ReloadInvalidateSetState2 fill:#a5d6a7,stroke:#2e7d32,stroke-width:2px %% NEW
    style ReloadInvalidateSetState3 fill:#a5d6a7,stroke:#2e7d32,stroke-width:2px %% NEW

</final_file_content>

IMPORTANT: For any future changes to this file, use the final_file_content shown above as your reference. This content reflects the current state of the file, including any auto-formatting (e.g., if you used single quotes but the formatter converted them to double quotes). Always base your SEARCH/REPLACE operations on this final version to ensure accuracy.
