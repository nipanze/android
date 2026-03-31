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
  List<LoanBid> _bids = [];
  bool _loading = true;
  String? _error;
  bool _showBidSheet = false;
  bool _newBidFlash = false; // briefly highlights order book on new bid

  final _repo = getIt<MarketplaceRepository>();
  StreamSubscription<List<LoanBid>>? _orderBookSub;
  StreamSubscription<List<LoanListing>>? _listingSub;

  @override
  void initState() {
    super.initState();
    _loadOnce();
  }

  @override
  void dispose() {
    _orderBookSub?.cancel();
    _listingSub?.cancel();
    super.dispose();
  }

  // ── Initial load — fetch listing + order book once, then subscribe ──────────

  Future<void> _loadOnce() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _repo.getListingDetail(widget.requestId),
        _repo.getOrderBook(widget.requestId),
      ]);
      if (!mounted) return;
      setState(() {
        _listing = results[0] as LoanListing;
        _bids    = results[1] as List<LoanBid>;
        _loading = false;
      });
      _subscribeRealtime();
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ── Realtime subscriptions ──────────────────────────────────────────────────

  void _subscribeRealtime() {
    // Order book — fires whenever loan_bids row changes for this listing
    _orderBookSub = _repo.watchOrderBook(widget.requestId).listen(
      (bids) {
        if (!mounted) return;
        final hadBids = _bids.length;
        setState(() => _bids = bids);
        // Flash the order book briefly when a new bid arrives
        if (bids.length > hadBids) _flashOrderBook();
      },
      onError: (_) {}, // silently ignore; last data still shown
    );

    // Listing — fires when the listing itself changes (e.g. status → contracted)
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
    setState(() => _newBidFlash = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _newBidFlash = false);
  }

  // ── Accept bid ──────────────────────────────────────────────────────────────

  Future<void> _acceptBid(LoanBid bid) async {
    try {
      final contractId = await _repo.acceptBid(
        requestId: widget.requestId,
        bidId: bid.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bid accepted — contract created.')));
      context.go('/contracts/$contractId');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()),
            backgroundColor: AppColors.danger));
    }
  }

  // ── Subscription gate ───────────────────────────────────────────────────────

  void _showSubscriptionGate({required String requiredPlan, required String reason}) {
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

  // ── Build ───────────────────────────────────────────────────────────────────

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
        body: ErrorState(message: _error ?? 'Listing not found', onRetry: _loadOnce),
      );
    }

    final listing = _listing!;
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final isOwner = user?.id == null ? false : _isOwner(listing);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(listing.title, overflow: TextOverflow.ellipsis),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: RiskBadge.fromString(listing.riskCategory),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadOnce,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Amount + meta
            UgxAmount(listing.requestedAmount, fontSize: 26),
            const SizedBox(height: 4),
            Text(
              '${listing.district} · ${listing.durationMonths} months · ceiling ${listing.maxInterestRate.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            // Stats grid
            GridView.count(
              crossAxisCount: 2, shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 2.4,
              children: [
                _StatBox(
                  label: 'Best bid',
                  value: listing.bestBidRate != null
                      ? '${listing.bestBidRate!.toStringAsFixed(1)}%' : '—',
                  valueColor: listing.bestBidRate != null ? AppColors.success : null,
                ),
                _StatBox(
                  label: 'Bids received',
                  value: '${listing.numberOfBids}',
                  valueColor: listing.numberOfBids > 0 ? AppColors.accent : null,
                ),
                _StatBox(label: 'Credit band', value: listing.creditScoreBand,
                    valueColor: AppColors.success),
                _StatBox(
                  label: 'Time left',
                  value: listing.timeRemainingLabel,
                  valueColor: listing.isClosingSoon6h
                      ? AppColors.danger
                      : listing.isClosingSoon24h ? AppColors.warning : null,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Non-custodial notice
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.15)),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline, size: 14, color: AppColors.accent),
                SizedBox(width: 8),
                Expanded(child: Text(
                  'Nipanze does not hold or move funds. All financial settlement is direct between matched participants.',
                  style: TextStyle(fontSize: 10, color: AppColors.accent),
                )),
              ]),
            ),

            // Live order book
            const Row(children: [
              SectionHeader('Live order book'),
              SizedBox(width: 8),
              LiveDot(),
            ]),

            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: _newBidFlash
                    ? [BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.25),
                        blurRadius: 12, spreadRadius: 2)]
                    : [],
              ),
              child: _OrderBook(bids: _bids),
            ),

            const SizedBox(height: 24),

            // CTAs
            if (isOwner && _bids.isNotEmpty) ...[
              ElevatedButton(
                onPressed: () => _acceptBid(_bids.first),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success),
                child: Text(
                  'Accept best bid — ${_bids.first.interestRate.toStringAsFixed(1)}%'),
              ),
              const SizedBox(height: 10),
            ],

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
                      reason: 'A Lender or Pro subscription is required to place bids.',
                    );
                    return;
                  }
                  setState(() => _showBidSheet = true);
                },
                child: const Text('Place a bid'),
              ),

            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Added to watchlist.'))),
              child: const Text('Save to watchlist'),
            ),
          ]),
        ),
      ),
      bottomSheet: _showBidSheet
          ? _PlaceBidSheet(
              listing: listing,
              onClose: () => setState(() => _showBidSheet = false),
              onBidPlaced: () => setState(() => _showBidSheet = false),
            )
          : null,
    );
  }

  // Borrower can't see their own borrower_id from the view, so we check
  // by comparing against their listings via the auth state
  bool _isOwner(LoanListing listing) => false; // wired in Stage 3 with v_user_portfolio
}

// ─── Order Book ───────────────────────────────────────────────────────────────

class _OrderBook extends StatelessWidget {
  const _OrderBook({required this.bids});
  final List<LoanBid> bids;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            Expanded(child: Text('Lender', style: _hStyle(context))),
            Expanded(child: Text('Amount', style: _hStyle(context), textAlign: TextAlign.center)),
            Expanded(child: Text('Rate', style: _hStyle(context), textAlign: TextAlign.right)),
          ]),
        ),
        const Divider(height: 1),
        if (bids.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('No bids yet — be the first.',
                style: Theme.of(context).textTheme.bodySmall))
        else
          ...bids.asMap().entries.map((entry) {
            final isFirst = entry.key == 0;
            final bid = entry.value;
            final color = isFirst ? AppColors.success : null;
            return Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(children: [
                  Expanded(child: Text(bid.lenderToken ?? 'L-#???',
                      style: TextStyle(fontFamily: 'DM Mono', fontSize: 11,
                          color: color,
                          fontWeight: isFirst ? FontWeight.w500 : null))),
                  Expanded(child: Text(_fmt(bid.amount),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: 'DM Mono', fontSize: 11))),
                  Expanded(child: Text('${bid.interestRate.toStringAsFixed(1)}%',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontFamily: 'DM Mono', fontSize: 11,
                          color: color,
                          fontWeight: isFirst ? FontWeight.w500 : null))),
                ]),
              ),
              if (entry.key < bids.length - 1) const Divider(height: 1),
            ]);
          }),
      ]),
    );
  }

  TextStyle _hStyle(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w600);

  String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ─── Stat Box ─────────────────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value, this.valueColor});
  final String label; final String value; final Color? valueColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(10)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 10, letterSpacing: 0.5, fontWeight: FontWeight.w500)),
      const SizedBox(height: 3),
      Text(value, style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600, color: valueColor)),
    ]),
  );
}

// ─── Subscription Gate Sheet ──────────────────────────────────────────────────

class _SubscriptionGateSheet extends StatelessWidget {
  const _SubscriptionGateSheet({
    required this.requiredPlan,
    required this.reason,
    required this.onUpgrade,
  });

  final String requiredPlan;
  final String reason;
  final VoidCallback onUpgrade;

  static const _plans = [
    (
      name: 'Borrower',
      price: 'UGX 20,000/mo',
      features: ['Post up to 3 loan requests', 'Accept bids', 'Contact reveals'],
      color: AppColors.success,
    ),
    (
      name: 'Lender',
      price: 'UGX 35,000/mo',
      features: ['Bid on listings', 'Real-time alerts', 'Bid history'],
      color: AppColors.accent,
    ),
    (
      name: 'Pro',
      price: 'UGX 150,000/mo',
      features: ['All features', 'Analytics API', 'Priority support'],
      color: AppColors.purple,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Container(width: 36, height: 4,
            decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),

        const Icon(Icons.lock_outline_rounded,
            size: 32, color: AppColors.purple),
        const SizedBox(height: 12),

        Text('Subscription required',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(reason,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 20),

        // Plan cards
        Row(children: _plans.map((plan) {
          final isRequired = plan.name == requiredPlan || plan.name == 'Pro';
          return Expanded(child: Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isRequired
                  ? plan.color.withValues(alpha: 0.08)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isRequired
                    ? plan.color.withValues(alpha: 0.4)
                    : Theme.of(context).dividerColor,
                width: isRequired ? 1.5 : 1,
              ),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(plan.name,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: isRequired ? plan.color : null)),
              const SizedBox(height: 2),
              Text(plan.price,
                  style: const TextStyle(
                      fontFamily: 'DM Mono', fontSize: 9)),
              const SizedBox(height: 8),
              ...plan.features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Icon(Icons.check_rounded, size: 10,
                      color: isRequired ? plan.color : AppColors.text3Dark),
                  const SizedBox(width: 4),
                  Expanded(child: Text(f,
                      style: TextStyle(
                          fontSize: 9,
                          color: isRequired ? null : AppColors.text2Dark))),
                ]),
              )),
            ]),
          ));
        }).toList()),

        const SizedBox(height: 16),

        ElevatedButton(
          onPressed: onUpgrade,
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purple),
          child: Text('Upgrade to $requiredPlan'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Maybe later'),
        ),
      ]),
    );
  }
}

// ─── Place Bid Sheet ──────────────────────────────────────────────────────────

class _PlaceBidSheet extends StatefulWidget {
  const _PlaceBidSheet({
    required this.listing,
    required this.onClose,
    required this.onBidPlaced,
  });
  final LoanListing listing;
  final VoidCallback onClose;
  final VoidCallback onBidPlaced;

  @override
  State<_PlaceBidSheet> createState() => _PlaceBidSheetState();
}

class _PlaceBidSheetState extends State<_PlaceBidSheet> {
  final _amountController = TextEditingController();
  final _rateController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await getIt<MarketplaceRepository>().placeBid(
        requestId: widget.listing.requestId,
        amount: int.parse(_amountController.text.replaceAll(',', '')),
        interestRate: double.parse(_rateController.text),
      );
      widget.onBidPlaced();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bid placed successfully.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()),
              backgroundColor: AppColors.danger));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Form(
        key: _formKey,
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('Place a bid', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: widget.onClose),
          ]),
          const SizedBox(height: 12),
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount (UGX)',
              helperText: 'Amount you propose to lend — settlement off-platform',
              prefixIcon: Icon(Icons.account_balance_wallet_outlined, size: 18),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter an amount';
              final n = int.tryParse(v.replaceAll(',', ''));
              if (n == null || n < 100000) return 'Minimum UGX 100,000';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _rateController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Interest rate %',
              hintText: 'Max ${widget.listing.maxInterestRate.toStringAsFixed(1)}%',
              prefixIcon: const Icon(Icons.percent_rounded, size: 18),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter a rate';
              final r = double.tryParse(v);
              if (r == null || r < 1) return 'Enter a valid rate';
              if (r > widget.listing.maxInterestRate) {
                return 'Cannot exceed ceiling of ${widget.listing.maxInterestRate.toStringAsFixed(1)}%';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(height: 20, width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Submit bid'),
          ),
        ]),
      ),
    );
  }
}