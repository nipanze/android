import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../domain/models/blocked_user.dart';
import '../cubit/blocked_users_cubit.dart';

class BlockedUsersPage extends StatelessWidget {
  const BlockedUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<BlockedUsersCubit>()..load(),
      child: const _BlockedUsersView(),
    );
  }
}

class _BlockedUsersView extends StatelessWidget {
  const _BlockedUsersView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.blockedUsers)),
      body: BlocConsumer<BlockedUsersCubit, BlockedUsersState>(
        listener: (context, state) {
          if (state is BlockedUsersLoaded && state.justUnblocked) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.userUnblocked)),
            );
          }
          if (state is BlockedUsersError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.danger,
              ),
            );
          }
        },
        builder: (context, state) {
          final isSaving = state is BlockedUsersSaving;
          if (state is BlockedUsersLoading || state is BlockedUsersInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          final users =
              state is BlockedUsersLoaded ? state.users : const <BlockedUser>[];

          if (users.isEmpty && !isSaving) {
            return RefreshIndicator(
              onRefresh: () => context.read<BlockedUsersCubit>().load(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                children: [
                  Icon(
                    Icons.visibility_off_outlined,
                    size: 42,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n.noBlockedUsers,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.noBlockedUsersSubtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: () => context.read<BlockedUsersCubit>().load(),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) => _BlockedUserTile(
                    user: users[index],
                    isSaving: isSaving,
                    onUnblock: isSaving
                        ? null
                        : () => _confirmUnblock(context, users[index]),
                  ),
                ),
              ),
              if (isSaving)
                const Positioned.fill(
                  child: AbsorbPointer(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmUnblock(BuildContext context, BlockedUser user) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.unblockUserConfirmTitle),
        content: Text(l10n.unblockUserConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.unblock),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<BlockedUsersCubit>().unblockUser(user.blockedId);
    }
  }
}

class _BlockedUserTile extends StatelessWidget {
  const _BlockedUserTile({
    required this.user,
    required this.isSaving,
    required this.onUnblock,
  });

  final BlockedUser user;
  final bool isSaving;
  final VoidCallback? onUnblock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateStr = DateFormat.yMMMd().format(user.createdAt);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      leading: UserAvatar(
        avatarUrl: user.avatarUrl,
        initials: user.initials,
        radius: 20,
      ),
      title: Text(user.displayName),
      subtitle: Text(l10n.blockedOnDate(dateStr)),
      trailing: TextButton(
        onPressed: isSaving ? null : onUnblock,
        child: Text(l10n.unblock),
      ),
    );
  }
}
