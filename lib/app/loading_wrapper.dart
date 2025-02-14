import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fftcg_companion/shared/widgets/loading_indicator.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/initialization_provider.dart';

class LoadingWrapper extends ConsumerWidget {
  final Widget child;

  const LoadingWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initializationState = ref.watch(initializationProvider);

    return Stack(
      children: [
        // Show child only when initialization is complete
        initializationState.maybeWhen(
          data: (_) => child,
          orElse: () => const SizedBox.shrink(),
        ),
        // Show loading screen during initialization or error
        initializationState.when(
          data: (_) => const SizedBox.shrink(),
          error: (error, _) => const LoadingIndicator(),
          loading: () => const LoadingIndicator(),
        ),
      ],
    );
  }
}
