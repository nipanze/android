// lib/features/marketplace/presentation/pages/loan_detail_page.dart
// ignore_for_file: unused_import

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../auth/domain/models/nipanze_user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/marketplace_repository.dart';
import '../../domain/models/loan_listing.dart';

class LoanDetailPage extends StatefulWidget {
  const LoanDetailPage({super.key, required this.requestId});
  final String requestId;

  @override
  State<LoanDetailPage> createState() => _LoanDetailPageState();
}

class _LoanDetailPageState extends State<LoanDetailPage> {
  LoanListing? _listing;
  List<LoanOffer> _offers = [];
  bool _loading = true;
  String? _error;
  bool _showOfferSheet = false;
  bool _newOfferFlash = false;
  bool _isOwnerValue = false;

  final _repo = getIt<MarketplaceRepository>();
  StreamSubscription<List<LoanOffer>>? _offersSub;
  StreamSubscription<List<LoanListing>>? _listingSub;

  @override
  void initState() {
    super.initState();
    _loadOnce();
  }

  @override
  void dispose() {
    _offersSub?.cancel();
    _listingSub?.cancel();
    super.dispose();
  }

  Future<void> _loadOnce() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final listing = await _repo.getListingDetail(widget.requestId);
      if (!mounted) return;

      bool isOwner = false;
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        isOwner = await _repo.isListingOwner(
          requestId: widget.requestId,
          userId: authState.user.id,
        );
      }

      final offers = await _repo.getOffers(
        widget.requestId,
        includePrivate: isOwner,
      );

      if (!mounted) return;
      setState(() {
        _listing = listing;
        _offers = offers;
        _isOwnerValue = isOwner;
        _loading = false;
      });
      _subscribeRealtime();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _subscribeRealtime() {
    _offersSub = _repo
        .watchOffers(
      widget.requestId,
      includePrivate: _isOwnerValue,
    )
        .listen(
      (offers) {
        if (!mounted) return;
        final hadOffers = _offers.length;
        setState(() => _offers = offers);
        if (offers.length > hadOffers) _flashOrderBook();
      },
      onError: (_) {},
    );

    _listingSub = _repo.watchListings().listen(
      (listings) {
        if (!mounted) return;
        final updated = listings.where((l) => l.requestId == widget.requestId);
        if (updated.isNotEmpty) setState(() => _listing = updated.first);
      },
      onError: (_) {},
    );
  }

  void _flashOrderBook() async {
    setState(() => _newOfferFlash = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _newOfferFlash = false);
  }

  Future<void> _acceptOffer(LoanOffer offer) async {
    try {
      final agreementId = await _repo.acceptOffer(
        requestId: widget.requestId,
        offerId: offer.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Offer accepted — review the deal agreement.')));
      // Navigate to agreement review page
      context.go('/marketplace/agreement/$agreementId');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()), backgroundColor: AppColors.danger));
    }
  }

  void _showSubscriptionGate(
      {required String requiredPlan, required String reason}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SubscriptionGateSheet(
        requiredPlan: requiredPlan,
        reason: reason,
        onUpgrade: () {
          Navigator.pop(context);
          context.go('/account');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _listing == null) {
      return Scaffold(
        appBar: AppBar(),
        body: ErrorState(
            message: _error ?? 'Listing not found', onRetry: _loadOnce),
      );
    }

    final listing = _listing!;
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final isOwner = _isOwnerValue;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Listing Detail'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadOnce,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(listing.title,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            UgxAmount(listing.requestedAmount, fontSize: 26),
            const SizedBox(height: 16),

            _DescriptionSection(
                title: 'Proposed Repayment Plan',
                body:
                    '${listing.preferredRepaymentPlan}\n${listing.repaymentTimeline}'),
            const SizedBox(height: 12),
            _DescriptionSection(
                title: 'Purpose of Loan', body: listing.purpose),

            const SizedBox(height: 24),

            // Stats grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2.2,
              children: [
                _StatBox(label: 'Offers', value: '${listing.numberOfOffers}'),
                _StatBox(
                    label: 'Repayment',
                    value:
                        'UGX ${listing.repaymentAmountPerPeriod.toString()}'),
                _StatBox(
                    label: 'Duration',
                    value: '${listing.durationMonths} Months'),
                _StatBox(
                  label: 'Time left',
                  value: listing.timeRemainingLabel,
                  valueColor: listing.isClosingSoon6h ? AppColors.danger : null,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Live order book (Offers)
            const Row(children: [
              SectionHeader('Current Offers'),
              SizedBox(width: 8),
              LiveDot(),
            ]),
            const SizedBox(height: 8),

            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: _newOfferFlash
                    ? [
                        BoxShadow(
                            color: AppColors.success.withValues(alpha: 0.2),
                            blurRadius: 8)
                      ]
                    : [],
              ),
              child: _OfferList(
                  offers: _offers,
                  requestedAmount: listing.requestedAmount,
                  isOwner: isOwner,
                  onAccept: _acceptOffer),
            ),

            const SizedBox(height: 32),

            if (!isOwner)
              ElevatedButton(
                onPressed: () {
                  if (user == null) {
                    context.go('/auth/login');
                    return;
                  }
                  if (!user.canLend) {
                    _showSubscriptionGate(
                      requiredPlan: 'Lender',
                      reason: 'A subscription is required to make offers.',
                    );
                    return;
                  }
                  setState(() => _showOfferSheet = true);
                },
                child: const Text('Make an Offer'),
              ),
          ]),
        ),
      ),
      bottomSheet: _showOfferSheet
          ? _MakeOfferSheet(
              listing: listing,
              onClose: () => setState(() => _showOfferSheet = false),
              onOfferPlaced: () => setState(() => _showOfferSheet = false),
            )
          : null,
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({required this.title, required this.body});
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.accent, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
        ],
      );
}

class _OfferList extends StatelessWidget {
  const _OfferList(
      {required this.offers,
      required this.requestedAmount,
      required this.isOwner,
      required this.onAccept});
  final List<LoanOffer> offers;
  final int requestedAmount;
  final bool isOwner;
  final Function(LoanOffer) onAccept;

  @override
  Widget build(BuildContext context) {
    if (offers.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12)),
        child: const Text('No offers yet.', textAlign: TextAlign.center),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: offers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final offer = offers[index];
        final lenderLabel = offer.hasMaskedLender
            ? 'Lender #${index + 1}'
            : 'Lender #${offer.lenderId.substring(0, 5)}';
        final coverage = requestedAmount <= 0
            ? 0
            : ((offer.offerAmount / requestedAmount) * 100).round();
        final offerType = offer.offerAmount >= requestedAmount
            ? 'Full offer'
            : 'Partial offer · $coverage%';
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.person_outline, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lenderLabel,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                      offerType,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: offer.offerAmount >= requestedAmount
                                ? AppColors.success
                                : AppColors.accent,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              UgxAmount(offer.offerAmount, fontSize: 14),
            ]),
            if (offer.proposedExpectations != null &&
                offer.proposedExpectations!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(offer.proposedExpectations!,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
            if (isOwner) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => onAccept(offer),
                  child: const Text('Accept Offer'),
                ),
              ),
            ],
          ]),
        );
      },
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label.toUpperCase(),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontSize: 9, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: valueColor)),
        ]),
      );
}

class _SubscriptionGateSheet extends StatelessWidget {
  const _SubscriptionGateSheet(
      {required this.requiredPlan,
      required this.reason,
      required this.onUpgrade});
  final String requiredPlan;
  final String reason;
  final VoidCallback onUpgrade;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.lock_person_outlined,
              size: 48, color: AppColors.accent),
          const SizedBox(height: 16),
          Text('Upgrade Required',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(reason, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(
              onPressed: onUpgrade, child: Text('Upgrade to $requiredPlan')),
        ]),
      );
}

class _MakeOfferSheet extends StatefulWidget {
  const _MakeOfferSheet(
      {required this.listing,
      required this.onClose,
      required this.onOfferPlaced});
  final LoanListing listing;
  final VoidCallback onClose;
  final VoidCallback onOfferPlaced;
  @override
  State<_MakeOfferSheet> createState() => _MakeOfferSheetState();
}

class _MakeOfferSheetState extends State<_MakeOfferSheet> {
  final _amountController = TextEditingController();
  final _expController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _expController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await getIt<MarketplaceRepository>().makeOffer(
        requestId: widget.listing.requestId,
        amount: int.parse(_amountController.text.replaceAll(',', '')),
        expectations: _expController.text,
      );
      widget.onOfferPlaced();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Offer sent successfully.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()), backgroundColor: AppColors.danger));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border:
                Border(top: BorderSide(color: Theme.of(context).dividerColor))),
        child: Form(
            key: _formKey,
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text('Make an Offer',
                        style: Theme.of(context).textTheme.titleMedium),
                    const Spacer(),
                    IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: widget.onClose)
                  ]),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Amount (UGX)',
                        prefixIcon: Icon(Icons.payments_outlined)),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Enter amount' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _expController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                        labelText: 'Proposed Expectations',
                        hintText:
                            'Explain your terms, e.g. "To be paid back in 3 monthly installments starting April"',
                        alignLabelWithHint: true),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const CircularProgressIndicator()
                          : const Text('Send Offer')),
                ])),
      );
}
