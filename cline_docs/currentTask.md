# Current Task

## Current Objective: Test Authentication Flows

### Context

- Recent work focused on resolving various analysis errors (`unused_element`, `unused_local_variable`, `use_build_context_synchronously`, dead code) across several files (`app_router.dart`, `register_page.dart`, `account_settings_page.dart`, `auth_service.dart`).
- Specific attention was given to fixing `use_build_context_synchronously` warnings by ensuring `BuildContext` is handled correctly across `await` gaps, primarily using the context-capturing pattern with `mounted` checks.
- A `ref` access issue after `await` in `auth_page.dart` was also resolved.
- The `linkGoogleToAnonymous` flow was refactored to handle merge conflicts in the UI layer (`register_page.dart`, `login_page.dart`).

### Status

- **Analysis Errors:** Resolved in relevant files.
- **`use_build_context_synchronously`:** Warnings addressed using context capturing and `mounted` checks.
- **`ref` Disposal Error:** Believed to be resolved in `auth_page.dart`.
- **Merge Conflict Logic:** Refactored to UI layer in `register_page.dart` and `login_page.dart`.
- **`GlobalKey` Error:** Still potentially persists (related to `ShellRoute`). Needs verification during testing.

### Next Steps

1. **Comprehensive Testing:** Execute the detailed test plan for all authentication flows to ensure recent fixes are effective and no regressions were introduced. Pay close attention to edge cases and transitions involving anonymous users.
2. **Verify `GlobalKey` Error:** Specifically test scenarios involving authentication state changes (sign-in, sign-out, linking, deletion) to see if the `Duplicate GlobalKey detected... [GlobalKey#... scaffoldWithNavBar]` error still occurs.
3. **Address `GlobalKey` Error (If Persists):** If the error remains, investigate GoRouter `ShellRoute` behavior during redirects or consider alternative structuring as previously planned.

## Previous Objectives (Completed)

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
- **Status:** `ref` disposal error resolved. Registration redirect fixed. `GlobalKey` error persists.

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
