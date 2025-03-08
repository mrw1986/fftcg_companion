# Project Roadmap

## Goals

- Create a comprehensive FFTCG companion app
- Provide card database with advanced search and filtering
- Support collection management
- Enable deck building functionality
- Implement card scanning feature

## Features

- [x] Card database with sorting options
  - [x] Sort by name, number, cost, power
  - [x] Handle crystal cards and sealed products properly
  - [x] Advanced filtering system
  - [x] Rich text processing
  - [x] Comprehensive search functionality
  - [x] Animated search interface
  - [x] Integrated search, filter, and sort functionality
  - [x] Swipe navigation in card details view
- [x] App initialization and loading
  - [x] Native splash screen
  - [x] Efficient provider initialization
  - [x] Consistent loading indicators
  - [x] Error handling and recovery
- [x] User authentication
  - [x] Google Sign-In integration
  - [x] Email/Password authentication
  - [x] Anonymous authentication
  - [x] Account management
  - [x] Profile settings
- [x] Theme customization
  - [x] Light/dark mode support
  - [x] System theme integration
  - [x] Custom theme color selection
  - [x] Predefined color schemes
  - [x] Contrast guarantees for accessibility
- [ ] Collection tracking
- [ ] Deck builder
- [ ] Card scanner
- [ ] Price tracking

## Completion Criteria

- Robust card database with proper sorting and filtering
- Accurate text processing and display
- Intuitive user interface
- Efficient data caching and offline support
- Reliable card scanning functionality
- Comprehensive collection management
- Smooth loading and initialization flow

## Progress Tracker

### Completed Tasks

- Implemented card database initialization
- Added card filtering system
- Created card detail view
- Implemented sorting functionality with proper handling of crystal cards and sealed products
- Separated sorting logic into dedicated widget
- Added native splash screen
- Improved app initialization flow
- Created consistent loading indicators
- Enhanced error handling
- Optimized provider initialization
- Added cache versioning system
- Optimized image loading performance
- Improved logging system
- Enhanced code quality
- Implemented deferred image prefetching
- Enhanced HTML tag support
- Improved text processing system
- Implemented case-insensitive EX BURST handling
- Fixed card name reference preservation
- Updated special ability formatting
- Optimized filter collection structure
- Improved search functionality for card names and numbers
- Enhanced search result relevance sorting
- Added offline support for search functionality
- Implemented progressive substring matching
- Fixed search functionality issues:
  - Rewrote CardSearchNotifier for better state management
  - Added clearSearchCache method to CardCache
  - Improved sorting logic for search results
  - Fixed progressive search issues
  - Enhanced alphabetical sorting for single-letter searches
  - Fixed name sorting in descending order
  - Implemented case-insensitive name comparison
  - Ensured consistent sorting behavior across the app
  - Added automatic scroll to top when applying sort
  - Created provider for accessing CardContent state
- Fixed set filter groups and optimized filter dialog:
  - Updated set categorization to properly include all core sets in Opus category
  - Implemented persistent caching for set card counts to reduce Firestore reads
  - Created StatefulWidget approach to eliminate card count flickering during set selection
  - Added prefetch mechanism for faster filter dialog loading
  - Optimized UI with placeholder counts while loading actual data
  - Fixed issue where only selected sets showed correct card counts with multiple filters
  - Modified cache key generation to handle set filtering properly
  - Updated filter providers to calculate set counts independently of selected sets
- Implemented animated search bar in app bar:
  - Created smooth expansion animation for search field
  - Added fade transitions for title and action buttons
  - Ensured cards remain visible during search operations
  - Implemented proper animation controllers and state management
  - Added scale and fade animations for floating action button during search
  - Improved overall search UX with fluid animations
- Enhanced search functionality with filtering and sorting:
  - Created FilteredSearchProvider for integrated search, filter, and sort operations
  - Implemented client-side search within filtered cards
  - Added ability to sort search results using any sort criteria
  - Made all app bar actions (filter, view type, size) visible during search
  - Ensured all operations are performed client-side to minimize Firestore reads
  - Improved search result accuracy with better matching algorithms
- Improved splash screen and loading experience:
  - Fixed splash screen to properly respect dark/light mode
  - Updated native splash screen configuration to use appropriate images for each theme
  - Modified custom splash screen to properly detect system brightness
  - Simplified loading indicator to show only a progress spinner
- Enhanced card metadata display:
  - Implemented element-colored cost crystals with dynamic rendering
  - Created different rendering approaches based on number of elements
  - Standardized element color palette across the application
  - Improved metadata chip organization with logical ordering
- Enhanced filter and sorting functionality:
  - Made set categories (Promotional Sets, Collections & Decks, and Opus Sets) collapsed by default unless sets are selected
  - Changed sorting to make sealed products appear at the bottom of results instead of the top
  - Added Category filter using the filters.category document values
  - Updated Card model to use fullCardNumber for display and sorting
  - Modified sorting logic to ensure non-cards always appear at the bottom regardless of sort type
- Implemented swipe navigation in card details page:
  - Added PageView for swiping between cards
  - Implemented navigation buttons on sides of card image
  - Ensured navigation respects current filtered card list
  - Added smooth transitions between cards
  - Improved UI with semi-transparent navigation controls
- Implemented Firebase Authentication:
  - Created authentication service for Google Sign-In, Email/Password, and Anonymous authentication
  - Implemented Riverpod providers for authentication state management
  - Created login, registration, and account management UI
  - Added password reset functionality
  - Implemented anonymous to permanent account conversion
  - Updated Profile page to show different options based on authentication state
  - Added account management features
- Implemented theme customization system:
  - Created theme settings page with mode selection (Light, Dark, System)
  - Added color picker for custom theme colors
  - Implemented predefined color schemes from FlexColorScheme
  - Created contrast extension to ensure text readability
  - Added theme persistence using Hive storage
  - Implemented safe color adjustments for better visibility
  - Updated router to include theme settings route

### In Progress

- Monitoring text processing performance
- Evaluating filter system efficiency
- Considering text caching optimizations
- Optimizing image loading performance

### Future Tasks

- Implement collection management
- Add deck building features
- Develop card scanning functionality
- Add price tracking system
- Consider loading progress indicators
- Add initialization performance metrics
- Enhance error handling for image loading

## Scalability Considerations

- Firebase infrastructure for real-time updates
- Local caching for offline access
- Modular architecture for easy feature additions
- Efficient data structures for large card collections
- Performance optimization for image loading
- Loading state optimization
- Error tracking and analytics
- Initialization performance monitoring
- Text processing optimization
- Filter system scalability
- Animation performance optimization
