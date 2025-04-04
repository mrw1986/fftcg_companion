# Codebase Summary

## Recent Changes

### Analysis Errors & Provider Refactoring (Current Session)

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
- **Status:** Migration complete. Build runner successful. **Extensive testing required.**

### Collection Management Fixes & UI Enhancements (Objective 50) - Completed

- **Context:** Resolved Firestore permission errors, inaccurate `collectionCount`, missing delete-on-zero-quantity logic, and addressed UI requests for quantity input and label capitalization.
- **Changes:** Fixed `CollectionItem.toMap()` serialization. Refactored `UserRepository.updateCollectionCount` to use transactions and added verification. Modified `CollectionRepository.addOrUpdateCard` to delete on zero quantity. Added quantity `TextField` and fixed grading labels in UI.
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

### Prevent Anonymous Dialog After Password Reset (Objective 40) - Completed

- **Context:** "Account Limits" dialog appeared after authenticated user password reset.
- **Changes:** Added `skipAccountLimitsDialog` flag to `AuthService.signOut`.
- **Status:** Implemented.

### Email Verification Status Update Fix (Objective 39) - Completed

- **Context:** Inconsistent Firestore `isVerified` field updates.
- **Changes:** Modified `email_verification_checker.dart` and `AuthService.handleEmailVerificationComplete`. (Flow further refined in Obj 41/42/46).
- **Status:** Implemented (UI timing addressed in Obj 42/44, state reset logic refined in Obj 46).

## Key Components

### Auth Service (lib/core/services/auth_service.dart) - **Refactored & Updated (Obj 45)**

- **Status:** Centralized Firestore user document creation/updates via `firestoreUserSyncProvider`. `deleteUser` now *only* deletes the Firebase Auth user.
- **Pending:** Test deletion flow.

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

#### Riverpod Providers (lib/core/providers/)

- **`auth_provider.dart`:** **Updated (Objective 46, 50)** `authStateProvider` calculates state. `firestoreUserSyncProvider` handles sync, resets verification flag, triggers count verification. Removed incorrect listener.
- **`email_verification_checker.dart`:** **Updated (Objective 42 - Attempt 2, Obj 46)** Polls, updates Firestore, sets detection flag. **Testing needed.**
- **`firestoreUserSyncProvider`:** Listens to `firebaseUserProvider`. Handles sync, resets detection flag, triggers count verification.
- **`emailVerificationDetectedProvider`:** **NEW (Objective 42 - Attempt 2)** Simple `StateProvider<bool>`. Reset logic in `firestoreUserSyncProvider`.
- **`auto_auth_provider.dart`:** **Updated (Objective 46)** Added null safety checks.
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

#### Profile Page Components

- **`account_settings_page.dart`:** **Updated (Objective 42, 44, 45, 46)** Manages account details, re-auth. Watches providers for verification banner. Added `if (mounted)` checks. **Aligned "Unverified" chip logic.** **Added `_handleSuccessfulDeletion` helper.** Calls simplified `AuthService.deleteUser`.

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
- **`reset_password_page.dart`:** **Updated** to call `signOut` with `skipAccountLimitsDialog: true`.

## Data Flow (Refactored & Updated)

- **Authentication Flow (Rebuilt & Refined - Testing)**
- **Firestore User Document Creation/Update:** (Flow unchanged, but now triggers count verification)
- **Collection Add/Update Flow:** (Flow updated for zero quantity deletion)
- **Email Verification Flow (Fixed - Attempt 2 - Testing Needed - Obj 42, 44, 46)**
- **Password Reset Flow (Updated)**
- **Account Deletion Flow (Updated - Objective 45 & 46 - Simplified)**
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

    subgraph Auth State Listener (firestoreUserSyncProvider)
        ListenAuthState[Listen to firebaseUserProvider] --> UserEvent{User Data Changed?};
        UserEvent -- Yes --> CheckResetFlag{Need to Reset Verification Flag?};
        CheckResetFlag -- Yes --> ResetFlag[Reset emailVerificationDetectedProvider=false];
        CheckResetFlag -- No --> CheckSyncNeeded{Need Firestore Sync?};
        ResetFlag --> CheckSyncNeeded;
        CheckSyncNeeded -- Yes --> CallCreateUser[Call UserRepository.createUserFromAuth(user)];
        CallCreateUser --> FirestoreUpdate[Firestore Doc Updated];
        FirestoreUpdate --> VerifyCount[Call UserRepository.verifyAndCorrectCollectionCount]; %% Added Verification Step
        CheckSyncNeeded -- No --> NoOp[No Firestore Action];
        UserEvent -- No --> NoOp;
    end

    subgraph Anonymous Flow
        B -- No --> AnonSignIn[Sign In Anonymously];
        AnonSignIn --> AuthState;
        Anon[Anonymous User] -- Link --> LinkChoice{Link Email/Pass or Google?};
        LinkChoice -- Email/Pass --> LinkEmailPass[AuthService.linkEmailAndPasswordToAnonymous];
        LinkEmailPass --> UpdateFirestoreAnon[Immediate Firestore Update in AuthService];
        UpdateFirestoreAnon --> AuthState;
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
    end

    subgraph Password Reset Flow
        ResetPage[Reset Password Page] -- Authenticated User --> SendResetEmail[UI Calls AuthService.sendPasswordResetEmail];
        SendResetEmail --> SignOutWithFlag[UI Calls AuthService.signOut(skipAccountLimitsDialog=true)];
        SignOutWithFlag --> SkipTimestampReset[AuthService: Skips Hive Timestamp Reset];
        SkipTimestampReset --> SignOutFirebase[AuthService: Signs out Firebase/Google];
        SignOutFirebase --> AuthState;
        ResetPage -- Unauthenticated User --> SendResetEmail2[UI Calls AuthService.sendPasswordResetEmail];
        SendResetEmail2 --> ShowSuccessMessage[UI Shows Success Message];
    end

    subgraph Common Actions
        B -- Yes --> SignedInUser;
        SignedInUser --> ActionChoice{Choose Action};
        ActionChoice -- Sign Out --> SignOutNormal[UI Calls AuthService.signOut];
        SignOutNormal --> ResetTimestamp[AuthService: Resets Hive Timestamp];
        ResetTimestamp --> SignOutFirebase2[AuthService: Signs out Firebase/Google];
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
        ShowSnackbar --> FinalSignOut[Helper: Sign Out User (skipAccountLimitsDialog=true)]; %% Updated Node Text
        FinalSignOut --> NavigateAway[Helper: Navigate Away (with mounted check)]; %% Updated Node Text
        NavigateAway --> AuthState;
    end

    subgraph State & UI
        AuthState[Auth State Change] --> ListenAuthState;
        AuthState --> UpdateUIMain[Update UI via AuthState];
        AuthState --> RouterRedirect[Router Redirect Logic];
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
    style SignOutWithFlag fill:#cce5ff,stroke:#005cb2,stroke-width:1px
    style SkipTimestampReset fill:#cce5ff,stroke:#005cb2,stroke-width:1px
    style SignOutFirebase fill:#cce5ff,stroke:#005cb2,stroke-width:1px
    style SignOutNormal fill:#e1f5fe,stroke:#0277bd,stroke-width:1px
    style ResetTimestamp fill:#e1f5fe,stroke:#0277bd,stroke-width:1px
    style SignOutFirebase2 fill:#e1f5fe,stroke:#0277bd,stroke-width:1px
    style ListenAuthState fill:#d1c4e9,stroke:#512da8,stroke-width:2px
    style UserEvent fill:#d1c4e9,stroke:#512da8,stroke-width:1px
    style CallCreateUser fill:#d1c4e9,stroke:#512da8,stroke-width:1px
    style FirestoreUpdate fill:#b39ddb,stroke:#512da8,stroke-width:1px
    style NoOp fill:#eee,stroke:#999,stroke-width:1px
    style UpdateFirestoreAnon fill:#ffcc80,stroke:#ef6c00,stroke-width:2px
    style UpdateUIMain fill:#e1f5fe,stroke:#0277bd,stroke-width:1px
    style HandleAuthError fill:#ffebcc,stroke:#ff8f00,stroke-width:2px
    style LogWarning fill:#fff9c4,stroke:#fbc02d,stroke-width:1px
    style HandleSuccess fill:#c8e6c9,stroke:#388e3c,stroke-width:2px
    style ShowSnackbar fill:#c8e6c9,stroke:#388e3c,stroke-width:1px
    style FinalSignOut fill:#c8e6c9,stroke:#388e3c,stroke-width:1px
    style NavigateAway fill:#c8e6c9,stroke:#388e3c,stroke-width:1px
    style CheckResetFlag fill:#d1c4e9,stroke:#512da8,stroke-width:1px
    style ResetFlag fill:#ffecb3,stroke:#ffa000,stroke-width:1px
    style CheckSyncNeeded fill:#d1c4e9,stroke:#512da8,stroke-width:1px
    style VerifyCount fill:#b39ddb,stroke:#512da8,stroke-width:2px %% Added Verification Step Style
