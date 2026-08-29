import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

Future<void> showSafetyToolkitSheet(
  BuildContext context, {
  required Future<void> Function() onBlockUser,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetCtx) => _SafetyToolkitSheet(onBlockUser: onBlockUser),
  );
}

class _SafetyToolkitSheet extends StatelessWidget {
  const _SafetyToolkitSheet({required this.onBlockUser});

  final Future<void> Function() onBlockUser;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shield_outlined, color: AppColors.accent),
                const SizedBox(width: 10),
                Text(
                  'Safety Toolkit',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SafetyRow(
              icon: Icons.tips_and_updates_outlined,
              title: 'Safety tips',
              subtitle:
                  'Keep chats in Nipanze, verify identity, and never send advance fees.',
              onTap: () => _showInfo(
                context,
                'Safety tips',
                'Use verified profiles where possible, keep a written agreement, and report pressure, advance-fee requests, or suspicious payment instructions.',
              ),
            ),
            _SafetyRow(
              icon: Icons.flag_outlined,
              title: 'Report listing or user',
              subtitle: 'Tell support about fraud, pressure, or false details.',
              onTap: () => _showInfo(
                context,
                'Report listing or user',
                'Send the listing link and a short description to support@nipanze.com. In-app reports can be connected to this action later.',
              ),
            ),
            _SafetyRow(
              icon: Icons.support_agent_outlined,
              title: 'Support & help',
              subtitle: 'Contact Nipanze support for marketplace safety help.',
              onTap: () => _showInfo(
                context,
                'Support & help',
                'Email support@nipanze.com with the request ID and screenshots if you need urgent help.',
              ),
            ),
            _SafetyRow(
              icon: Icons.visibility_off_outlined,
              title: 'Block user',
              subtitle: 'Hide this user from your marketplace experience.',
              destructive: true,
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogCtx) => AlertDialog(
                    title: const Text('Block user?'),
                    content: const Text(
                      'You will stop seeing this user in listings and marketplace activity.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogCtx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(dialogCtx).pop(true),
                        child: const Text('Block'),
                      ),
                    ],
                  ),
                );
                if (confirmed != true || !context.mounted) return;
                Navigator.of(context).pop();
                await onBlockUser();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showInfo(BuildContext context, String title, String body) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _SafetyRow extends StatelessWidget {
  const _SafetyRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.danger : AppColors.accent;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: destructive ? AppColors.danger : null,
        ),
      ),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}
