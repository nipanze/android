// lib/features/marketplace/presentation/pages/agreement_review_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../data/agreement_repository.dart';
import '../../domain/models/agreement.dart';

class AgreementReviewPage extends StatefulWidget {
  const AgreementReviewPage({super.key, required this.agreementId});

  final String agreementId;

  @override
  State<AgreementReviewPage> createState() => _AgreementReviewPageState();
}

class _AgreementReviewPageState extends State<AgreementReviewPage> {
  late final AgreementRepository _repo;
  Agreement? _agreement;
  bool _loading = true;
  String? _error;
  bool _borrowerConfirmed = false;
  bool _lenderConfirmed = false;
  bool _isConfirming = false;

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
        _borrowerConfirmed = agreement.borrowerAgreedAt != null;
        _lenderConfirmed = agreement.lenderAgreedAt != null;
        _loading = false;
      });

      // Listen for realtime updates
      _repo.watchAgreement(widget.agreementId).listen((updated) {
        if (mounted && updated != null) {
          setState(() {
            _agreement = updated;
            _borrowerConfirmed = updated.borrowerAgreedAt != null;
            _lenderConfirmed = updated.lenderAgreedAt != null;
          });

          // If locked, show completion message
          if (updated.isFullyLocked && !_isConfirming) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Deal agreement locked! Ready to unlock contact.'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _confirmAgreement() async {
    setState(() => _isConfirming = true);
    try {
      await _repo.confirmAgreement(widget.agreementId);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You confirmed the agreement.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Deal Agreement')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _agreement == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Deal Agreement')),
        body: ErrorState(
          message: _error ?? 'Agreement not found',
          onRetry: _loadAgreement,
        ),
      );
    }

    final agreement = _agreement!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Deal Agreement'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadAgreement,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status banner
              _StatusBanner(agreement: agreement),
              const SizedBox(height: 24),

              // Agreement status
              _AgreementStatusIndicator(
                borrowerAgreed: _borrowerConfirmed,
                lenderAgreed: _lenderConfirmed,
              ),
              const SizedBox(height: 24),

              // Agreement text
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Loan Agreement',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        agreement.agreementText,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons
              if (!agreement.isFullyLocked) ...[
                if (!_borrowerConfirmed || !_lenderConfirmed)
                  ElevatedButton(
                    onPressed: _isConfirming ? null : _confirmAgreement,
                    child: _isConfirming
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('I Agree to This Deal'),
                  ),
              ] else ...[
                // Locked - show unlock button
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.go('/marketplace/deal-unlock/${agreement.id}');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                  ),
                  child: const Text('Unlock Deal & Contact'),
                ),
              ],
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'This is a template agreement provided by Nipanze.\n'
                  'Final terms are solely between borrower and lender.',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.agreement});

  final Agreement agreement;

  @override
  Widget build(BuildContext context) {
    final statusColor = agreement.isFullyLocked ? AppColors.success : AppColors.warning;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        border: Border.all(color: statusColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Agreement Status',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            agreement.status.displayName,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _AgreementStatusIndicator extends StatelessWidget {
  const _AgreementStatusIndicator({
    required this.borrowerAgreed,
    required this.lenderAgreed,
  });

  final bool borrowerAgreed;
  final bool lenderAgreed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirmation Status',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 12),
        _PartyStatus(label: 'Borrower', confirmed: borrowerAgreed),
        const SizedBox(height: 8),
        _PartyStatus(label: 'Lender', confirmed: lenderAgreed),
      ],
    );
  }
}

class _PartyStatus extends StatelessWidget {
  const _PartyStatus({
    required this.label,
    required this.confirmed,
  });

  final String label;
  final bool confirmed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: confirmed
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.bg3Light,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: confirmed
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Icon(
            confirmed ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: confirmed ? AppColors.success : AppColors.text2Light,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: confirmed ? AppColors.success : AppColors.text2Light,
            ),
          ),
        ],
      ),
    );
  }
}
