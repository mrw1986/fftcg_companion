# Current Task

## Objective

Fix search functionality issues in the app

## Context

The search functionality in the app was not working correctly:

1. When typing a search term and then modifying it (e.g., typing "s", then "se", then back to "s"), the search results were not updating properly
2. The search results were not being sorted correctly, particularly for single-letter searches
3. The caching mechanism was causing stale results to be displayed

## Implementation Plan

### 1. Rewrite CardSearchNotifier for Better State Management

Location: lib/features/cards/presentation/providers/cards_provider.dart

Current Issue:

- The debouncing and caching mechanisms were interfering with each other
- State was not being properly updated when the search query changed
- Progressive searches were not working correctly

Solution:

- Completely rewrote the CardSearchNotifier class
- Simplified the search implementation
- Added code to clear the search cache when the query changes
- Maintained a minimal debounce timer to prevent excessive searches during typing

Impact:

- Search results now update correctly when the search query changes
- The UI is more responsive during typing
- No more stale results from previous searches

### 2. Add clearSearchCache Method to CardCache

Location: lib/core/storage/card_cache.dart

Current Issue:

- There was no way to clear the search cache when needed
- This was causing stale results to be displayed

Solution:

- Added a clearSearchCache method to the CardCache class
- This method clears both memory and disk search caches
- Called this method when the search query changes

Impact:

- Each search query now gets fresh results
- The search cache is properly cleared when needed
- No more stale results from previous searches

### 3. Improve Sorting Logic for Search Results

Location: lib/features/cards/data/repositories/card_repository.dart

Current Issue:

- When searching for "s", SOLDIER was appearing before Sabin
- The sorting logic wasn't properly prioritizing alphabetical order for cards with the same relevance score

Solution:

- Modified the relevance calculation and sorting logic
- Improved the sorting logic to properly handle alphabetical sorting for cards with the same relevance score
- Enhanced the name comparison logic for single-letter searches

Impact:

- Search results are now sorted correctly
- For single-letter searches, cards are sorted alphabetically
- The search results are more intuitive and consistent

### 4. Fix Name Sorting in Descending Order

Location: lib/features/cards/data/repositories/card_repository.dart and lib/features/cards/domain/models/card.dart

Current Issue:

- When sorting cards by name in descending order, "Leslie" appeared as the first card (alphabetically last)
- Simply inverting the comparison result for descending order didn't work correctly for alphabetical sorting
- The `compareByName` method in the Card model wasn't consistently using lowercase comparison

Solution:

- Added special handling for name sorting in descending order in the repository
- Implemented direct name comparison in reverse order instead of just inverting the comparison result
- Modified the `compareByName` method in the Card model to use lowercase comparison
- Ensured consistent case handling in both the repository and the Card model

Impact:

- Cards are now properly sorted by name in both ascending and descending order
- Alphabetical sorting is consistent and intuitive
- Case-insensitive sorting ensures proper alphabetical order regardless of capitalization

### 5. Scroll to Top When Applying Sort

Location: Multiple files (see below)

Current Issue:

- When applying a sort, the list remained at the current scroll position
- This was confusing for users as they couldn't see the beginning of the sorted list
- Users had to manually scroll back to the top to see the new sort order

Solution:

- Created a new provider (`cardContentKeyProvider`) to access the `CardContent` widget's state from anywhere
- Added a `scrollToTop` method to the `CardContentState` class
- Added an extension method on `WidgetRef` to easily scroll to the top
- Modified the `SortBottomSheet` to scroll to the top after applying a sort

Files Modified:

- lib/features/cards/presentation/widgets/card_content.dart
- lib/features/cards/presentation/pages/cards_page.dart
- lib/features/cards/presentation/widgets/sort_bottom_sheet.dart
- lib/features/cards/presentation/providers/card_content_provider.dart (new file)

Impact:

- When a sort is applied, the list automatically scrolls to the top
- Users can immediately see the beginning of the sorted list
- Improved user experience with more intuitive behavior
- Alphabetical sorting is consistent and intuitive

## Testing Strategy

1. Progressive Search Testing
   - Type a search term (e.g., "s")
   - Modify the search term (e.g., "se")
   - Go back to the original search term (e.g., "s")
   - Verify that the search results update correctly

2. Sorting Testing
   - Search for a single letter (e.g., "s")
   - Verify that the results are sorted alphabetically
   - Check that cards starting with that letter appear before cards containing that letter

3. Cache Invalidation Testing
   - Perform multiple searches
   - Verify that each search gets fresh results
   - Check that there are no stale results from previous searches

## Success Criteria

- Search results update correctly when the search query changes
- Search results are sorted correctly, particularly for single-letter searches
- No stale results from previous searches
- The UI is responsive during typing
- The search functionality works as expected for all search patterns

## Next Steps

1. Consider implementing a more sophisticated relevance calculation for search results
2. Explore further optimizations for the search process
3. Add analytics to track search performance and usage
4. Implement more comprehensive testing for the search functionality
