# Current Task

## Objective

Fix set filter groups and optimize filter dialog performance

## Context

The set filter groups in the app had the following issues:

1. Core sets that don't have "deck" or "collection" in their names were not being properly categorized as Opus sets
2. When selecting a set, all card counts briefly showed loading state ("...") before showing the actual counts
3. The filter dialog was making too many Firestore reads, which could increase operational expenses

## Implementation Plan

### 1. Update Set Categorization Logic

Location: lib/features/cards/presentation/providers/filter_options_provider.dart

Current Issue:

- Core sets like "Crystal Dominion", "Beyond Destiny", etc. were not being properly categorized as Opus sets
- These sets were missing from the Opus Sets section in the filter dialog

Solution:

- Updated the _categorizeSet method to properly identify core sets
- Added explicit checks for known core set names
- Ensured all core sets that don't have "deck" or "collection" in their names are categorized as Opus sets

Impact:

- All core sets are now correctly displayed in the Opus Sets section
- The filter dialog now shows a complete list of sets in their appropriate categories

### 2. Implement Persistent Caching for Set Card Counts

Location: lib/features/cards/presentation/providers/set_card_count_provider.dart

Current Issue:

- Set card counts were being recalculated on every app launch
- This resulted in unnecessary Firestore reads and slower filter dialog loading

Solution:

- Created a SetCardCountsCache class for persistent storage of set card counts
- Implemented methods to store and retrieve counts from Hive storage
- Modified the FilteredSetCardCountCache provider to use the persistent cache

Impact:

- Reduced Firestore reads by caching set card counts
- Improved filter dialog loading performance
- Lower operational costs due to fewer Firestore queries

### 3. Prevent Card Count Flickering During Set Selection

Location: Multiple files (see below)

Current Issue:

- When selecting a set, all card counts briefly showed loading state ("...")
- This created a flickering effect that was visually distracting
- Card counts shouldn't change just because a set is being selected

Solution:

- Created a StatefulWidget (SetCardCountDisplay) to maintain card counts during set selection
- Added a flag in the filter provider to track when a set is being toggled
- Modified the FilteredSetCardCountCache provider to maintain previous values while loading new ones
- Implemented asynchronous cache updates to avoid UI flickering

Files Modified:

- lib/features/cards/presentation/widgets/filter_dialog.dart
- lib/features/cards/presentation/providers/filter_provider.dart
- lib/features/cards/presentation/providers/set_card_count_provider.dart

Impact:

- Card counts remain stable when selecting sets
- No more flickering in the filter dialog
- Improved user experience with smoother UI interactions

### 4. Optimize Filter Dialog Loading

Location: lib/features/cards/presentation/widgets/filter_dialog.dart

Current Issue:

- The filter dialog was slow to open, especially on first launch
- All set card counts were being loaded sequentially

Solution:

- Added a prefetch mechanism to load filter options and some set counts before showing the dialog
- Implemented optimistic UI updates with placeholder counts while loading actual data
- Modified the filter dialog to show immediately with cached data

Impact:

- Filter dialog opens faster, especially on subsequent launches
- Better user experience with more responsive UI
- Reduced perceived loading time
- Alphabetical sorting is consistent and intuitive

## Testing Strategy

1. Set Categorization Testing
   - Open the filter dialog
   - Verify that core sets like "Crystal Dominion", "Beyond Destiny", etc. appear in the Opus Sets section
   - Check that all sets are properly categorized

2. Card Count Stability Testing
   - Open the filter dialog
   - Select and deselect various sets
   - Verify that card counts remain stable and don't flicker during selection

3. Performance Testing
   - Clear the app cache
   - Launch the app and open the filter dialog
   - Measure the time it takes to load
   - Open the filter dialog again and verify it loads faster

4. Caching Effectiveness Testing
   - Launch the app and open the filter dialog
   - Check the logs for Firestore read operations
   - Verify that subsequent opens use cached data instead of making new Firestore queries

## Success Criteria

- All core sets are correctly displayed in the Opus Sets section
- Card counts remain stable when selecting sets (no flickering)
- The filter dialog opens quickly, especially on subsequent launches
- Reduced Firestore reads for set card counts
- Smooth and responsive UI during filter interactions

## Next Steps

1. Consider implementing a more sophisticated caching strategy for other parts of the app
2. Explore further optimizations for the filter dialog
3. Add analytics to track filter usage patterns
4. Implement similar caching and UI stability improvements for other dialogs
