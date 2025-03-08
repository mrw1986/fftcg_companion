import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fftcg_companion/app/theme/contrast_extension.dart';
import 'package:fftcg_companion/core/providers/auth_provider.dart';
import 'package:fftcg_companion/shared/widgets/google_sign_in_button.dart';
import 'package:fftcg_companion/shared/widgets/loading_indicator.dart';
import 'package:fftcg_companion/shared/widgets/styled_button.dart';
import 'package:fftcg_companion/shared/widgets/themed_logo.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registerWithEmailAndPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final authState = ref.read(authStateProvider);

      // If user is anonymous, link the account
      if (authState.isAnonymous) {
        await authService.linkWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        // Otherwise create a new account
        await authService.createUserWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }

      if (mounted) {
        context.go('/profile');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final authState = ref.read(authStateProvider);

      // If user is anonymous, link the account
      if (authState.isAnonymous) {
        await authService.linkWithGoogle();
      } else {
        // Otherwise sign in with Google
        await authService.signInWithGoogle();
      }

      if (mounted) {
        context.go('/profile');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isAnonymous = authState.isAnonymous;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAnonymous ? 'Complete Registration' : 'Register'),
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  const ThemedLogo(height: 150),
                  const SizedBox(height: 24),
                  if (isAnonymous)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withAlpha(51), // 0.2 * 255 = 51
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context)
                                  .extension<ContrastExtension>()
                                  ?.primaryWithContrast ??
                              Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withAlpha(128),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'You\'re currently using the app without an account. Complete your registration to save your collection, decks, and settings.',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context)
                                  .extension<ContrastExtension>()
                                  ?.onSurfaceWithContrast ??
                              Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context)
                                  .extension<ContrastExtension>()
                                  ?.onSurfaceWithContrast ??
                              Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPasswordController,
                          decoration: const InputDecoration(
                            labelText: 'Confirm Password',
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: StyledButton(
                            onPressed: _registerWithEmailAndPassword,
                            text: isAnonymous
                                ? 'Complete Registration'
                                : 'Register',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isAnonymous) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => context.go('/profile/login'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            foregroundColor: Theme.of(context)
                                    .extension<ContrastExtension>()
                                    ?.primaryWithContrast ??
                                Theme.of(context).colorScheme.primary,
                          ),
                          child: const Text('Already have an account? Login'),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Divider(thickness: 1),
                  const SizedBox(height: 16),
                  GoogleSignInButton(
                    onPressed: _signInWithGoogle,
                    text: isAnonymous
                        ? 'Link with Google'
                        : 'Register with Google',
                  ),
                ],
              ),
            ),
    );
  }
}
