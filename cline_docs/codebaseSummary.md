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
   - Account linking for anonymous to permanent account conversion
   - Authentication state management with Riverpod

### Feature Modules

1. **Cards Feature**
   - Card data models and repositories
   - Card grid and details views
   - Advanced search with filtering and sorting
   - Card metadata display
   - Animated search interface
   - Integrated search, filter, and sort functionality

2. **Collection Feature**
   - User's card collection management
   - Collection statistics and tracking
   - Add/remove cards from collection

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
   - Google Sign-In integration
   - Profile management
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

## External Dependencies

1. **Firebase/Firestore**
   - Used for card database
   - Firebase Authentication for user management
   - Google Sign-In integration
   - Analytics and crash reporting

2. **Image Handling**
   - Cached network image for efficient loading
   - Custom image widgets for card display
   - Progressive image loading

3. **UI Components**
   - Custom widgets for consistent UI
   - Responsive layouts for different screen sizes
   - Animations for improved UX
   - Animated transitions for search and filtering

## Recent Significant Changes

1. **Theme System Enhancement**
   - Added ThemeSettingsPage for customizing app appearance
   - Implemented color picker for selecting custom theme colors
   - Added predefined color schemes from FlexColorScheme
   - Created contrast extension to ensure text readability
   - Implemented theme mode selection (light, dark, system)
   - Added persistent theme settings using Hive storage
   - Updated router to include theme settings route
   - Ensured colors have appropriate contrast in both light and dark modes

2. **Authentication Implementation**
   - Added Firebase Authentication integration with Google Sign-In, Email/Password, and Anonymous authentication
   - Created authentication service and Riverpod providers for state management
   - Implemented login, registration, and account management UI
   - Added password reset functionality
   - Implemented anonymous to permanent account conversion
   - Updated Profile page to show different options based on authentication state
   - Added account management features
   - Integrated authentication state with the app's navigation system

3. **UI Improvements**
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

4. **Performance Optimizations**
   - Improved image caching
   - Reduced unnecessary rebuilds
   - Optimized search functionality
   - Enhanced animation performance
   - Added memory cache layer to reduce Hive access
   - Implemented resilient storage operations with fallback mechanisms

5. **Bug Fixes**
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

## User Feedback Integration

1. **Card Details Navigation**
   - Users wanted to browse through cards without returning to the list
   - Users needed to navigate between filtered or search results easily
   - Implemented swipe navigation with PageView for intuitive browsing
   - Added navigation buttons on sides of card image
   - Ensured navigation respects current filtered card list
   - Made navigation controls visually appealing and non-intrusive
   - Implemented smooth transitions between cards

2. **Search Experience**
   - Users wanted a more intuitive search interface
   - Users requested ability to search within filtered cards
   - Users needed to sort search results
   - Users wanted access to all app bar actions during search
   - Implemented animated search bar that expands from right to left
   - Created FilteredSearchProvider for integrated search, filter, and sort
   - Made all app bar actions visible and functional during search
   - Added smooth transitions for all search-related UI elements
   - Ensured cards remain visible during search operations

3. **Card Details Page**
   - Users reported white corners on card images in dark mode
   - Implemented fix using BoxDecoration with larger border radius
   - Removed Hero animation to prevent transition issues

4. **Card Description Text**
   - Users reported inconsistent styling for special abilities
   - Updated regex pattern to handle different spacing scenarios
   - Improved text processing for consistent formatting

5. **Splash Screen and Loading Experience**
   - Users reported splash screen not respecting dark mode
   - Users wanted a cleaner loading indicator without the logo
   - Updated native splash screen configuration to use appropriate images for each theme
   - Modified custom splash screen to properly detect system brightness
   - Simplified loading indicator to show only a progress spinner

## Upcoming Development Focus

1. **Collection Management Implementation**
   - Implement collection tracking functionality
   - Create UI for adding/removing cards from collection
   - Add collection statistics
   - Implement card condition and purchase info tracking
   - Ensure proper integration with user authentication

2. **Deck Builder Implementation**
   - Create deck building interface
   - Implement deck validation rules
   - Add deck statistics and analysis
   - Support different deck formats
   - Enable deck sharing functionality

3. **Performance Improvements**
   - Further optimize image loading
   - Reduce animation overhead
   - Implement progressive image loading techniques
   - Improve overall app responsiveness

4. **Error Handling**
   - Enhance error reporting
   - Improve recovery mechanisms
   - Add retry functionality for failed image loads
   - Better user feedback for errors

5. **Additional UI Enhancements**
   - Refine animation timings for optimal user experience
   - Implement additional micro-interactions
   - Improve accessibility features
   - Enhance dark mode experience
