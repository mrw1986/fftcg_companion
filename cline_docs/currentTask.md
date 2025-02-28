# Current Task

## Objective

Fix set filter groups and card count display issues

## Context

The set filter groups in the app had the following issues:

1. When filtering by a set and adjusting other filters, only the selected set had its card count updated while all other sets showed 0
2. This created a confusing user experience when trying to filter by multiple criteria

## Implementation Plan

### 1. Fix Card Count Calculation for Set Filters

Location: lib/features/cards/presentation/providers/set_card_count_provider.dart

Current Issue:

- When a set was selected and other filters were applied, only the selected set's card count was updated
- All other sets showed 0 cards, even though they should have shown their counts with the other filters applied
- The cache key generation didn't properly handle set filtering

Solution:

- Modified the `_getCacheKey` method to exclude selected sets from the cache key
- Updated the `FilteredSetCardCount` provider to use a modified filter without the set filter
- This ensures that set counts are calculated independently of which sets are selected
- Applied the same approach to `_updateCacheAsync` and `preloadAllSetCounts` methods for consistency

Files Modified:

- lib/features/cards/presentation/providers/set_card_count_provider.dart

Impact:

- Card counts for all sets now update correctly when applying other filters
- Users can see accurate card counts for all sets regardless of which sets are selected
- The filter dialog provides a more intuitive and consistent experience

## Testing Strategy

1. Set Filtering Test
   - Open the filter dialog
   - Select a set (e.g., "Opus I")
   - Apply another filter (e.g., select an element like "Fire")
   - Verify that all sets show their correct card counts with the element filter applied
   - Reset the filters and verify all counts return to their original values

2. Multiple Filter Test
   - Apply multiple filters (elements, types, rarities)
   - Select and deselect various sets
   - Verify that all set counts update correctly with the applied filters

## Success Criteria

- When a set is selected and other filters are applied, all sets show their correct card counts
- Card counts update properly when any filter is applied or removed
- The filter dialog provides a consistent and intuitive experience

## Next Steps

1. Consider implementing similar filtering improvements for other filter categories
2. Add analytics to track filter usage patterns
3. Explore further optimizations for the filter dialog
4. Consider adding a "Select All" option for each filter category
