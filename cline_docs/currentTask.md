# Current Task

## Objective

Fix UI issues in the card details page and card description text

## Context

The app had the following issues:

1. In the card description text, the Meteorain special ability wasn't being properly stylized with the orange color and bold formatting
2. In the card flipping animation, when an image is loading from the placeholder, both the card flipping and fading in were occurring, when it should only flip in and NOT fade in

## Implementation Plan

### 1. Fix Special Ability Styling in Card Description Text

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

### 2. Attempted Fixes for Card Flipping Animation

Location:

- lib/core/widgets/flipping_card_image.dart
- lib/core/widgets/cached_card_image.dart
- lib/features/cards/presentation/pages/card_details_page.dart

Current Issue:

- During the card flipping animation, both flipping and fading effects were occurring
- The card corners weren't displaying correctly with the border radius

Attempted Solutions:

1. Modified the CachedCardImage widget:
   - Set fadeInDuration and fadeOutDuration to const Duration(milliseconds: 0)
   - Added placeholderFadeInDuration to remove placeholder fade-in
   - Used linear curves for fade effects

2. Updated the FlippingCardImage widget:
   - Added clipBehavior: Clip.antiAlias to the ClipRRect widgets
   - Ensured consistent border radius application

3. Simplified the card_details_page.dart:
   - Removed nested Card and ClipRRect widgets
   - Used a single ClipRRect with consistent border radius

Current Status:

- The special ability styling issue has been fixed
- The card corner rounding issue still persists and requires further investigation

## Testing Strategy

1. Special Ability Styling Test
   - View cards with different special abilities (e.g., Meteorain, Omnislash)
   - Verify that all special abilities are properly stylized with orange color
   - Check that the formatting is consistent regardless of spacing in the text

2. Card Animation Test
   - Navigate between different cards to trigger the flipping animation
   - Observe the card corners during the animation
   - Verify that the animation is smooth and the card corners are properly rounded

## Success Criteria

- All special abilities in card descriptions are properly stylized
- Card flipping animation works correctly without unwanted fading effects
- Card corners display with proper border radius during and after animations

## Next Steps

1. Further investigate the card corner rounding issue
   - Consider a complete redesign of the card animation system
   - Explore alternative approaches to applying border radius during animations
   - Test different ClipRRect configurations and nesting structures

2. Improve image loading performance
   - Optimize image caching for faster loading
   - Reduce animation overhead for smoother transitions

3. Enhance error handling for image loading
   - Provide better fallback mechanisms
   - Improve error reporting and recovery
