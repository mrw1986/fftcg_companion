# Current Task

## Objective

Implement an animated search bar in the app bar

## Context

The app had the following issues:

1. In the card description text, the Meteorain special ability wasn't being properly stylized with the orange color and bold formatting
2. In the card flipping animation, when an image is loading from the placeholder, both the card flipping and fading in were occurring, when it should only flip in and NOT fade in
3. The search bar implementation was not animated and would replace the title text when activated

## Implementation Plan

### 1. Fix Special Ability Styling in Card Description Text (Completed)

Location: lib/features/cards/presentation/widgets/card_description_text.dart

Current Issue:

- The regex pattern for detecting special abilities without HTML tags was not matching "Meteorain" because it was expecting a space between the ability name and the [S] tag
- Only the Omnislash special ability was being properly stylized

Solution:

- Updated the regex pattern from `(\w+)\s*\[S\]` to `(\w+)(\s*)\[S\]` to capture any whitespace between the ability name and [S] tag
- Modified the text processing to handle the case where there's no space between the ability name and the [S] tag
- Changed from using HtmlParser to direct TextSpan for ability name styling to ensure consistent formatting

Files Modified:

- lib/features/cards/presentation/widgets/card_description_text.dart

Impact:

- All special abilities (including Meteorain) now display with the correct orange styling
- Consistent formatting for all special abilities regardless of spacing in the text

### 2. Fix Card Corner Rounding Issue (Completed)

Location:

- lib/features/cards/presentation/pages/card_details_page.dart
- lib/core/widgets/corner_mask_painter.dart

Current Issue:

- The card images had white corners that were visible against the dark background in dark mode
- The corners needed to be transparent to match the background color

Solution:

- Created a new approach using a Container with BoxDecoration and DecorationImage
- Set a larger border radius (16.0) to ensure the corners were properly rounded
- Removed the Hero animation for the card image to prevent issues with the transition
- This approach ensures the corners are properly masked and match the background color

### 3. Implement Animated Search Bar (Completed)

Location:

- lib/features/cards/presentation/widgets/card_search_bar.dart
- lib/features/cards/presentation/widgets/card_app_bar_actions.dart
- lib/features/cards/presentation/pages/cards_page.dart

Current Issue:

- The search bar would replace the title text when activated without animation
- Other app bar actions would disappear instantly when search was activated
- The cards would disappear during search if no query was entered

Solution:

1. Updated CardSearchBar:
   - Converted from ConsumerWidget to ConsumerStatefulWidget to manage animation state
   - Added animations for width expansion, opacity, and title fading
   - Implemented a stack layout to overlay the search field on the title
   - Created smooth transitions for expanding/collapsing the search field

2. Updated CardAppBarActions:
   - Converted from ConsumerWidget to ConsumerStatefulWidget to manage animation state
   - Added fade animations for the filter, view type, and size toggle buttons
   - Implemented animated icon switching between search and close icons
   - Disabled button functionality during animation transitions

3. Updated CardsPage:
   - Added animation controller for the floating action button
   - Refactored search toggle logic to handle animations properly
   - Modified card content display logic to keep cards visible during search
   - Centralized search toggle functionality to ensure consistent behavior

Files Modified:

- lib/features/cards/presentation/widgets/card_search_bar.dart
- lib/features/cards/presentation/widgets/card_app_bar_actions.dart
- lib/features/cards/presentation/pages/cards_page.dart

Impact:

- Search bar now animates smoothly, expanding from right to left
- Title text fades out as search bar expands
- Other app bar actions fade out gradually when search is activated
- Cards remain visible during search, even when no query is entered
- Floating action button scales and fades during search transitions
- Overall improved user experience with smooth animations

## Current Status

- The special ability styling issue has been fixed
- The card corner rounding issue has been fixed
- The animated search bar has been implemented

## Testing Strategy

1. Special Ability Styling Test
   - View cards with different special abilities (e.g., Meteorain, Omnislash)
   - Verify that all special abilities are properly stylized with orange color
   - Check that the formatting is consistent regardless of spacing in the text

2. Card Corner Rounding Test
   - View cards in dark mode to check for white corners
   - Verify that the card corners are properly rounded and match the background color
   - Test different cards to ensure consistency

3. Animated Search Bar Test
   - Test search activation by clicking the search icon
   - Verify smooth animation of the search bar expanding
   - Check that the title text fades out properly
   - Confirm other app bar actions fade out gradually
   - Verify cards remain visible during search
   - Test search deactivation by clicking the close icon
   - Check that all elements return to their original state
   - Test on different screen sizes to ensure responsive behavior

## Success Criteria

- All special abilities in card descriptions are properly stylized
- Card corners display with proper border radius and match the background color
- Search bar animates smoothly when activated/deactivated
- Cards remain visible during search operations
- All animations are smooth and enhance the user experience

## Next Steps

1. Improve image loading performance
   - Optimize image caching for faster loading
   - Reduce animation overhead for smoother transitions
   - Implement progressive image loading techniques

2. Enhance error handling for image loading
   - Provide better fallback mechanisms
   - Improve error reporting and recovery
   - Add retry functionality for failed image loads
