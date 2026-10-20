# GEMINI.md

## Project Overview

This is a Flutter application for Android and iOS that serves as a companion app for the Final Fantasy Trading Card Game (FFTCG). The app allows users to browse cards, manage their collection, build decks, and scan cards.

The project follows a clean, feature-based architecture and utilizes the following technologies:

*   **State Management:** Riverpod
*   **Routing:** GoRouter
*   **Backend:** Firebase (Authentication, Firestore, App Check, etc.)
*   **Local Storage:** Hive
*   **UI:** FlexColorScheme, Flutter Animate, and other UI components.

## Building and Running

### Prerequisites

*   Flutter SDK installed.
*   Firebase project set up with the necessary services enabled (Authentication, Firestore, etc.).
*   A `.env` file in the root of the project with the required environment variables (e.g., Firebase API keys).

### Commands

*   **Get dependencies:** `flutter pub get`
*   **Run code generation:** `flutter pub run build_runner build`
*   **Run the app:** `flutter run`

## Development Conventions

*   **State Management:** The project uses [Riverpod](https://riverpod.dev/) for state management. Follow the existing patterns for creating and using providers.
*   **Routing:** Navigation is handled by [GoRouter](https://pub.dev/packages/go_router). Routes are defined in `lib/core/routing/app_router.dart`.
*   **Architecture:** The project is structured by features (e.g., `cards`, `collection`, `profile`). New features should follow this structure.
*   **Linting:** The project uses `flutter_lints`. Ensure your code adheres to the linting rules.
*   **Code Generation:** The project uses `build_runner` for code generation (e.g., for Riverpod providers and data classes). Run `flutter pub run build_runner build` after making changes that require code generation.
