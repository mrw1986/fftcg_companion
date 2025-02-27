# Technology Stack

## Frontend Framework

### Flutter

- Primary UI framework
- Cross-platform development
- Material Design components
- Efficient widget rebuilding

### State Management

- Riverpod for dependency injection and state management
  - AsyncNotifierProvider for async operations
  - StateNotifierProvider for mutable state
  - Provider for dependency injection
  - ConsumerWidget for reactive UI updates

### UI/UX Components

- flutter_native_splash for branded launch screen
- Shared loading indicators
- Page-level loading states
- Error handling components
- Rich text processing system
  - HTML tag support
  - Special token handling
  - Custom styling engine
  - Memory-efficient rendering

## Backend Services

### Firebase

- Cloud Firestore for card database
  - Real-time updates
  - Offline persistence
  - Complex querying capabilities
  - Optimized filter collections
  - SearchTerms array for efficient text search
  - Metadata collection for version tracking
  - Card versioning with dataVersion field
  - Incremental sync support
  - Hash-based change detection
- Firebase Storage for card images
- Firebase Authentication (planned)

### Local Storage

- Hive for local caching
  - Card data caching
  - Search results caching
  - User preferences
  - Custom adapters for complex types
  - Version-based cache management

## Architecture

### Project Structure

- Feature-first architecture
  - Separate modules by feature
  - Shared core functionality
  - Clear separation of concerns
  - Optimized filter system

### Design Patterns

- Repository pattern for data access
- Provider pattern for dependency injection
- MVVM-inspired presentation layer
- Clean Architecture principles
- Strategy pattern for text processing

### Data Flow

- Unidirectional data flow
- Immutable state management
- Reactive programming with Streams
- Async/await for asynchronous operations
- Optimized filter chain processing

### Loading and Initialization

- Native splash screen during app launch
- Efficient provider initialization
- Page-level loading management
- Error recovery mechanisms
- Consistent loading indicators

## Development Tools

### Code Generation

- build_runner for code generation
- freezed for immutable models
- riverpod_generator for provider generation

### Testing

- Unit tests with Flutter Test
- Widget tests for UI components
- Integration tests (planned)
- Text processing test suite

## Performance Optimizations

### Text Processing

- Efficient HTML parsing
- Optimized token handling
- Smart style inheritance
- Memory-efficient rendering
- Cached text layouts

### Image Loading

- Cached network images
- Progressive image loading
- Memory-efficient image caching
- Deferred prefetching strategy
- Visible-only image loading
- Optimized memory usage

### Data Management

- Efficient filtering algorithms
- Local caching for offline access
  - Version-based cache management
  - Optimized cache initialization
  - Improved cache hit rates
- Incremental sync system
  - Card-level versioning with dataVersion field
  - Selective data fetching based on version
  - Efficient Firestore reads
  - Robust offline fallback
- Lazy loading for large datasets
- Optimized provider initialization
- Separate filter collections
- Advanced search functionality
  - Progressive substring matching
  - Comprehensive search approach
  - Relevance-based sorting with improved alphabetical ordering
  - Offline search support
  - Efficient search term generation
  - Robust cache invalidation mechanism
  - Improved state management for search queries
  - Debounced search for better performance

### Loading States

- Minimal initialization chain
- Efficient resource loading
- Progressive UI updates
- Smooth transitions
- Reduced logging overhead
- Improved error handling

### Code Quality

- Clean code practices
- Removed unnecessary operations
- Optimized imports
- Enhanced error handling
- Efficient state management
- Memory leak prevention

## Future Considerations

### Planned Additions

- Camera integration for card scanning
- Price tracking APIs
- User authentication
- Cloud synchronization
- Advanced text processing features

### Scalability

- Modular architecture for easy expansion
- Efficient data structures
- Performance monitoring
- Error tracking and analytics
- Loading state optimization
- Text processing optimization
