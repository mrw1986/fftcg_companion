# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter application (Android/iOS) that serves as a companion app for the Final Fantasy Trading Card Game (FFTCG). Users can browse cards, manage their collection, build decks, and scan cards.

## Essential Commands

### Development Workflow

```bash
# Get dependencies
flutter pub get

# Run code generation (required after changes to providers, models with annotations)
flutter pub run build_runner build

# Run code generation with cleanup
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode for continuous code generation during development
flutter pub run build_runner watch --delete-conflicting-outputs

# Run the app
flutter run

# Run linter
flutter analyze

# Run tests
flutter test

# Clean build artifacts
flutter clean
```

### Firebase Setup

This project requires a `.env` file in the root directory with Firebase configuration. Ensure Firebase services are properly configured:
- Authentication (Email/Password, Google Sign-In, Anonymous)
- Firestore Database
- App Check
- Analytics, Crashlytics (configured but implementation pending)
- Storage

## Architecture

### Project Structure

The codebase follows a **feature-first architecture** with clean separation of concerns:

```
lib/
├── app/                    # App-level configuration
│   └── theme/             # Theme system with FlexColorScheme
├── core/                  # Core infrastructure
│   ├── extensions/        # Dart/Flutter extensions
│   ├── providers/         # Cross-cutting Riverpod providers (auth, etc.)
│   ├── routing/          # GoRouter configuration and navigation
│   ├── services/         # Core services (auth, logging)
│   ├── storage/          # Local storage with Hive
│   ├── utils/            # Utilities and helpers
│   └── widgets/          # Reusable core widgets
├── features/             # Feature modules (see below)
│   ├── cards/
│   ├── collection/
│   ├── decks/
│   ├── prices/
│   ├── profile/
│   └── scanner/
└── shared/               # Shared utilities and widgets
    ├── utils/
    └── widgets/
```

### Feature Module Structure

Each feature follows a layered architecture:

```
feature_name/
├── data/
│   └── repositories/      # Data access layer (Firestore, local storage)
├── domain/
│   └── models/           # Business entities and data models
└── presentation/
    ├── pages/            # Full-page widgets
    ├── widgets/          # Feature-specific widgets
    └── providers/        # Feature-specific Riverpod providers
```

### Key Architectural Patterns

**State Management - Riverpod**
- `AsyncNotifierProvider` for async operations (e.g., data fetching from Firebase)
- `StateNotifierProvider` for complex mutable state
- `NotifierProvider` for simpler state with methods (replacing deprecated `StateProvider` with `listenSelf`)
- `Provider` for dependency injection
- Use `ConsumerWidget` or `Consumer` for reactive UI updates
- Code generation via `riverpod_generator` and `riverpod_annotation`

**Navigation - GoRouter**
- Centralized route configuration in `lib/core/routing/app_router.dart`
- Bottom navigation with `StatefulShellRoute.indexedStack` for tab persistence
- Auth-aware redirects handled by `authNotifierProvider`
- Each tab (Cards, Collection, Decks, Scanner, Profile) has its own navigator key

**Data Layer**
- Repository pattern for data access
- Firestore for cloud storage
- Hive for local storage and offline support
- Type-safe models using `dart_mappable` for serialization

**Authentication System**
- Comprehensive auth service in `lib/core/services/auth_service.dart`
- Custom `AuthException` with categorized error handling
- Support for:
  - Email/Password authentication
  - Google Sign-In
  - Anonymous accounts with data migration on link
  - Email verification flows
  - Re-authentication for sensitive operations
  - Provider linking/unlinking

## Critical Implementation Details

### Code Generation

This project heavily relies on code generation. **Always run `flutter pub run build_runner build` after:**
- Creating or modifying Riverpod providers with `@riverpod` annotation
- Creating or modifying models with `@MappableClass` annotation
- Making changes that require generated `.g.dart` files

### Authentication Flow

The authentication system has several important characteristics:

1. **Anonymous Account Limitations**: Anonymous users are limited to 50 collection items (enforced via Firestore rules)
2. **Data Migration**: When linking anonymous accounts to Google/Email, collection and settings data migrate to the new user
3. **Email Updates**: Require verification with automatic token refresh and state synchronization
4. **Re-authentication**: Sensitive operations (email change, account deletion) require recent authentication

### Firestore Security Rules

Security rules in `firestore.rules` enforce:
- User-specific data access (users can only access their own data)
- Anonymous user collection limits (max 50 items)
- Email verification requirements for certain operations
- Proper validation of data structure on writes

When modifying collection or user data structures, **always update Firestore rules accordingly**.

### State Synchronization

**Critical**: The app uses several providers that must stay synchronized:
- `authNotifierProvider` - Auth state and user info
- `authStatusProvider` - Simple auth status for navigation
- Collection-related providers must invalidate on user changes

When making auth-related changes, ensure proper provider invalidation to prevent stale state.

### Theme System

The app uses FlexColorScheme with Material 3:
- Dynamic color generation from seed colors
- Light/dark mode support with system theme detection
- Custom color picker for user customization
- Theme persistence via Hive
- Automatic contrast handling

### HTML Content Rendering

Card descriptions use `flutter_html` package with **XSS sanitization**. When rendering HTML:
- HTML is sanitized before display (see HTML parser utilities)
- Element symbols are converted to image assets
- Keywords can be bolded (feature in progress)

## Common Development Tasks

### Adding a New Feature

1. Create feature directory under `lib/features/feature_name/`
2. Follow the data/domain/presentation structure
3. Create repository in `data/repositories/`
4. Define models in `domain/models/` with `@MappableClass` if needed
5. Create pages and widgets in `presentation/`
6. Define providers in `presentation/providers/` or feature root
7. Add routes to `lib/core/routing/app_router.dart`
8. Run code generation: `flutter pub run build_runner build`

### Modifying Collection or User Data

1. Update model classes
2. Update repository methods
3. **Update Firestore security rules** in `firestore.rules`
4. Test with both anonymous and authenticated users
5. Verify collection count tracking works correctly

### Testing Authentication Changes

Test with:
- Anonymous users (check 50-item limit)
- Email/password users (with and without verification)
- Google Sign-In users
- Account linking scenarios
- Email update flow
- Re-authentication flows

## Linting and Code Quality

- Project uses `flutter_lints` package
- Custom lint rules via `custom_lint` and `riverpod_lint`
- Analysis options in `analysis_options.yaml` (mostly defaults)
- Run `flutter analyze` before committing

## Important Context from Project Documentation

### Current State (from projectRoadmap.md)

**Completed Features:**
- Theme customization system
- Core collection management (with recent fixes to Firestore permissions and count tracking)
- Authentication system (recently rebuilt with improved state management)
- Card browsing and search

**Known Issues to Be Aware Of:**
- Ongoing: Resolve GlobalKey conflicts and ref disposal errors during auth flows
- Pending: Expand data migration to include deck data (currently only collection and settings)
- Some planned features are not yet implemented (deck builder, scanner, price tracking)

### Development Conventions

**Naming Conventions:**
- Feature-specific files: `feature_name_file.dart` (e.g., `profile_page.dart`)
- Providers: `*_provider.dart`
- Repositories: `*_repository.dart`
- Generated files: `*.g.dart` (never edit manually)

**Error Handling:**
- Use custom `AuthException` for auth errors with proper categorization
- Display user-friendly messages via `SnackbarHelper`
- Log errors via Talker logging system (`lib/core/utils/logger.dart`)

**UI/UX:**
- Maintain consistency with existing components
- Use Material 3 design system
- Implement responsive layouts for different screen sizes
- Ensure proper loading states for async operations
- Use established spacing and padding patterns

## Development Tools

- **FVM**: Flutter Version Manager (`.fvmrc` present - specific Flutter version pinned)
- **Logging**: Talker integration for debugging (`TalkerFlutter`, `TalkerRiverpodLogger`)
- **Debugging**: Use logger instance from `lib/core/utils/logger.dart`

## Security Considerations

- Never commit `.env` file with Firebase keys
- Follow Firestore security rules strictly
- Validate all user inputs before Firestore writes
- Handle re-authentication for sensitive operations
- Sanitize HTML content before display (XSS prevention)
- Anonymous users have enforced limits (50 collection items)
