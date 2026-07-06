// lib/features/marketplace/presentation/pages/deal_unlock_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../data/agreement_repository.dart';
import '../../domain/models/agreement.dart';

class DealUnlockPage extends StatefulWidget {
  const DealUnlockPage({super.key, required this.agreementId});

  final String agreementId;

  @override
  State<DealUnlockPage> createState() => _DealUnlockPageState();
}

class _DealUnlockPageState extends State<DealUnlockPage> {
  late final AgreementRepository _repo;
  Agreement? _agreement;
  bool _loading = true;
  String? _error;
  bool _unlocking = false;

  @override
  void initState() {
    super.initState();
    _repo = getIt<AgreementRepository>();
    _loadAgreement();
  }

  Future<void> _loadAgreement() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final agreement = await _repo.getAgreement(widget.agreementId);
      if (!mounted) return;

      setState(() {
        _agreement = agreement;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _unlockContact() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlock Contact Details?'),
        content: const Text(
          'This action is irreversible. Contact details will be revealed to both parties and you can then connect directly outside the platform.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unlock'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _unlocking = true);
    try {
      final contactData = await _repo.unlockContact(widget.agreementId);
      if (!mounted) return;

      // Show success dialog with contact details
      await showDialog(
        context: context,
        builder: (context) => _ContactRevealDialog(
          borrowerName: contactData.borrowerName,
          borrowerPhone: contactData.borrowerPhone,
          borrowerEmail: contactData.borrowerEmail,
          lenderName: contactData.lenderName,
          lenderPhone: contactData.lenderPhone,
          lenderEmail: contactData.lenderEmail,
          onClose: () {
            Navigator.pop(context);
            context.go('/marketplace');
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _unlocking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error unlocking contact: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Unlock Deal')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _agreement == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Unlock Deal')),
        body: ErrorState(
          message: _error ?? 'Agreement not found',
          onRetry: _loadAgreement,
        ),
      );
    }

    final agreement = _agreement!;

    if (!agreement.isFullyLocked) {
      return Scaffold(
        appBar: AppBar(title: const Text('Unlock Deal')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline, size: 48, color: AppColors.warning),
                const SizedBox(height: 16),
                Text(
                  'Deal Not Yet Ready',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Both borrower and lender must confirm the agreement before you can unlock contact details.',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Unlock Deal & Contact'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Locked badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                border: Border.all(color: AppColors.success),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lock, size: 20, color: AppColors.success),
                      const SizedBox(width: 8),
                      Text(
                        'Deal Agreement Locked',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Both borrower and lender have confirmed the deal. '
                    'You can now unlock contact details to connect directly.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // What happens next
            Text(
              'What Happens Next',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            const _InfoStep(
              number: 1,
              title: 'Contact Details Revealed',
              description: 'Legal name, phone, and email of both parties will be shared.',
            ),
            const SizedBox(height: 8),
            const _InfoStep(
              number: 2,
              title: 'Direct Connection',
              description: 'You can now contact your partner outside the Nipanze platform.',
            ),
            const SizedBox(height: 8),
            const _InfoStep(
              number: 3,
              title: 'Complete Transaction',
              description: 'Finalize the loan agreement and exchange funds directly.',
            ),
            const SizedBox(height: 32),

            // Disclaimer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bg3Light,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '⚠️ Nipanze does not hold or move any funds. You and your partner are '
                'solely responsible for all financial transactions and dispute resolution.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 32),

            // Unlock button
            ElevatedButton(
              onPressed: _unlocking ? null : _unlockContact,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
              ),
              child: _unlocking
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Unlock Contact Details'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoStep extends StatelessWidget {
  const _InfoStep({
    required this.number,
    required this.title,
    required this.description,
  });

  final int number;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '$number',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContactRevealDialog extends StatelessWidget {
  const _ContactRevealDialog({
    required this.borrowerName,
    required this.borrowerPhone,
    required this.borrowerEmail,
    required this.lenderName,
    required this.lenderPhone,
    required this.lenderEmail,
    required this.onClose,
  });

  final String borrowerName;
  final String borrowerPhone;
  final String borrowerEmail;
  final String lenderName;
  final String lenderPhone;
  final String lenderEmail;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Contact Details Revealed'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Connection successful! Here are the contact details:',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            _ContactCard(
              label: 'Borrower',
              name: borrowerName,
              phone: borrowerPhone,
              email: borrowerEmail,
            ),
            const SizedBox(height: 12),
            _ContactCard(
              label: 'Lender',
              name: lenderName,
              phone: lenderPhone,
              email: lenderEmail,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bg3Light,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'You can now contact your partner directly to complete the transaction outside of the Nipanze platform.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onClose,
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.label,
    required this.name,
    required this.phone,
    required this.email,
  });

  final String label;
  final String name;
  final String phone;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.text2Light,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _ContactDetail(icon: Icons.person, value: name),
          const SizedBox(height: 4),
          _ContactDetail(icon: Icons.phone, value: phone),
          const SizedBox(height: 4),
          _ContactDetail(icon: Icons.email, value: email),
        ],
      ),
    );
  }
}

class _ContactDetail extends StatelessWidget {
  const _ContactDetail({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.text2Light),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
