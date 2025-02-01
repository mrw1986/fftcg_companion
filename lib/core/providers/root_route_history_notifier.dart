// lib/core/providers/root_route_history_notifier.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RootRouteHistoryNotifier extends StateNotifier<List<int>> {
  RootRouteHistoryNotifier() : super([0]);
  static const platform =
      MethodChannel('com.mrw1986.fftcg_companion/back_handler');

  void addHistory(int index) {
    // Only add to history if it's different from current
    if (state.isEmpty || state.last != index) {
      state = [...state, index];
    }
  }

  void removeLastHistory() {
    if (state.length > 1) {
      state = state.sublist(0, state.length - 1);
    }
  }

  void clearHistory() {
    state = [0];
  }

  int get currentIndex => state.last;
  bool get canGoBack => state.length > 1;

  // Initialize back press handler
  void initBackPressHandler(BuildContext context) {
    platform.setMethodCallHandler((call) async {
      if (call.method == 'handleBackPress') {
        if (canGoBack) {
          removeLastHistory();
          return true;
        }
        return false; // Let app_router handle the back press
      }
      return null;
    });
  }
}

final rootRouteHistoryProvider =
    StateNotifierProvider<RootRouteHistoryNotifier, List<int>>(
        (ref) => RootRouteHistoryNotifier());
