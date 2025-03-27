import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fftcg_companion/shared/utils/snackbar_helper.dart';

/// Shows a dialog for re-authentication
Future<bool> showReauthDialog(
  BuildContext context,
  WidgetRef ref,
  Function(AuthCredential) onReauthenticate,
) async {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  bool showPassword = false;
  bool result = false;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Re-authenticate'),
            content: isLoading
                ? const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'For security reasons, please re-enter your password to continue.',
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          enabled: false,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                showPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  showPassword = !showPassword;
                                });
                              },
                            ),
                          ),
                          obscureText: !showPassword,
                        ),
                      ],
                    ),
                  ),
            actions: isLoading
                ? []
                : [
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        final currentContext = context;
                        if (passwordController.text.isEmpty) {
                          SnackBarHelper.showErrorSnackBar(
                            context: currentContext,
                            message: 'Please enter your password',
                          );
                          return;
                        }

                        setState(() {
                          isLoading = true;
                        });

                        try {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null || user.email == null) {
                            throw Exception('User not found or has no email');
                          }

                          emailController.text = user.email!;
                          final credential = EmailAuthProvider.credential(
                            email: user.email!,
                            password: passwordController.text,
                          );

                          await onReauthenticate(credential);
                          result = true;
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                        } catch (e) {
                          setState(() {
                            isLoading = false;
                          });

                          String errorMessage = 'Authentication failed';
                          if (e is FirebaseAuthException) {
                            if (e.code == 'wrong-password') {
                              errorMessage =
                                  'Incorrect password. Please try again.';
                            } else if (e.code == 'too-many-requests') {
                              errorMessage =
                                  'Too many attempts. Please try again later.';
                            }
                          }

                          if (currentContext.mounted) {
                            SnackBarHelper.showErrorSnackBar(
                              context: currentContext,
                              message: errorMessage,
                            );
                          }
                        }
                      },
                      child: const Text('Authenticate'),
                    ),
                  ],
          );
        },
      );
    },
  );

  return result;
}

/// Shows a dialog for linking email/password to an account
Future<bool> showLinkEmailPasswordDialog(
  BuildContext context,
  WidgetRef ref,
  Function(String, String) onLinkEmailPassword,
) async {
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool isLoading = false;
  bool showPassword = false;
  bool showConfirmPassword = false;
  bool result = false;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Set Password'),
            content: isLoading
                ? const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Set a password for your account to enable email/password sign-in.',
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: const OutlineInputBorder(),
                            helperText:
                                'At least 8 characters with uppercase, lowercase, number, and special character',
                            helperMaxLines: 2,
                            suffixIcon: IconButton(
                              icon: Icon(
                                showPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  showPassword = !showPassword;
                                });
                              },
                            ),
                          ),
                          obscureText: !showPassword,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: confirmPasswordController,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                showConfirmPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  showConfirmPassword = !showConfirmPassword;
                                });
                              },
                            ),
                          ),
                          obscureText: !showConfirmPassword,
                        ),
                      ],
                    ),
                  ),
            actions: isLoading
                ? []
                : [
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        final currentContext = context;
                        // Validate password
                        if (passwordController.text.isEmpty) {
                          SnackBarHelper.showErrorSnackBar(
                            context: currentContext,
                            message: 'Please enter a password',
                          );
                          return;
                        }

                        if (passwordController.text.length < 8) {
                          SnackBarHelper.showErrorSnackBar(
                            context: currentContext,
                            message: 'Password must be at least 8 characters',
                          );
                          return;
                        }

                        // Check for uppercase
                        if (!RegExp(r'[A-Z]')
                            .hasMatch(passwordController.text)) {
                          SnackBarHelper.showErrorSnackBar(
                            context: currentContext,
                            message:
                                'Password must include an uppercase letter',
                          );
                          return;
                        }

                        // Check for lowercase
                        if (!RegExp(r'[a-z]')
                            .hasMatch(passwordController.text)) {
                          SnackBarHelper.showErrorSnackBar(
                            context: currentContext,
                            message: 'Password must include a lowercase letter',
                          );
                          return;
                        }

                        // Check for number
                        if (!RegExp(r'[0-9]')
                            .hasMatch(passwordController.text)) {
                          SnackBarHelper.showErrorSnackBar(
                            context: currentContext,
                            message: 'Password must include a number',
                          );
                          return;
                        }

                        // Check for special character
                        if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]')
                            .hasMatch(passwordController.text)) {
                          SnackBarHelper.showErrorSnackBar(
                            context: currentContext,
                            message:
                                'Password must include a special character',
                          );
                          return;
                        }

                        // Check passwords match
                        if (passwordController.text !=
                            confirmPasswordController.text) {
                          SnackBarHelper.showErrorSnackBar(
                            context: currentContext,
                            message: 'Passwords do not match',
                          );
                          return;
                        }

                        setState(() {
                          isLoading = true;
                        });

                        try {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null || user.email == null) {
                            throw Exception('User not found or has no email');
                          }

                          await onLinkEmailPassword(
                            user.email!,
                            passwordController.text,
                          );

                          result = true;
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                            if (currentContext.mounted) {
                              SnackBarHelper.showSuccessSnackBar(
                                context: currentContext,
                                message: 'Password set successfully',
                              );
                            }
                          }
                        } catch (e) {
                          setState(() {
                            isLoading = false;
                          });

                          String errorMessage = 'Failed to set password';
                          if (e is FirebaseAuthException) {
                            if (e.code == 'provider-already-linked') {
                              errorMessage =
                                  'Email/password authentication is already enabled';
                            } else if (e.code == 'requires-recent-login') {
                              errorMessage =
                                  'Please sign in again before setting a password';
                            }
                          }

                          if (currentContext.mounted) {
                            SnackBarHelper.showErrorSnackBar(
                              context: currentContext,
                              message: errorMessage,
                            );
                          }
                        }
                      },
                      child: const Text('Set Password'),
                    ),
                  ],
          );
        },
      );
    },
  );

  return result;
}
