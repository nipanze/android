// ignore_for_file: unused_local_variable, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
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

  final _repo = getIt<MarketplaceRepository>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _repo.getListingDetail(widget.requestId),
        _repo.getOrderBook(widget.requestId),
      ]);
      setState(() {
        _listing = results[0] as LoanListing;
        _bids = results[1] as List<LoanBid>;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _acceptBid(LoanBid bid) async {
    try {
      final contractId = await _repo.acceptBid(
        requestId: widget.requestId,
        bidId: bid.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bid accepted — contract created.')),
        );
        context.go('/contracts/$contractId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: ErrorState(message: _error!, onRetry: _load),
      );
    }

    final listing = _listing!;
    final authState = context.watch<AuthBloc>().state;
    final currentUserId = authState is AuthAuthenticated ? authState.user.id : null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(listing.title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: RiskBadge.fromString(listing.riskCategory),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.4,
                children: [
                  _StatBox(
                    label: 'Best bid',
                    value: listing.bestBidRate != null
                        ? '${listing.bestBidRate!.toStringAsFixed(1)}%'
                        : '—',
                    valueColor: AppColors.success,
                  ),
                  _StatBox(
                    label: 'Competing',
                    value: '${listing.numberOfBids} bids',
                    valueColor: AppColors.accent,
                  ),
                  _StatBox(
                    label: 'Bids',
                    value: '${listing.numberOfBids}',
                    valueColor: listing.numberOfBids > 0 ? AppColors.success : null,
                  ),
                  _StatBox(
                    label: 'Credit band',
                    value: listing.creditScoreBand,
                    valueColor: AppColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    listing.numberOfBids > 0
                        ? '${listing.numberOfBids} lender${listing.numberOfBids != 1 ? 's' : ''} competing'
                        : 'No bids yet — be the first',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    listing.timeRemainingLabel,
                    style: TextStyle(
                      fontSize: 10,
                      color: listing.isClosingSoon6h ? AppColors.danger : null,
                    ),
                  ),
                ],
              ),

              // Order book
              SectionHeader('Live order book'),
              _OrderBook(bids: _bids),

              const SizedBox(height: 12),
              // Non-custodial notice
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Nipanze never holds or moves funds. Accepting a bid exchanges contact details so you can arrange the deal directly.',
                  style: TextStyle(fontSize: 10, height: 1.5),
                ),
              ),

              const SizedBox(height: 24),

              // CTAs
              if (_bids.isNotEmpty)
                ElevatedButton(
                  onPressed: () => _acceptBid(_bids.first),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                  child: Text(
                    'Accept best bid — ${_bids.first.interestRate.toStringAsFixed(1)}%',
                  ),
                ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => setState(() => _showBidSheet = true),
                child: const Text('Place a bid'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Added to watchlist.')),
                  );
                },
                child: const Text('Save to watchlist'),
              ),
            ],
          ),
        ),
      ),
      bottomSheet: _showBidSheet
          ? _PlaceBidSheet(
              listing: listing,
              onClose: () => setState(() => _showBidSheet = false),
              onBidPlaced: () {
                setState(() => _showBidSheet = false);
                _load();
              },
            )
          : null,
    );
  }
}

// ─── Order Book ────────────────────────────────────────────────────────────────
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
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(child: Text('Lender', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600))),
                Expanded(child: Text('Amount', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                Expanded(child: Text('Rate', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
              ],
            ),
          ),
          const Divider(height: 1),
          if (bids.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('No bids yet — be the first.',
                  style: Theme.of(context).textTheme.bodySmall),
            )
          else
            ...bids.asMap().entries.map((entry) {
              final isFirst = entry.key == 0;
              final bid = entry.value;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            bid.lenderToken ?? 'L-#???',
                            style: TextStyle(
                              fontFamily: 'DM Mono',
                              fontSize: 11,
                              color: isFirst ? AppColors.success : null,
                              fontWeight: isFirst ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _fmt(bid.amount),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontFamily: 'DM Mono', fontSize: 11),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${bid.interestRate.toStringAsFixed(1)}%',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontFamily: 'DM Mono',
                              fontSize: 11,
                              color: isFirst ? AppColors.success : null,
                              fontWeight: isFirst ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (entry.key < bids.length - 1) const Divider(height: 1),
                ],
              );
            }),
        ],
      ),
    );
  }

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

// ─── Stat Box ──────────────────────────────────────────────────────────────────
class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w500,
                  )),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Place Bid Sheet ───────────────────────────────────────────────────────────
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Place a bid', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: widget.onClose,
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (UGX)',
                prefixIcon: Icon(Icons.attach_money, size: 18),
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
                labelText: 'Interest rate % (max ${widget.listing.maxInterestRate.toStringAsFixed(1)}%)',
                prefixIcon: const Icon(Icons.percent, size: 18),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter a rate';
                final r = double.tryParse(v);
                if (r == null || r < 1) return 'Enter a valid rate';
                if (r > widget.listing.maxInterestRate) {
                  return 'Rate cannot exceed ${widget.listing.maxInterestRate.toStringAsFixed(1)}%';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Submit bid'),
            ),
          ],
        ),
      ),
    );
  }
}
