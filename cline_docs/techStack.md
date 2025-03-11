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
- flex_color_scheme for comprehensive theming
  - Material 3 design support
  - Predefined color schemes
  - Custom color scheme generation
  - Light and dark theme variants
- flex_color_picker for theme color customization
  - Color wheel selection
  - Predefined color palettes
  - Copy/paste color support
  - Material design color selection
- Custom theme extensions
  - ContrastExtension for ensuring text readability
  - Automatic contrast adjustment for accessibility
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
- Firebase Authentication
  - Google Sign-In integration
  - Email/Password authentication
  - Anonymous authentication
  - Account linking
  - Password reset functionality
- Firestore for user data
  - Collection management
  - User preferences
  - Deck storage (planned)

### Local Storage

- Hive for local caching
  - Card data caching
  - Search results caching
  - User preferences and settings
  - Theme settings persistence
  - View preferences persistence
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

## Feature Implementations

### Authentication System

- Authentication Service
  - Firebase Authentication integration with comprehensive error handling
  - Google Sign-In with emulator detection and detailed logging
  - Email/Password authentication with verification tracking
  - Anonymous authentication with upgrade path
  - Account linking with preserved user data
  - Password reset with automatic logout for security

- UI Components
  - Redesigned GoogleSignInButton with loading state and error handling
  - Interactive SnackBar notifications with OK buttons
  - Login, registration, and account management pages
  - Email verification UI with clear feedback
  - Password reset flow with security considerations
  - Profile management with email change functionality

- State Management
  - AuthStateProvider for authentication state
  - UserRepository for Firestore integration
  - Comprehensive error handling with user-friendly messages
  - Logging throughout the authentication flow for debugging

### Collection Management System

- Data Models
  - CollectionItem model for user's card collection
  - Support for regular and foil cards
  - Card condition tracking (NM, LP, MP, HP, DMG)
  - Purchase information tracking (price, date)
  - Professional grading support (PSA, BGS, CGC)
  - Firestore integration with efficient document structure

- UI Components
  - Grid and list views with customizable sizes
  - Card labels toggle for showing/hiding card names and numbers
  - Collection statistics card
  - Filtering by card type (regular, foil, graded)
  - Sorting by various criteria (last modified, card ID, quantity, price)
  - Search functionality within collection
  - Collection edit page with integrated card search
  - Collection item detail page
  - Consistent UI with Cards feature

- State Management
  - AsyncNotifierProvider for collection data
  - StateProvider for search, filter, and sort preferences
  - FutureProvider for collection statistics
  - Provider for filtered and searched collection

- Firestore Integration
  - Efficient document structure for collection items
  - Real-time updates for collection changes
  - Offline support for collection management
  - Batch operations for multiple card updates

## Future Considerations

### Planned Additions

- Camera integration for card scanning
- Deck building
  - Deck creation and editing
  - Format validation
  - Deck statistics
  - Sharing capabilities
- Price tracking APIs
- Cloud synchronization
- Advanced text processing features
- Favorites and wishlist features
- Collection import/export functionality
- Collection sharing capabilities
- Batch operations for collection management

### Scalability

- Modular architecture for easy expansion
- Efficient data structures
- Performance monitoring
- Error tracking and analytics
- Loading state optimization
- Text processing optimization
