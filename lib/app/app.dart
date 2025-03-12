import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fftcg_companion/app/theme/app_theme.dart';
import 'package:fftcg_companion/app/theme/theme_provider.dart';
import 'package:fftcg_companion/core/routing/app_router.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/core/providers/auto_auth_provider.dart';
import 'package:talker_flutter/talker_flutter.dart';

class FFTCGCompanionApp extends ConsumerWidget {
  const FFTCGCompanionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize auto-authentication
    ref.watch(autoAuthProvider);

    return ErrorBoundary.run(
      () {
        final router = ref.watch(routerProvider);
        final themeMode = ref.watch(themeModeControllerProvider);
        final themeColor = ref.watch(themeColorControllerProvider);

        return MaterialApp.router(
          title: 'FFTCG Companion',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: AppTheme.lightCustomColor(themeColor),
          darkTheme: AppTheme.darkCustomColor(themeColor),
          routerConfig: router,
          builder: (context, child) {
            ErrorWidget.builder = (FlutterErrorDetails details) {
              return TalkerWrapper(
                talker: talker,
                options: const TalkerWrapperOptions(),
                child: CustomErrorWidget(details: details),
              );
            };

            return Material(child: child!);
          },
        );
      },
      context: 'FFTCGCompanionApp.build',
      fallback: const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('An error occurred starting the app'),
          ),
        ),
      ),
    );
  }
}

class CustomErrorWidget extends StatelessWidget {
  final FlutterErrorDetails details;

  const CustomErrorWidget({
    super.key,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'An error occurred',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                details.exception.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
