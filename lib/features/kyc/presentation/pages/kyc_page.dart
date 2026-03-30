// ignore_for_file: deprecated_member_use, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class KycPage extends StatefulWidget {
  const KycPage({super.key});
  @override State<KycPage> createState() => _KycPageState();
}

class _KycPageState extends State<KycPage> {
  String _status = 'not_submitted';
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => context.pop()),
        title: const Text('Identity verification'),
      ),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Status banner
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(
          color: _statusColor(_status).withOpacity(0.08), borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _statusColor(_status).withOpacity(0.3))),
          child: Row(children: [
            Icon(_statusIcon(_status), color: _statusColor(_status), size: 20),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_statusLabel(_status), style: TextStyle(fontWeight: FontWeight.w600, color: _statusColor(_status), fontSize: 13)),
              Text(_statusDescription(_status), style: Theme.of(context).textTheme.bodySmall),
            ])),
          ]),
        ),
        const SizedBox(height: 24),
        Text('Required documents', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        _DocItem(icon: Icons.badge_outlined, title: 'National ID — front', subtitle: 'Clear photo of the front of your Ugandan National ID'),
        _DocItem(icon: Icons.badge_outlined, title: 'National ID — back', subtitle: 'Clear photo of the back of your National ID'),
        _DocItem(icon: Icons.face_outlined, title: 'Selfie', subtitle: 'Hold your ID next to your face'),
        const SizedBox(height: 24),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
          child: const Text('Document uploads are stored securely. Your identity is never shown to other marketplace participants.', style: TextStyle(fontSize: 11))),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _submitting ? null : () async {
            setState(() => _submitting = true);
            await Future.delayed(const Duration(seconds: 1));
            if (mounted) setState(() { _status = 'pending'; _submitting = false; });
          },
          child: _submitting
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Submit documents'),
        ),
      ])),
    );
  }
  Color _statusColor(String s) { switch(s) { case 'approved': return AppColors.success; case 'pending': return AppColors.warning; case 'rejected': return AppColors.danger; default: return AppColors.accent; } }
  IconData _statusIcon(String s) { switch(s) { case 'approved': return Icons.verified; case 'pending': return Icons.hourglass_top; case 'rejected': return Icons.cancel_outlined; default: return Icons.upload_file_outlined; } }
  String _statusLabel(String s) { switch(s) { case 'approved': return 'KYC Approved'; case 'pending': return 'Under review'; case 'rejected': return 'Rejected'; default: return 'Not submitted'; } }
  String _statusDescription(String s) { switch(s) { case 'approved': return 'Identity verified. You can now create listings.'; case 'pending': return 'Documents submitted. Admin review in progress.'; case 'rejected': return 'Submission rejected. Please re-submit.'; default: return 'Submit documents to unlock listing creation.'; } }
}

class _DocItem extends StatelessWidget {
  const _DocItem({required this.icon, required this.title, required this.subtitle});
  final IconData icon; final String title; final String subtitle;
  @override Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12), decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Theme.of(context).dividerColor)),
    child: Row(children: [
      Icon(icon, size: 20, color: AppColors.accent),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      ])),
      Icon(Icons.upload_outlined, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
    ]));
}
