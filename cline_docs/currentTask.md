# Current Task

## Completed Task: Analysis Errors & Provider Refactoring

- **Context:** Addressed various analysis errors reported by the Dart analyzer, including unused imports, deprecated API usage (`listenSelf`), invalid member access (`.state`), and unused local variables.
- **Action:**
  - Removed unused imports.
  - Fixed `use_super_parameters` warnings.
  - Refactored `cardSearchQueryProvider`, `collectionSpecificFilterProvider`, and `collectionSearchQueryProvider` from `StateProvider` to `NotifierProvider` to correctly handle state persistence and resolve `listenSelf` deprecation warnings.
  - Updated UI components (`cards_page.dart`, `card_app_bar_actions.dart`, `card_search_bar.dart`, `collection_edit_page.dart`, `collection_page.dart`, `collection_filter_bar.dart`, `collection_filter_dialog.dart`) to use the appropriate methods (`setQuery`, `clearFilters`, `setFilter`, `removeFilter`) on the refactored notifiers instead of accessing `.state` directly.
  - Removed unused local variables introduced during refactoring.
- **Status:** Completed.

## Current Objective: Plan Implementation for Multiple Copies of Same Card Handling (Phase 2, Task 5)

### Context

- Completed Phase 1, Task 4: Finished Favorite/Wishlist Features (UI Implementation).
- Completed the separation of state management for Cards and Collection pages.
- **Completed fixing analysis errors and refactoring providers.**
- The next major task identified in `projectRoadmap.md` is Phase 2, Task 5: Handle multiple copies of the same card, implementing **Solution C (Subcollection per Card)**.

### Next Steps

1. **Analyze Solution C:** Review the implications of using a subcollection (`/users/{userId}/collection/{cardId}/copies/{copyId}`) for each individual copy of a card. Consider data structure, Firestore rules, and impact on existing collection logic (add/update/delete, count).
2. **Plan Data Model Changes:** Define the data model for an individual card copy document within the subcollection (e.g., fields for condition, purchase info, grading info, foil status).
3. **Plan Repository Changes:** Outline modifications needed in `CollectionRepository` to:
    - Add/update/delete individual copy documents in the subcollection.
    - Query the subcollection to get details for a specific card ID.
    - Potentially aggregate data from the subcollection (e.g., total quantity, unique conditions).
4. **Plan Firestore Rules:** Design Firestore rules to secure the new `/copies/` subcollection, ensuring users can only manage their own copies.
5. **Plan UI/Provider Impact:** Assess how this change affects existing UI components (`CollectionPage`, `CollectionEditPage`, `CollectionItemDetailPage`) and providers (`UserCollectionNotifier`, `collectionStatsProvider`). Will the main `/collection/{cardId}` document still exist? If so, what data will it hold (e.g., just the `cardId` and maybe aggregated counts)? How will the UI display and manage individual copies?
6. **Outline Migration Strategy (if needed):** Determine if existing collection data needs to be migrated to the new subcollection structure.

## Previous Objectives (Completed)

### Objective: Plan Implementation for Multiple Copies of Same Card Handling (Phase 2, Task 5)

- **Context:** Completed Phase 1, Task 4 and state separation. Next task is Phase 2, Task 5.
- **Action:** Outlined planning steps for Solution C (Subcollection per Card).
- **Status:** Planning initiated (superseded by error fixing, now resuming).

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
