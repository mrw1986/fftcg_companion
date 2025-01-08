// lib/features/cards/presentation/providers/filter_options_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fftcg_companion/core/services/firestore_provider.dart';
import 'package:fftcg_companion/features/cards/domain/models/card_filter_options.dart';

part 'filter_options_provider.g.dart';

@riverpod
class FilterOptionsNotifier extends _$FilterOptionsNotifier {
  @override
  Future<CardFilterOptions> build() async {
    final firestoreService = ref.watch(firestoreServiceProvider);
    return firestoreService.getFilterOptions();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      final firestoreService = ref.read(firestoreServiceProvider);
      return firestoreService.getFilterOptions();
    });
  }
}
