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
  - Loading states

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

## External Dependencies

### Key Components

- Firebase for backend services
- Hive for local storage
- Riverpod for state management
- GoRouter for navigation
- Freezed for immutable models

## Recent Changes

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

### Performance Optimizations

- Efficient filtering algorithms
- Improved image caching
- Better state updates

## User Feedback Integration

- Improved sorting behavior
- Better handling of special cards
- Enhanced filtering options

## Known Issues

- None currently tracked

## Development Guidelines

- Feature-first architecture
- Clean Architecture principles
- Comprehensive documentation
- Regular testing
- Performance monitoring
