# TechStack

## Purpose and Overview
This Flutter application is built to help Final Fantasy Trading Card Game (FFTCG) players manage their card collection, build decks, and track card prices. The tech stack is carefully chosen to provide a robust, scalable, and maintainable mobile application.

## Core Technologies
- **Flutter/Dart**: Cross-platform UI framework for building natively compiled applications
- **Firebase/Firestore**: Backend and database solution for real-time data synchronization
- **Riverpod**: State management solution for dependency injection and app state
- **Hive**: Local storage solution for offline data persistence

## Key Dependencies
- **GoRouter**: Navigation and routing
- **Freezed**: Code generation for data classes
- **Firebase SDK**: Authentication and cloud services

## Architecture Overview
- **Feature-first Architecture**: Organized by features (cards, collection, decks, prices, etc.)
- **Clean Architecture Principles**: Separation of concerns with data, domain, and presentation layers
- **Repository Pattern**: Abstract data sources behind repository interfaces

## Development Environment
- **Flutter SDK**: Required for development
- **Android Studio/VSCode**: IDE with Flutter plugins
- **Firebase CLI**: For managing Firebase services

## Build and Deployment
- Android: Gradle-based build system
- iOS: Xcode build system with CocoaPods
- Firebase configuration files included for both platforms

## Actionable Advice
- Always run `flutter pub get` after pulling new changes
- Use `build_runner` to generate code: `flutter pub run build_runner build`
- Keep Firebase configuration files up to date
- Test on both Android and iOS regularly
- Monitor Firebase quotas and usage
- Use proper null safety practices throughout the codebase
