// lib/features/profile/presentation/pages/profile_page.dart
// ignore_for_file: unused_import, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => context.pop()),
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            const SizedBox(height: 8),
            Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF1E40AF), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(32)),
                child: Center(
                    child: Text(
                        user?.fullName?.isNotEmpty == true
                            ? user!.fullName![0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700)))),
            const SizedBox(height: 12),
            Text(user?.fullName ?? 'User',
                style: Theme.of(context).textTheme.titleMedium),
            Text(user?.email ?? '',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            if (user != null) RepTierBadge(user.repTier),
            const SizedBox(height: 20),
            SectionHeader('Details'),
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(children: [
                      _Row('Email', user?.email ?? '—'),
                      const Divider(height: 16),
                      _Row('District', user?.district ?? '—'),
                      const Divider(height: 16),
                      _Row('Lender token', user?.lenderToken ?? '—'),
                      const Divider(height: 16),
                      _Row('Credit score', '${user?.creditScore ?? 50}/100'),
                    ]))),
          ])),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.l, this.v);
  final String l, v;
  @override
  Widget build(BuildContext context) => Row(children: [
        Text(l, style: Theme.of(context).textTheme.bodyMedium),
        const Spacer(),
        Text(v,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))
      ]);
}
