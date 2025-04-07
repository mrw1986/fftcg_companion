# Current Task

## Current Objective: Fix Email Verification Status Update After Linking (Attempt 2)

### Context

- After linking Email/Password to Google and verifying the email, the UI state still didn't update correctly.
- Previous fix adjusted the `EmailVerificationChecker` trigger, but the issue persisted.
- Further analysis suggested the `authStateProvider` might be incorrectly calculating the state or the `AuthState` constructor might be setting the internal `emailNotVerified` flag incorrectly even when the overall status should be `authenticated`.

### Actions Taken

1. **Modified `authStateProvider` Logic:** Updated the state calculation logic in `lib/core/providers/auth_provider.dart`. It now returns `AuthStatus.emailNotVerified` *only* if the user has *only* an unverified email/password provider. Otherwise (if email is verified OR Google is linked), it returns `AuthStatus.authenticated`.
2. **Modified `AuthState` Constructor:** Simplified the `AuthState.authenticated` constructor to always set its internal `emailNotVerified` flag to `false`. The distinction between verified/unverified is now solely handled by the `AuthStatus` enum returned by `authStateProvider`.

### Status

- Completed. This change should ensure the correct `AuthState` (with `emailNotVerified: false`) is emitted once the underlying `User` object reports `emailVerified: true`.

### Next Steps

- Update `codebaseSummary.md` to reflect these changes.
- Request user testing for the scenario: Link Email/Pass to Google -> Verify Email -> Check if UI updates correctly.

## Previous Objectives (Completed)

### Objective: Fix Auth Flow Issues (Unlinking, Linking UI, Email Pre-population)

- **Context:** Resolved several issues related to provider linking/unlinking, including incorrect navigation after unlinking, `GlobalKey` conflicts, email pre-population regressions, and UI update failures.
- **Action:** Introduced `authStatusProvider`, updated GoRouter `redirect` logic, added delay to `AuthService.unlinkProvider` for Google, corrected email lookup logic in `AccountInfoCard`, added provider invalidation to `linkEmailPasswordToGoogleProvider`.
- **Status:** Completed. All reported auth flow issues resolved.

### Objective: Verify Auth Flow Fixes (Unlinking, Linking UI, Email Pre-population)

- **Context:** After unlinking a provider while remaining authenticated, the app incorrectly navigated to `/` and threw a `Duplicate GlobalKey` error.
- **Action:** Created `authStatusProvider`, updated router `redirect` logic, added delay to Google unlink in `AuthService`, corrected email lookup logic in `AccountInfoCard`, added provider invalidation to `linkEmailPasswordToGoogleProvider`.
- **Status:** Completed. All reported issues resolved and confirmed by user.

### Objective: Attempt to Fix Navigation/Context Errors After Auth Changes

- **Context:** A `Multiple widgets used the same GlobalKey` error occurred after account linking and unlinking. A `Looking up a deactivated widget's ancestor is unsafe` error occurred after account deletion. An incorrect redirect occurred after unlinking.
- **Action:**
  - Refactored `app_router.dart` to replace `ShellRoute` with `StatefulShellRoute.indexedStack`. Updated `ScaffoldWithNavBar`. Corrected back button handling.
  - Modified `_handleSuccessfulDeletion` in `account_settings_page.dart` to use the root navigator's context for the SnackBar.
  - Simplified `LinkEmailPasswordDialog` (removed explicit invalidations/delays, used root context for SnackBar).
  - Corrected `use_build_context_synchronously` warnings in linking/unlinking functions using appropriate `mounted` checks.
  - Attempted various explicit navigation calls (`context.go`, `WidgetsBinding`) in `_unlinkProvider` to fix redirect, eventually removing them to match the working linking flow.
- **Status:** Completed. Router refactored. Deletion SnackBar context fixed. Dialog simplified. Build context warnings fixed. **Linking `GlobalKey` error resolved.** **Unlinking `GlobalKey` error persisted.** **Unlinking redirect remained incorrect.**

### Objective: Fix Auth Flow Analysis Errors & BuildContext Warnings

- **Context:** Address remaining analysis errors (`unused_element`, `unused_local_variable`) and `use_build_context_synchronously` warnings identified after previous fixes. Refactor `linkGoogleToAnonymous` merge logic.
- **Actions:**
  - Removed dead code in `auth_service.dart`.
  - Refactored `linkGoogleToAnonymous` in `AuthService` to remove `BuildContext` and throw `AuthException` with details for merge conflicts.
  - Updated `register_page.dart` and `login_page.dart` to catch the `merge-required` exception and handle the merge dialog/data migration logic.
  - Corrected `use_build_context_synchronously` warnings in `register_page.dart` and `account_settings_page.dart` by capturing `BuildContext` before `await` and using the captured context within appropriate `mounted` checks after `await`.
- **Status:** Completed.

### Objective: Fix Google Authentication Issues & Related Errors

- **Context:** Address `ref` disposal error, `GlobalKey` error, and silent redirect issues during Google Sign-In and registration flows.
- **Actions:** Refactored `GoogleSignInButton`, simplified `_signInWithGoogle`, added `ref.listen` in `AuthPage`, corrected `SnackBarHelper` usage, fixed `StyledButton` issues, adjusted router logic, added provider invalidation, moved `ref` access before `await` in `AuthPage`, isolated auth routes, fixed registration redirect.
- **Status:** `ref` disposal error resolved. Registration redirect fixed. `GlobalKey` error persisted.

### Objective: Plan Implementation for Multiple Copies of Same Card Handling (Phase 2, Task 5)

#### Context (Details)

- Completed Phase 1, Task 4: Finished Favorite/Wishlist Features (UI Implementation).
- Completed the separation of state management for Cards and Collection pages.
- **Completed fixing analysis errors and refactoring providers.**
- The next major task identified in `projectRoadmap.md` is Phase 2, Task 5: Handle multiple copies of the same card, implementing **Solution C (Subcollection per Card)**.

#### Next Steps for Phase 2, Task 5

1. **Analyze Solution C:** Review the implications of using a subcollection (`/users/{userId}/collection/{cardId}/copies/{copyId}`) for each individual copy of a card. Consider data structure, Firestore rules, and impact on existing collection logic (add/update/delete, count).
2. **Plan Data Model Changes:** Define the data model for an individual card copy document within the subcollection (e.g., fields for condition, purchase info, grading info, foil status).
3. **Plan Repository Changes:** Outline modifications needed in `CollectionRepository` to:
    - Add/update/delete individual copy documents in the subcollection.
    - Query the subcollection to get details for a specific card ID.
    - Potentially aggregate data from the subcollection (e.g., total quantity, unique conditions).
4. **Plan Firestore Rules:** Design Firestore rules to secure the new `/copies/` subcollection, ensuring users can only manage their own copies.
5. **Plan UI/Provider Impact:** Assess how this change affects existing UI components (`CollectionPage`, `CollectionEditPage`, `CollectionItemDetailPage`) and providers (`UserCollectionNotifier`, `collectionStatsProvider`). Will the main `/collection/{cardId}` document still exist? If so, what data will it hold (e.g., just the `cardId` and maybe aggregated counts)? How will the UI display and manage individual copies?
6. **Outline Migration Strategy (if needed):** Determine if existing collection data needs to be migrated to the new subcollection structure.

### Objective: Fix Analysis Errors & Provider Refactoring

- **Context:** Addressed various analysis errors reported by the Dart analyzer, including unused imports, deprecated API usage (`listenSelf`), invalid member access (`.state`), and unused local variables.
- **Action:**
  - Removed unused imports.
  - Fixed `use_super_parameters` warnings.
  - Refactored `cardSearchQueryProvider`, `collectionSpecificFilterProvider`, and `collectionSearchQueryProvider` from `StateProvider` to `NotifierProvider` to correctly handle state persistence and resolve `listenSelf` deprecation warnings.
  - Updated UI components (`cards_page.dart`, `card_app_bar_actions.dart`, `card_search_bar.dart`, `collection_edit_page.dart`, `collection_page.dart`, `collection_filter_bar.dart`, `collection_filter_dialog.dart`) to use the appropriate methods (`setQuery`, `clearFilters`, `setFilter`, `removeFilter`) on the refactored notifiers instead of accessing `.state` directly.
  - Removed unused local variables introduced during refactoring.
- **Status:** Completed.

### Objective: Finish Favorite/Wishlist Features (UI Implementation) (Phase 1, Task 4)

- **Context:** Implement UI elements for Favorite/Wishlist features.
- **Action:**
  - Added favorite/wishlist icons and toggle actions to `CardGridItem`, `CardListItem`, and `CardDetailsPage`.
  - Added "Status" filter section to `FilterDialog` and `CollectionFilterDialog`.
  - Updated `CardFilters` model with `showFavoritesOnly` and `showWishlistOnly` flags.
  - Updated `CardsNotifier` and `filteredCollectionProvider` to apply status filters.
- **Status:** Completed. (Note: Persistence for favorite/wishlist state is not yet implemented).

### Objective: Implement Independent Screen States for Cards and Collection Pages

- **Context:** Separated state management for filters, search, and view preferences between Cards and Collection pages.
- **Action:** Duplicated and refactored providers, updated persistence keys/logic, updated UI references, ran build runner.
- **Status:** Completed. (Note: Persistence for some duplicated providers needs full implementation).

### Objective: Fix Card Details Page Flicker/Lag (Phase 1, Task 2)

- **Status:** Completed (Per user instruction).

### Objective: Fix App Check Token Issue (Phase 1, Task 1)

- **Status:** Completed (User Handled/Deferred).

### Objective: Fix `setState` Error in AccountSettingsPage

- **Status:** Fix applied.
