// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(authRepository: getIt()),
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (ctx, state) {
          if (state is AuthPasswordResetSent) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(content: Text('Reset email sent — check your inbox')),
            );
          }
          if (state is AuthError) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (ctx, state) {
          final isLoading = state is AuthLoading;
          final isSent = state is AuthPasswordResetSent;

          return Scaffold(
            appBar: AppBar(title: const Text('Reset Password')),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: isSent
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded,
                              color: AppColors.success, size: 64),
                          const SizedBox(height: 24),
                          Text('Reset email sent',
                              style: Theme.of(ctx).textTheme.headlineMedium,
                              textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          Text('Check your inbox and follow the link to reset your password.',
                              style: Theme.of(ctx).textTheme.bodyMedium,
                              textAlign: TextAlign.center),
                          const SizedBox(height: 32),
                          OutlinedButton(
                            onPressed: () => ctx.pop(),
                            child: const Text('Back to Sign In'),
                          ),
                        ],
                      )
                    : Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Forgot your password?',
                                style: Theme.of(ctx).textTheme.headlineLarge),
                            const SizedBox(height: 12),
                            Text(
                              'Enter your email address and we\'ll send you a reset link.',
                              style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(ctx)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                            ),
                            const SizedBox(height: 32),
                            TextFormField(
                              key: const Key('emailField'),
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email address',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Email is required';
                                if (!v.contains('@')) return 'Enter a valid email';
                                return null;
                              },
                            ),
                            const SizedBox(height: 32),
                            ElevatedButton(
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      if (_formKey.currentState!.validate()) {
                                        ctx.read<AuthBloc>().add(
                                              AuthPasswordResetRequested(
                                                  email: _emailCtrl.text.trim()),
                                            );
                                      }
                                    },
                              child: isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('Send Reset Email'),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
