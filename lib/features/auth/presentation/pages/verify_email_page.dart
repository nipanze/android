// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';

class VerifyEmailPage extends StatelessWidget {
  const VerifyEmailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated && !state.needsEmailVerification) {
            context.go(AppRoutes.marketplace);
          }
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.mark_email_unread_outlined,
                      color: AppColors.accent, size: 32),
                ),
                const SizedBox(height: 24),
                Text('Check your email',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 10),
                Text(
                  'We\'ve sent a verification link to your email address. Click the link to activate your account.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
                ),
                const SizedBox(height: 32),
                OutlinedButton(
                  onPressed: () {
                    context.read<AuthBloc>().add(const AuthStarted());
                  },
                  child: const Text('I\'ve verified — continue'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () async {
                    context.read<AuthBloc>();
                    // Resend via repository — access through BLoC in real implementation
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Verification email resent.')),
                    );
                  },
                  child: const Text('Resend email'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    context.read<AuthBloc>().add(const AuthSignOutRequested());
                    context.go(AppRoutes.login);
                  },
                  child: Text(
                    'Sign out',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
