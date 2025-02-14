# Codebase Summary

## Project Structure

### Core Components

- `/lib/core/`
  - Services (Firestore, caching)
  - Widgets (shared UI components)
  - Utils (helper functions)
  - Storage (local data persistence)
  - Providers (app-wide state management)

### Features

- `/lib/features/cards/`
  - Data layer (repositories)
  - Domain layer (models, business logic)
  - Presentation layer (pages, providers, widgets)
- `/lib/features/prices/` (planned)
- `/lib/features/collection/` (planned)
- `/lib/features/decks/` (planned)

### App Configuration

- `/lib/app/`
  - Theme configuration
  - App initialization
  - Route management
  - Native splash screen
- `/lib/shared/`
  - Common widgets (loading indicators)
  - Utility components

## Data Flow

### Card Data Management

1. Initial load from Firestore
2. Local caching with Hive
3. Repository layer for data access
4. Providers for state management
5. UI components for display

### State Management

- Riverpod providers for dependency injection
- AsyncNotifier for async operations
- StateNotifier for mutable state
- Consumer widgets for UI updates

### Loading and Initialization

1. Native splash screen during app launch
2. Efficient provider initialization
3. Page-level loading states
4. Consistent loading indicators
5. Error handling and recovery

## External Dependencies

### Key Components

- Firebase for backend services
- Hive for local storage
- Riverpod for state management
- GoRouter for navigation
- Freezed for immutable models
- flutter_native_splash for launch screen

## Recent Changes

### Loading System Improvements

- Implemented native splash screen
- Created simplified LoadingIndicator widget
- Removed LoadingWrapper complexity
- Enhanced provider initialization
- Improved error handling

### Card Sorting Improvements

- Moved SortBottomSheet to dedicated widget
- Updated sorting logic for crystal cards
- Improved filtering for non-card items
- Added secondary sorting by number

### Code Organization

- Separated concerns in card repository
- Improved provider structure
- Enhanced error handling
- Better state management
- New shared widgets directory

### Performance Optimizations

- Efficient filtering algorithms
- Improved image caching
  - Deferred image prefetching
  - Limited to visible cards
  - Memory-efficient loading
- Better state updates
- Optimized initialization flow
  - Version-based cache management
  - Reduced logging overhead
  - Improved code quality
  - Removed unnecessary operations

## User Feedback Integration

- Improved loading experience
- Better error handling
- Enhanced initialization flow
- Consistent loading indicators

## Known Issues

- None currently tracked

## Recent Performance Improvements

### Caching System

- Added version tracking to prevent unnecessary cache clearing
- Optimized cache initialization
- Improved cache hit rates

### Image Loading

- Deferred prefetching until after initial render
- Limited prefetching to first 20 visible cards
- Removed redundant image preloading

### Logging System

- Reduced logging verbosity
- Filtered out debug logs
- Removed excessive animation logging
- Cleaned up unnecessary logging code

### Code Quality

- Removed duplicate catch clauses
- Cleaned up unused imports
- Removed unnecessary overrides
- Enhanced code organization

## Development Guidelines

- Feature-first architecture
- Clean Architecture principles
- Comprehensive documentation
- Regular testing
- Performance monitoring
- Consistent loading states
- Error handling best practices
