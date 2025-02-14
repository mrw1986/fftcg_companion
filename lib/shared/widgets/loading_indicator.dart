import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/fftcg_companion_logo.png',
            width: 150,
            height: 150,
          ),
          const SizedBox(height: 24),
          CircularProgressIndicator(
            color: colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
