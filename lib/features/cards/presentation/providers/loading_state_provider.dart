import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'loading_state_provider.freezed.dart';
part 'loading_state_provider.g.dart';

@freezed
class LoadingState with _$LoadingState {
  const factory LoadingState({
    required String message,
    double? progress,
    @Default(false) bool isLoading,
  }) = _LoadingState;
}

@riverpod
class LoadingStateNotifier extends _$LoadingStateNotifier {
  @override
  LoadingState build() {
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
