import 'package:flutter/material.dart';

class LoadingScreen extends StatefulWidget {
  final String message;
  final double? progress;

  const LoadingScreen({
    super.key,
    required this.message,
    this.progress,
  });

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    // Trigger fade in after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      type: MaterialType.transparency,
      child: AnimatedOpacity(
        opacity: _visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Container(
          color: Color.alphaBlend(
            colorScheme.surface.withAlpha((0.95 * 255).round()),
            Colors.transparent,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo
                Image.asset(
                  'assets/images/fftcg_companion_logo.png',
                  width: 200,
                  height: 200,
                ),
                const SizedBox(height: 32),
                // Loading indicator
                if (widget.progress != null)
                  SizedBox(
                    width: 200,
                    child: LinearProgressIndicator(
                      value: widget.progress,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      color: colorScheme.primary,
                    ),
                  )
                else
                  CircularProgressIndicator(
                    color: colorScheme.primary,
                  ),
                const SizedBox(height: 24),
                // Loading message
                Text(
                  widget.message,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
