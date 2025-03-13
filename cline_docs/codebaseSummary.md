# Codebase Summary

## Key Components and Their Interactions

### Core Components

1. **App Structure**
   - Flutter application with a modular architecture
   - Uses Riverpod for state management
   - Implements Go Router for navigation

2. **Theme System**
   - Supports both light and dark modes
   - Custom theme extensions for consistent styling
   - Theme provider for dynamic theme switching
   - Custom theme color selection with color picker
   - Predefined color schemes from FlexColorScheme
   - Contrast extension for ensuring text readability
   - Persistent theme settings using Hive storage

3. **Storage Layer**
   - Hive for local storage and caching with memory cache fallback
   - Card cache for efficient data access
   - Cache persistence for offline functionality
   - Resilient storage operations with error recovery

4. **Networking**
   - Firestore service for cloud data
   - Cache-first strategy for improved performance
   - Error handling and retry mechanisms

5. **Authentication**
   - Firebase Authentication integration
   - Support for Google Sign-In, Email/Password, and Anonymous authentication
   - Enhanced Google Sign-In with detailed logging and emulator detection
   - Email verification tracking with isVerified field
   - Account linking for anonymous to permanent account conversion
   - Authentication state management with Riverpod
   - Interactive notifications for authentication operations
   - Re-authentication for security-sensitive operations
   - Provider unlinking for managing authentication methods
   - Account deletion with proper data cleanup

### Feature Modules

1. **Cards Feature**
   - Card data models and repositories
   - Card grid and details views
   - Advanced search with filtering and sorting
   - Card metadata display
   - Animated search interface
   - Integrated search, filter, and sort functionality
   - Action buttons for adding to collection, favorites, and wishlist
   - Card label toggle for showing/hiding card names and numbers

2. **Collection Feature**
   - User's card collection management
   - Collection statistics and tracking
   - Add/remove cards from collection
   - Card condition tracking (NM, LP, MP, HP, DMG)
   - Purchase information tracking (price, date)
   - Professional grading support (PSA, BGS, and CGC)
   - Grid and list view options with customizable sizes
   - Filtering by card type (regular, foil, graded)
   - Sorting by various criteria (last modified, card ID, quantity)
   - Search functionality within collection
   - Integrated card search when adding new cards to collection
   - Card label toggle for showing/hiding card names and numbers
   - Consistent UI with Cards feature for better user experience

3. **Decks Feature**
   - Deck building and management
   - Deck validation and statistics
   - Card recommendations

4. **Scanner Feature**
   - Card scanning functionality
   - Image recognition for cards
   - Quick add to collection

5. **Profile Feature**
   - User preferences and settings
   - User authentication and account management
   - Theme customization with color picker and mode selection
   - Login, registration, and password reset
   - Anonymous authentication with upgrade path
   - Google Sign-In integration with improved error handling
   - Email verification with interactive notifications
   - Profile management with email change functionality
   - Application settings

## Data Flow

1. **Card Data Flow**
   - Cards are fetched from Firestore
   - Cached locally using Hive
   - Displayed in grid/list views
   - Detailed view shows comprehensive card information

2. **Search Flow**
   - User activates search with animated transition
   - Search query is entered in expanding search field
   - Local cache is searched first
   - Results are filtered and displayed with smooth transitions
   - Users can apply filters to search results
   - Search results can be sorted using any sort criteria
   - All operations are performed client-side for better performance
   - Cards remain visible during search operations
   - Search history is maintained

3. **Collection Management Flow**
   - User adds/removes cards from collection
   - Collection is updated locally and in cloud
   - Statistics are recalculated
   - UI reflects changes immediately
   - Users can track card condition, purchase info, and grading
   - Collection can be filtered and sorted by various criteria
   - Users can switch between grid and list views
   - Users can search for cards to add to their collection
   - Users can add cards directly from the card details page
   - Users can toggle card labels on/off for better visibility

## External Dependencies

1. **Firebase/Firestore**
   - Used for card database
   - Firebase Authentication for user management
   - Google Sign-In integration with enhanced error handling
   - Analytics and crash reporting
   - Firestore for user collection and deck storage

2. **Image Handling**
   - Cached network image for efficient loading
   - Custom image widgets for card display
   - Progressive image loading

3. **UI Components**
   - Custom widgets for consistent UI
   - Responsive layouts for different screen sizes
   - Animations for improved UX
   - Animated transitions for search and filtering
   - FlexColorScheme for comprehensive theming
   - FlexColorPicker for theme color customization

## Recent Significant Changes

1. **Theme Picker Contrast Improvements**
   - Fixed contrast issues in the theme picker for better text readability
   - Enhanced text styling in the color picker with high-contrast white text and shadows
   - Fixed the opacityTrackHeight parameter to comply with the required range (8-50dp)
   - Improved the SwitchListTile in the profile page for better visibility in dark mode
   - Added adaptive text colors based on the current theme brightness
   - Increased font sizes for better readability
   - Enhanced the theme mode buttons with larger icons and text
   - Improved overall accessibility of the theme picker
   - Made text elements more readable on all background colors

1. **Theme Picker Enhancement**
   - Enhanced the theme picker with advanced features using flex_color_scheme and flex_color_picker
   - Added Material 3 tonal palette generation for selected colors
   - Enabled color shades selection for more precise color choices
   - Added color name display for better user understanding
   - Implemented recently used colors tracking with persistence between sessions
   - Added multiple color picker types (Primary, Accent, Black & White, and Wheel)
   - Improved the UI organization with clear section headings
   - Enhanced the predefined schemes section with visual indicators for the selected scheme
   - Added persistence for recently used colors in the theme provider

1. **Theme Settings UI Simplification**
   - Removed the custom color selector circle at the top right
   - Removed the "Predefined Schemes" text to simplify the UI
   - Kept only the color grid for theme color selection
   - Improved text contrast in the color grid by using withAlpha instead of withOpacity
   - Added proper contrast calculation for palette icons based on background color
   - Simplified the UI to focus on the essential functionality
   - Enhanced overall user experience with a more focused and user-friendly interface

1. **UI Consistency Improvements**
   - Replicated the card label toggle from the Collection page to the Card Database page with independent state for each
   - Fixed the Collection sorting query to properly handle ascending/descending sorting
   - Removed the extra divider lines between sections in both the Collection filter dialog and Card filter dialog
   - Updated the View Size button in the Collection page to dynamically change its size based on the selected size
   - Adjusted padding between UI elements for a more compact and visually appealing layout
   - Reduced the space between the appbar and Collection Stats card
   - Reduced the space between the Collection Stats card and card images using Transform.translate with negative offset
   - Fixed the filter functionality in the Collection page to properly apply both collection-specific filters and card filters
   - Improved the overall user experience with more consistent UI elements and behavior

1. **Card Details Page UI Improvements**
   - Fixed "T:" styling in card descriptions to show the dull.png image
   - Improved layout with navigation buttons and FAB
     - Moved navigation buttons outside the card image
     - Implemented a FAB menu for "Add to Collection", "Favorite", and "Wishlist" actions
     - Increased card image size (55% in normal layout, 85% in wide layout)
   - Fixed white borders in the full-screen image viewer
     - Implemented the CornerMaskWidget to handle white corners in card images
     - Used a black background with proper border radius
     - Maintained the ClipRRect for consistent corner rounding
     - Used BoxFit.cover to ensure the image fills the entire container
     - Preserved Hero animation for smooth transitions

1. **Collection UI Improvements**
   - Updated collection grid to match cards grid implementation
   - Added card labels toggle in collection page
   - Improved collection card display with quantity indicators
   - Enhanced collection search functionality to search by card name
   - Fixed scrolling issues in collection content
   - Added scroll to top functionality
   - Improved sort options with animation and visual feedback
   - Added price sorting options (market, low, mid, high)
   - Fixed search functionality in collection edit page
   - Ensured consistent UI between cards and collection features

1. **Card Details Page Enhancement**
   - Added action buttons below the card image
   - Implemented "Add to Collection" button that navigates to the Collection Edit page with the selected card
   - Added placeholder "Favorite" button with star icon and toggle functionality
   - Added placeholder "Add to Wishlist" button with bookmark icon and toggle functionality
   - Ensured buttons are visually consistent with the app's design language
   - Improved layout to accommodate the new action buttons

1. **Collection Edit Page Enhancement**
   - Added integrated card search functionality
   - Implemented search bar in the app bar when in search mode
   - Created search results list with card images and details
   - Added ability to select a card from search results
   - Improved UX flow for adding new cards to collection
   - Ensured seamless integration with existing collection management features
   - Added support for direct navigation from Card Details page

1. **Collection Feature Implementation**
   - Created collection data models with support for regular and foil cards
   - Added card condition tracking with standardized condition codes
   - Implemented purchase information tracking with price and date
   - Added professional grading support for PSA, BGS, and CGC
   - Created collection repository with Firestore integration
   - Implemented collection providers for state management
   - Created collection UI with grid and list views
   - Added collection statistics card
   - Implemented filtering and sorting functionality
   - Created detailed collection item view
   - Added add/edit functionality for collection items
   - Integrated with card cache for efficient image loading
   - Updated router to include collection routes
   - Fixed nested scrollable widgets issue in collection content
   - Fixed layout issues by converting sliver widgets to regular widgets in collection grid and list

1. **Theme System Enhancement**
   - Added ThemeSettingsPage for customizing app appearance
   - Implemented color picker for selecting custom theme colors
   - Added predefined color schemes from FlexColorScheme
   - Created contrast extension to ensure text readability
   - Implemented theme mode selection (light, dark, system)
   - Added persistent theme settings using Hive storage
   - Create deck building interface
   - Implement deck validation rules
   - Add deck statistics and analysis
   - Support different deck formats
   - Enable deck sharing functionality

1. **Card Scanner Implementation**
   - Develop camera integration for card scanning
   - Implement image recognition for cards
   - Create quick add to collection from scan
   - Add batch scanning for multiple cards

1. **Price Tracking Implementation**
   - Integrate with price APIs
   - Add price history charts
   - Implement price alerts
   - Calculate collection value

1. **Performance Improvements**
   - Further optimize image loading
   - Reduce animation overhead
   - Implement progressive image loading techniques
   - Improve overall app responsiveness

1. **Error Handling**
   - Enhance error reporting
   - Improve recovery mechanisms
   - Add retry functionality for failed image loads
   - Better user feedback for errors
