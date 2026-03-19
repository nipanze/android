// lib/features/auth/presentation/pages/login_page.dart
// ignore_for_file: directives_ordering, deprecated_member_use

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../features/auth/data/auth_repository.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit(AuthBloc bloc) {
    if (!_formKey.currentState!.validate()) return;
    bloc.add(AuthLoginRequested(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(authRepository: getIt<AuthRepository>()),
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (ctx, state) {
          if (state is AuthSuccess) {
            final session = _authRepo(ctx).currentSession;
            if (session?.user.emailConfirmedAt == null) {
              ctx.go('${Routes.verifyEmail}?email=${Uri.encodeComponent(_emailCtrl.text.trim())}');
            } else {
              ctx.go(Routes.dashboard);
            }
          }
          if (state is AuthError) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (ctx, state) {
          final bloc = ctx.read<AuthBloc>();
          final isLoading = state is AuthLoading;

          return Scaffold(
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeInDown(
                        child: Text('Welcome back',
                            style: Theme.of(ctx).textTheme.displaySmall),
                      ),
                      const SizedBox(height: 8),
                      FadeInDown(
                        delay: const Duration(milliseconds: 100),
                        child: Text(
                          'Sign in to your OpenCapital account',
                          style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(ctx)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6),
                              ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Email
                      FadeInUp(
                        delay: const Duration(milliseconds: 150),
                        child: TextFormField(
                          key: const Key('emailField'),
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
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
                      ),
                      const SizedBox(height: 16),

                      // Password
                      FadeInUp(
                        delay: const Duration(milliseconds: 200),
                        child: TextFormField(
                          key: const Key('passwordField'),
                          controller: _passCtrl,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(
                                  _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Password is required';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Forgot password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => ctx.push(Routes.forgotPassword),
                          child: const Text('Forgot password?'),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Sign in button
                      FadeInUp(
                        delay: const Duration(milliseconds: 250),
                        child: ElevatedButton(
                          onPressed: isLoading ? null : () => _submit(bloc),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Sign In'),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Register link
                      FadeInUp(
                        delay: const Duration(milliseconds: 300),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Don't have an account? ",
                                style: Theme.of(ctx).textTheme.bodyMedium),
                            TextButton(
                              onPressed: () => ctx.push(Routes.register),
                              child: const Text('Create one'),
                            ),
                          ],
                        ),
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

  // Helper to get AuthRepository from DI (used for session check in listener)
  AuthRepository _authRepo(BuildContext ctx) => getIt<AuthRepository>();
}
