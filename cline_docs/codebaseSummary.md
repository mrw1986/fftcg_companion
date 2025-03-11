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

2. **Card Details Page UI Improvements**
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

3. **Collection UI Improvements**
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

4. **Card Details Page Enhancement**
   - Added action buttons below the card image
   - Implemented "Add to Collection" button that navigates to the Collection Edit page with the selected card
   - Added placeholder "Favorite" button with star icon and toggle functionality
   - Added placeholder "Add to Wishlist" button with bookmark icon and toggle functionality
   - Ensured buttons are visually consistent with the app's design language
   - Improved layout to accommodate the new action buttons

5. **Collection Edit Page Enhancement**
   - Added integrated card search functionality
   - Implemented search bar in the app bar when in search mode
   - Created search results list with card images and details
   - Added ability to select a card from search results
   - Improved UX flow for adding new cards to collection
   - Ensured seamless integration with existing collection management features
   - Added support for direct navigation from Card Details page

6. **Collection Feature Implementation**
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

7. **Theme System Enhancement**
   - Added ThemeSettingsPage for customizing app appearance
   - Implemented color picker for selecting custom theme colors
   - Added predefined color schemes from FlexColorScheme
   - Created contrast extension to ensure text readability
   - Implemented theme mode selection (light, dark, system)
   - Added persistent theme settings using Hive storage
   - Updated router to include theme settings route
   - Ensured colors have appropriate contrast in both light and dark modes

8. **Authentication Implementation**
   - Added Firebase Authentication integration with Google Sign-In, Email/Password, and Anonymous authentication
   - Created authentication service and Riverpod providers for state management
   - Implemented login, registration, and account management UI
   - Added password reset functionality
   - Implemented anonymous to permanent account conversion
   - Updated Profile page to show different options based on authentication state
   - Added account management features
   - Integrated authentication state with the app's navigation system
   - Enhanced Google Sign-In with detailed logging and emulator detection
   - Redesigned GoogleSignInButton with loading state and error handling
   - Added email verification tracking with isVerified field in UserModel
   - Made SnackBar notifications interactive with OK buttons
   - Improved error messages for authentication operations
   - Enhanced the overall authentication experience with better feedback

9. **UI Improvements**
   - Implemented swipe navigation in card details page with intuitive controls
   - Added navigation buttons on sides of card image for easy browsing
   - Implemented PageView for smooth transitions between cards
   - Ensured navigation respects current filtered card list
   - Implemented animated search bar in app bar
   - Fixed special ability styling in card descriptions
   - Improved card corner rounding in dark mode
   - Enhanced card image display with proper border radius
   - Added smooth animations for search transitions
   - Fixed splash screen to properly respect dark/light mode
   - Simplified loading indicator for a cleaner look
   - Fixed card list item corner rounding with dynamic border radius based on view size
   - Implemented element-colored cost crystals with dynamic rendering based on number of elements
   - Standardized element color palette across the application
   - Improved metadata chip organization with logical ordering
   - Made set categories (Promotional Sets, Collections & Decks, and Opus Sets) collapsed by default unless sets are selected
   - Changed sorting to make sealed products appear at the bottom of results instead of the top
   - Added Category filter using the filters.category document values
   - Updated Card model to use fullCardNumber for display and sorting
   - Modified sorting logic to ensure non-cards always appear at the bottom regardless of sort type
   - Replaced custom splash screen with properly configured native splash screen
   - Fixed Android 12+ splash screen to show the full logo with "COMPANION" text

10. **Performance Optimizations**
    - Improved image caching
    - Reduced unnecessary rebuilds
    - Optimized search functionality
    - Enhanced animation performance
    - Added memory cache layer to reduce Hive access
    - Implemented resilient storage operations with fallback mechanisms
    - Replaced deprecated withOpacity with withAlpha for better performance
    - Fixed nested scrollable widgets to prevent layout issues
    - Improved scrolling performance by using NeverScrollableScrollPhysics for nested scrollable widgets

11. **Bug Fixes**
    - Fixed card description text styling issues
    - Resolved card corner rounding problems in dark mode
    - Fixed null check error in ThemeSettingsPage when accessing FlexColor.schemes
      - Added null safety check when accessing predefined color schemes
      - Provided fallback to Material scheme when a scheme is not available
    - Improved error handling for image loading
    - Fixed search visibility issues
    - Resolved Hive box type mismatch errors
    - Fixed non-card items sorting to the top when filtering by set
    - Enhanced error recovery for storage operations
    - Fixed search visibility issues
    - Replaced deprecated withOpacity with withAlpha for better performance
    - Fixed nested scrollable widgets in collection content to prevent "Vertical viewport was given unbounded height" errors
    - Fixed "A RenderPadding expected a child of type RenderBox but received a child of type RenderSliverFillRemainingWithScrollable" error by converting sliver widgets to regular widgets

12. **Authentication Improvements**
    - Enhanced Google Sign-In error handling with detailed logging
    - Added emulator detection to provide specific warnings when running on emulators
    - Improved the GoogleSignInButton widget to show loading state and handle errors
    - Added email verification tracking with isVerified field in UserModel
    - Enhanced SnackBar notifications to be interactive with OK buttons
    - Improved error messages for authentication operations
    - Added better logging throughout the authentication process
    - Fixed issues with Google Sign-In on emulators
    - Enhanced the email verification process with better user feedback
    - Improved the password reset flow with automatic logout for security
    - Made all authentication notifications more user-friendly with longer durations
    - Used theme-consistent colors for all notifications

## User Feedback Integration

1. **Card Details Navigation**
   - Users wanted to browse through cards without returning to the list
   - Users needed to navigate between filtered or search results easily
   - Implemented swipe navigation with PageView for intuitive browsing
   - Added navigation buttons on sides of card image
   - Ensured navigation respects current filtered card list
   - Made navigation controls visually appealing and non-intrusive
   - Implemented smooth transitions between cards

2. **Collection Management Workflow**
   - Users wanted a more streamlined way to add cards to their collection
   - Users needed to search for cards when adding to collection
   - Users wanted to add cards directly from the card details page
   - Added "Add to Collection" button on card details page
   - Implemented integrated search in the collection edit page
   - Created seamless flow between card browsing and collection management
   - Added placeholder favorites and wishlist functionality for future implementation
   - Improved collection grid to match cards grid implementation
   - Added card labels toggle for better visibility
   - Enhanced collection search functionality

3. **Search Experience**
   - Users wanted a more intuitive search interface
   - Users requested ability to search within filtered cards
   - Users needed to sort search results
   - Users wanted access to all app bar actions during search
   - Implemented animated search bar that expands from right to left
   - Created FilteredSearchProvider for integrated search, filter, and sort
   - Made all app bar actions visible and functional during search
   - Added smooth transitions for all search-related UI elements
   - Ensured cards remain visible during search operations

4. **Collection Management**
   - Users wanted to track their card collection
   - Users needed to track card condition and purchase information
   - Users requested professional grading support
   - Implemented comprehensive collection tracking system
   - Added support for regular and foil cards
   - Created condition tracking with standardized codes
   - Added purchase information tracking with price and date
   - Implemented professional grading support for PSA, BGS, and CGC
   - Created intuitive UI for managing collection
   - Added statistics to track collection progress

5. **Card Details Page**
   - Users reported white corners on card images in dark mode
   - Users reported inconsistent styling for "T:" in card descriptions
   - Implemented fix using CornerMaskWidget to handle white corners
   - Fixed "T:" styling to show the dull.png image
   - Improved layout with navigation buttons and FAB
   - Increased card image size for better visibility

6. **Card Description Text**
   - Users reported inconsistent styling for special abilities
   - Updated regex pattern to handle different spacing scenarios
   - Improved text processing for consistent formatting

7. **Splash Screen and Loading Experience**
   - Users reported splash screen not respecting dark mode
   - Users wanted a cleaner loading indicator without the logo
   - Updated native splash screen configuration to use appropriate images for each theme
   - Modified custom splash screen to properly detect system brightness
   - Simplified loading indicator to show only a progress spinner

8. **UI Consistency**
   - Users reported inconsistent UI between Cards and Collection pages
   - Users wanted the same features available in both sections
   - Replicated the card label toggle from the Collection page to the Card Database page
   - Fixed the Collection sorting query to properly handle all sort methods
   - Adjusted padding between UI elements for a more compact layout
   - Improved the overall user experience with more consistent UI elements and behavior

9. **Authentication Experience**
   - Users reported issues with Google Sign-In on emulators
   - Users wanted better feedback during authentication operations
   - Users needed clearer verification instructions for email accounts
   - Enhanced Google Sign-In with detailed logging and emulator detection
   - Redesigned GoogleSignInButton with loading state and error handling
   - Added email verification tracking with isVerified field
   - Made SnackBar notifications interactive with OK buttons
   - Improved error messages for authentication operations
   - Enhanced the overall authentication experience with better feedback

## Upcoming Development Focus

1. **Favorites and Wishlist Implementation**
   - Implement full functionality for favorites feature
   - Create wishlist data models and repositories
   - Add wishlist management UI
   - Implement wishlist statistics and tracking
   - Enable sharing wishlists with other users

2. **Deck Builder Implementation**
   - Create deck building interface
   - Implement deck validation rules
   - Add deck statistics and analysis
   - Support different deck formats
   - Enable deck sharing functionality

3. **Card Scanner Implementation**
   - Develop camera integration for card scanning
   - Implement image recognition for cards
   - Create quick add to collection from scan
   - Add batch scanning for multiple cards

4. **Price Tracking Implementation**
   - Integrate with price APIs
   - Add price history charts
   - Implement price alerts
   - Calculate collection value

5. **Performance Improvements**
   - Further optimize image loading
   - Reduce animation overhead
   - Implement progressive image loading techniques
   - Improve overall app responsiveness

6. **Error Handling**
   - Enhance error reporting
   - Improve recovery mechanisms
   - Add retry functionality for failed image loads
   - Better user feedback for errors
