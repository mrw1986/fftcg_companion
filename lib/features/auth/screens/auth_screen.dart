import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../config/routes.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<FFTCGAuthProvider>(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // Implement Google sign in later
              },
              child: const Text('Sign in with Google'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.emailSignIn),
              child: const Text('Sign in with Email'),
            ),
            TextButton(
              onPressed: () => authProvider.signInAnonymously(),
              child: const Text('Continue as Guest'),
            ),
          ],
        ),
      ),
    );
  }
}
