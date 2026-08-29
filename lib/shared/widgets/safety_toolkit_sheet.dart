import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

Future<void> showSafetyToolkitSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetCtx) => const _SafetyToolkitSheet(),
  );
}

class _SafetyToolkitSheet extends StatelessWidget {
  const _SafetyToolkitSheet();

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
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.accent),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}
