# CodebaseDetails

## Project Structure

### Core Directories
- `/lib`: Main source code directory
  - `/app`: Application-wide configurations and theme
  - `/core`: Shared utilities, services, and widgets
  - `/features`: Feature-specific implementations
  - `/shared`: Shared widgets and components

### Feature Organization
Each feature follows a clean architecture pattern:
- `/data`: Repositories and data sources
- `/domain`: Models and business logic
- `/presentation`: UI components and state management

## Key Features

### Cards Management
- Card model with comprehensive attributes
- Filtering and search capabilities
- Card details view with synergy information
- Card image caching for offline access

### Collection Tracking
- Collection statistics and management
- Progress tracking per set
- Local storage with Hive for offline access

### Deck Building
- Deck creation and management
- Card quantity tracking
- Element and cost distribution analysis

### Price Tracking
- Historical price data
- Price trend visualization
- Market value calculations

## Implementation Details

### State Management
- Riverpod providers for dependency injection
- State persistence with Hive
- Reactive UI updates

### Data Flow
1. Repository layer handles data operations
2. Domain models define business logic
3. Providers manage state and UI updates
4. Presentation layer renders UI components

### Offline Support
- Cached card images
- Local data persistence
- Sync management with Firestore

## Best Practices

### Code Organization
- Feature-first architecture for scalability
- Clean architecture principles for maintainability
- Shared components for consistency

### Performance Considerations
- Image caching strategy
- Efficient state management
- Optimized database queries

## Actionable Advice
- Follow the established feature structure for new features
- Use shared widgets from `/core` and `/shared` directories
- Implement proper error handling in repositories
- Cache network resources appropriately
- Write unit tests for business logic
- Document complex workflows and edge cases
