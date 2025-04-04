import 'package:dart_mappable/dart_mappable.dart'; // Added
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'loading_state_provider.mapper.dart'; // Added
part 'loading_state_provider.g.dart'; // Added back for Riverpod generator

@MappableClass() // Added
class LoadingState with LoadingStateMappable {
  // Added mixin
  final String message;
  final double? progress;
  final bool isLoading;

  const LoadingState({
    // Changed to standard constructor
    required this.message,
    this.progress,
    this.isLoading = false, // Default value handled here
  });
}

@riverpod
class LoadingStateNotifier extends _$LoadingStateNotifier {
  @override
  LoadingState build() {
    // Constructor usage remains the same due to named parameters
    return const LoadingState(message: '', isLoading: false);
  }

  void startLoading(String message) {
    state = LoadingState(message: message, isLoading: true);
  }

  void updateProgress(String message, double progress) {
    state = LoadingState(
      message: message,
      progress: progress,
      isLoading: true,
    );
  }

  void stopLoading() {
    state = const LoadingState(message: '', isLoading: false);
  }
}
