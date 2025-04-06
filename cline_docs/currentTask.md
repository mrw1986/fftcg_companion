# Current Task

## Current Objective: Fix Google Authentication Issues

### Context

- When users attempted to sign in with Google but the account didn't exist, they were being silently redirected back to the sign-in page without any notification.
- Logs revealed successful authentication with Firebase but issues in the app's state management during the auth flow.

### Actions Taken

1. **Refactored `GoogleSignInButton`:** Removed internal loading state (`setState`) to prevent errors when the parent page (`AuthPage`) was disposed during the async sign-in operation. Passed loading state down from `AuthPage`. Corrected deprecated `withOpacity` usage to `withValues`.
2. **Simplified `_signInWithGoogle`:** Removed all post-`await` logic (reloads, delays, state checks, snackbars, explicit navigation) to prevent operations on a potentially disposed widget context/ref. Focused on triggering the core auth operation and resetting flags.
3. **Implemented `ref.listen` in `AuthPage`:** Added a listener to `authStateProvider` within `AuthPage`'s `initState` to specifically handle the transition from non-authenticated to authenticated *after* a Google sign-in initiated from that page. This listener now handles showing the success snackbar and navigating to `/profile/account`.
4. **Corrected `SnackBarHelper` Usage:** Fixed incorrect method calls in `AuthPage` (replaced hallucinated `buildThemedSnackBar` with correct methods).
5. **Corrected `StyledButton` Deprecations & Nullability:** Updated `StyledButton` to use `withValues` instead of `withOpacity` and accept a nullable `onPressed`. Fixed type mismatch in `AuthPage` button usage.
6. **Router Adjustments:** Modified `app_router.dart` to use `ref.watch` for reactive redirects and removed the potentially conflicting `refreshListenable`.
7. **Provider Invalidation:** Added provider invalidation (`firebaseUserProvider`, `authStateProvider`, `currentUserProvider`) after successful Google sign-in/linking in `AuthPage` to ensure the reactive chain updates correctly, similar to the working `RegisterPage` flow.
8. **Refined `_signInWithGoogle` Error/Flag Handling:** Ensured `skipAutoAuthProvider` flag is reset reliably in `try`/`catch`/`finally` blocks, checking `mounted` status before accessing `ref`.
9. **Added Extra `mounted` Check in `AuthPage`:** Added an additional `mounted` check immediately before the `ref.read` call within the `finally` block of `_signInWithGoogle`. (Note: This was insufficient).
10. **Simplified Router Page Building:** Changed `pageBuilder:` to `builder:` for profile sub-routes. (Note: Did not resolve GlobalKey issue).
11. **Added GlobalKey to `ScaffoldWithNavBar`:** Added a persistent key to the shell scaffold. (Note: Did not resolve GlobalKey issue).
12. **Temporarily Removed `LoadingWrapper`:** Removed wrapper from `app.dart` for diagnosis. (Note: Did not resolve GlobalKey issue).
13. **Refactored `_signInWithGoogle` Ref Access:** Moved all `ref` interactions before the `await` call in `AuthPage`. (Note: This appears to have fixed the `ref` disposal error).
14. **Isolated Auth Routes:** Moved `/auth`, `/register`, `/reset-password` outside the `ShellRoute` in `app_router.dart`.
15. **Fixed Registration Redirect:** Added explicit `context.go('/profile/account')` after dialog dismissal in `RegisterPage`.
16. **Restored `LoadingWrapper`:** Added the wrapper back in `app.dart`.

### Status

- **`ref` Disposal Error:** Appears **resolved** by refactoring `_signInWithGoogle` in `AuthPage`.
- **Registration Redirect:** Explicit navigation added in `RegisterPage` to ensure correct redirection after email/password registration.
- **`GlobalKey` Error:** **Persists** even after isolating auth routes. The error `Duplicate GlobalKey detected... [GlobalKey#5f22b scaffoldWithNavBar]` indicates the issue still relates to the `ShellRoute` or `ScaffoldWithNavBar` during auth state transitions.
- **Next Steps:**
  - **Investigate `ShellRoute` Further:** Research GoRouter issues related to `ShellRoute` rebuilds during redirects triggered by external state changes (like `authStateProvider`). Look for potential workarounds or alternative structuring.
  - **Consider Router Alternatives (If Necessary):** If the `ShellRoute` issue proves intractable, explore alternative navigation packages or patterns.
  - **Test Other Flows:** Verify if isolating auth routes impacted sign-out or account deletion flows regarding the `GlobalKey` error.

## Previous Objectives (Completed)

### Objective: Plan Implementation for Multiple Copies of Same Card Handling (Phase 2, Task 5)

#### Context (Details)

- Completed Phase 1, Task 4: Finished Favorite/Wishlist Features (UI Implementation).
- Completed the separation of state management for Cards and Collection pages.
- **Completed fixing analysis errors and refactoring providers.**
- The next major task identified in `projectRoadmap.md` is Phase 2, Task 5: Handle multiple copies of the same card, implementing **Solution C (Subcollection per Card)**.

#### Next Steps

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
