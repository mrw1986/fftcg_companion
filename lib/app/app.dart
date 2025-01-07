import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fftcg_companion/app/theme/app_theme.dart';
import 'package:fftcg_companion/app/theme/theme_provider.dart';
import 'package:fftcg_companion/core/routing/app_router.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:talker_flutter/talker_flutter.dart';

class FFTCGCompanionApp extends ConsumerWidget {
  const FFTCGCompanionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        return TalkerWrapper(
          talker: talker,
          options: const TalkerWrapperOptions(),
          child: child!,
        );
      },
    );
  }
}
