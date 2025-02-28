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
- [x] App initialization and loading
  - [x] Native splash screen
  - [x] Efficient provider initialization
  - [x] Consistent loading indicators
  - [x] Error handling and recovery
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

### In Progress

- Monitoring text processing performance
- Evaluating filter system efficiency
- Considering text caching optimizations

### Future Tasks

- Implement collection management
- Add deck building features
- Develop card scanning functionality
- Add price tracking system
- Consider loading progress indicators
- Add initialization performance metrics

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
