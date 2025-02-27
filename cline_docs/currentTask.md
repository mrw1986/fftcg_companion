# Current Task

## Objective

Fix UI issues with splash screen and card display on foldable phones

## Context

The app had the following UI issues:

1. The splash screen was displaying the logo inside a circular container, which was not desired
2. On foldable phones, card images were not fully visible due to aspect ratio issues

## Implementation Plan

### 1. Fix Splash Screen Logo Display

Location: pubspec.yaml

Current Issue:

- The splash screen was displaying the logo inside a circular container
- This was not the intended design for the app

Solution:

- Updated the flutter_native_splash configuration in pubspec.yaml
- Added android_gravity and ios_content_mode parameters set to "center"
- Added fullscreen: false to ensure proper display
- Added support for dark mode with image_dark and color_dark parameters

Impact:

- The splash screen now displays the logo without a circular container
- The logo appears properly centered on both Android and iOS devices
- The splash screen maintains consistency with the app's design language

### 2. Fix Card Image Display on Foldable Phones

Location: lib/features/cards/presentation/pages/card_details_page.dart

Current Issue:

- On foldable phones, card images were not fully visible due to aspect ratio issues
- The fixed aspect ratio (223/311) combined with the screen dimensions caused parts of the card to be cut off
- The BoxFit.cover setting was causing the image to be cropped on certain screen sizes
- The card was overlapping with the status bar at the top of the screen
- In dark mode, white corners were visible around the card image, breaking the rounded corner effect

Solution:

- Modified the card details page to calculate appropriate card dimensions based on screen size
- Changed BoxFit from "cover" to "contain" to ensure the entire card is visible
- Implemented responsive sizing that adapts to different screen dimensions
- Added constraints to ensure the card is properly displayed on all devices, including foldables
- Used percentages of screen height/width rather than fixed dimensions
- Added padding to move the card down from the status bar
- Implemented proper card styling with ClipRRect and Card widgets to ensure corners match the background color in dark mode
- Used the same approach as in card_grid_item.dart for consistent styling across the app

Files Modified:

- lib/features/cards/presentation/pages/card_details_page.dart

Impact:

- Card images are now fully visible on all devices, including foldable phones
- The entire card content is displayed without cropping
- The UI adapts to different screen sizes and aspect ratios
- Improved user experience on devices with unusual aspect ratios
- Cards no longer overlap with the status bar
- Card corners appear properly rounded in both light and dark mode
- Consistent styling across the app

## Testing Strategy

1. Splash Screen Testing
   - Launch the app on different devices
   - Verify that the logo appears without a circular container
   - Check that the logo is properly centered
   - Ensure the splash screen transitions smoothly to the main app

2. Card Display Testing
   - Open a card detail view on different devices, especially foldable phones
   - Verify that the entire card is visible without cropping
   - Check that the card maintains its proper aspect ratio
   - Ensure the card is displayed at an appropriate size for the screen
   - Verify that the card doesn't overlap with the status bar
   - Check that card corners appear properly rounded in both light and dark mode

## Success Criteria

- The splash screen displays the logo without a circular container
- Card images are fully visible on all devices, including foldable phones
- The UI adapts properly to different screen sizes and aspect ratios
- No visual artifacts or distortions in the card display
- Cards don't overlap with the status bar
- Card corners appear properly rounded in both light and dark mode

## Next Steps

1. Consider implementing similar responsive sizing for other image displays in the app
2. Explore further UI optimizations for unusual screen sizes
3. Add comprehensive device testing to ensure consistent experience across all form factors
4. Consider adding analytics to track user device types and screen sizes
