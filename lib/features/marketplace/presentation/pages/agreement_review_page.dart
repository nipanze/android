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

      // Listen for realtime updates
      _repo.watchAgreement(widget.agreementId).listen((updated) {
        if (mounted && updated != null) {
          setState(() {
            _agreement = updated;
          });
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
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/positions');
            }
          },
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

              ElevatedButton(
                onPressed: agreement.isFullyLocked
                    ? () =>
                        context.go('/marketplace/deal-unlock/${agreement.id}')
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                ),
                child: const Text('Unlock Deal & Contact'),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Contact details are only revealed after unlock.\n'
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
    final statusColor =
        agreement.isFullyLocked ? AppColors.success : AppColors.warning;
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
            agreement.isFullyLocked
                ? 'Contract locked'
                : agreement.status.displayName,
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
