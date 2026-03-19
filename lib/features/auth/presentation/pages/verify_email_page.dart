// ignore_for_file: duplicate_import, use_build_context_synchronously, deprecated_member_use, directives_ordering

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../features/auth/data/auth_repository.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../main.dart';
import '../bloc/auth_bloc.dart';
import '../../data/auth_repository.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key, required this.email});
  final String email;

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  Timer? _pollTimer;
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;
  bool _checkingVerification = false;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    // Poll every 3 seconds to detect when user confirms email in inbox
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_checkingVerification) return;
      setState(() => _checkingVerification = true);

      try {
        await supabase.auth.refreshSession();
        final user = supabase.auth.currentUser;
        if (user?.emailConfirmedAt != null && mounted) {
          // Mark in public.users table
          await getIt<AuthRepository>().markEmailVerified(user!.id);
          context.go(Routes.dashboard);
        }
      } finally {
        if (mounted) setState(() => _checkingVerification = false);
      }
    });
  }

  void _resend(AuthBloc bloc) {
    if (_cooldownSeconds > 0) return;
    bloc.add(AuthResendVerificationRequested(email: widget.email));
    setState(() => _cooldownSeconds = 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        _cooldownSeconds--;
        if (_cooldownSeconds <= 0) t.cancel();
      });
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(authRepository: getIt<AuthRepository>()),
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.mark_email_unread_outlined,
                      color: AppColors.primary, size: 44),
                ),
                const SizedBox(height: 32),
                Text('Check your inbox',
                    style: Theme.of(context).textTheme.headlineLarge,
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text(
                  'We sent a confirmation link to\n${widget.email}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                        height: 1.6,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'This page will update automatically when confirmed.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.45),
                      ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (ctx, state) => OutlinedButton.icon(
                    key: const Key('resendButton'),
                    onPressed: _cooldownSeconds > 0 ? null : () => _resend(ctx.read()),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(
                      _cooldownSeconds > 0
                          ? 'Resend in ${_cooldownSeconds}s'
                          : 'Resend Email',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () async {
                    await getIt<AuthRepository>().signOut();
                    if (context.mounted) context.go(Routes.login);
                  },
                  child: const Text('Use a different account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
