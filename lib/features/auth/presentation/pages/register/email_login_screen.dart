// lib/features/auth/presentation/pages/register/email_login_screen.dart

import 'package:flutter/material.dart';


import '../../widgets/auth_widgets.dart';
import 'shared.dart';

class EmailLoginScreen extends StatelessWidget {
  const EmailLoginScreen({super.key, 
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.errorMsg,
    required this.onTogglePassword,
    required this.onBack,
    required this.onSubmit,
    required this.onForgotPassword,
    required this.onCreateAccount,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isLoading;
  final String? errorMsg;
  final VoidCallback onTogglePassword;
  final VoidCallback onBack;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;
  final VoidCallback onCreateAccount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BackHeader(onBack: onBack),
            const SizedBox(height: 16),
            const AuthBrandMark(),
            const SizedBox(height: 28),
            Text('Welcome back 👋',
                style: theme.textTheme.displayLarge?.copyWith(fontSize: 26)),
            const SizedBox(height: 6),
            Text('Login to your account', style: theme.textTheme.bodyMedium),
            if (errorMsg != null) ...[
              const SizedBox(height: 16),
              ErrorBanner(message: errorMsg!),
            ],
            const SizedBox(height: 28),
            AuthField(
              fieldKey: const Key('email_field'),
              label: 'Email',
              controller: emailController,
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter your email';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 14),
            AuthField(
              fieldKey: const Key('password_field'),
              label: 'Password',
              controller: passwordController,
              icon: Icons.lock_outline_rounded,
              obscureText: obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => onSubmit(),
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 17,
                ),
                onPressed: onTogglePassword,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter your password';
                return null;
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onForgotPassword,
                child: const Text('Forgot password?'),
              ),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : onSubmit,
              child: isLoading ? const ButtonLoader() : const Text('Sign in'),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: Divider(color: theme.dividerColor)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text('new here', style: theme.textTheme.bodySmall),
              ),
              Expanded(child: Divider(color: theme.dividerColor)),
            ]),
            const SizedBox(height: 16),
            AuthSecondaryButton(
              label: 'Create an account',
              onPressed: onCreateAccount,
            ),
            const SizedBox(height: 28),
            Text(
              'Nipanze is a technology marketplace. We do not hold, pool, or move your funds.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Country Selection Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
