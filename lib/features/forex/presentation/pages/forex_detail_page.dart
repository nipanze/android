import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/forex_listing_model.dart';
import '../../../../shared/models/forex_offer_model.dart';
import '../../../../shared/widgets/send_rate_receive_panel.dart';

import '../../../../shared/widgets/trust_badges.dart';
import '../../../account/data/privacy_repository.dart';
import '../../../auth/domain/models/nipanze_user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../marketplace/presentation/widgets/lender_required_sheet.dart';
import '../../data/forex_repository.dart';

class ForexDetailPage extends StatefulWidget {
  const ForexDetailPage({super.key, required this.requestId});

  final String requestId;

  @override
  State<ForexDetailPage> createState() => _ForexDetailPageState();
}

class _ForexDetailPageState extends State<ForexDetailPage> {
  late Future<_ForexDetailData> _future;
  bool _showOfferSheet = false;
  ForexListingModel? _cachedListing;
  String? _ownerId;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ForexDetailData> _load() async {
    final repo = getIt<ForexRepository>();
    final listing = await repo.getRequestDetail(widget.requestId);
    _ownerId = await repo.getRequestOwnerId(widget.requestId);
    final offers = await repo.getOffers(widget.requestId);
    return _ForexDetailData(listing: listing, offers: offers);
  }

  void _refresh() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
          ),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(AppRoutes.marketplace),
        ),
        title: Text(l10n?.forexRequestTitle ?? 'Forex request'),
        actions: [
          if (user != null && _ownerId != null && _ownerId != user.id)
            PopupMenuButton<String>(
              tooltip: 'More',
              onSelected: (value) {
                if (value == 'block') _blockOwner();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'block',
                  child: Text(
                    AppLocalizations.of(context)?.blockUser ?? 'Block User',
                  ),
                ),
              ],
            ),
        ],
      ),
      body: FutureBuilder<_ForexDetailData>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            if (snapshot.hasError) {
              return Center(
                child: Text(userFacingErrorMessage(snapshot.error!)),
              );
            }
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          final listing = data.listing;
          _cachedListing = listing;
          final isOwner = user != null && _ownerId == user.id;

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Background carveout card ───────────────────────────────
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Send → Rate → Receive panel
                        SendRateReceivePanel(
                          listing: listing,
                          showBorder: false,
                          prominent: true,
                        ),

                        const SizedBox(height: 14),

                        // Settlement preference
                        Text(
                          listing.settlementPreference,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),

                        const SizedBox(height: 10),

                        // Trust badges
                        TrustBadgeRow(
                          ratingAvg: listing.trustRatingAvg,
                          reviewCount: listing.trustReviewCount,
                          completedDealsCount: listing.trustCompletedDealsCount,
                          isRepeatParticipant: listing.trustIsRepeatParticipant,
                          phoneVerified: listing.trustPhoneVerified,
                          responseTimeBucket: listing.trustResponseTimeBucket,
                        ),

                        const SizedBox(height: 18),

                        // ── Offers header ────────────────────────────────────
                        Row(
                          children: [
                            Text(
                              l10n?.offersLabel ?? 'OFFERS',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.45),
                                  ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${listing.numberOfOffers}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (listing.rateCoverageTier != null) ...[
                              const SizedBox(width: 4),
                              Text(
                                '· ${listing.rateCoverageTier}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 8),

                        // ── Offer tiles ──────────────────────────────────────
                        _OffersSection(
                          listing: listing,
                          offers: data.offers,
                          authState: authState,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Make an Offer button (outside card, like loan detail) ──
                  if (!isOwner)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (user == null) {
                            context.go(AppRoutes.login);
                            return;
                          }
                          if (!user.canLend) {
                            showLenderRequiredSheet(context);
                            return;
                          }
                          setState(() => _showOfferSheet = true);
                        },
                        child: Text(l10n?.makeAnOffer ?? 'Make an offer'),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
      bottomSheet: _showOfferSheet
          ? _MakeOfferSheet(
              requestId: widget.requestId,
              listing: _cachedListing,
              onClose: () => setState(() => _showOfferSheet = false),
              onOfferPlaced: () {
                setState(() => _showOfferSheet = false);
                _refresh();
              },
            )
          : null,
    );
  }

  Future<void> _blockOwner() async {
    final ownerId = _ownerId;
    if (ownerId == null) return;
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.blockUserConfirmTitle),
        content: Text(l10n.blockUserConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.block),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await getIt<PrivacyRepository>().blockUser(ownerId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.userBlocked)),
      );
      context.go(AppRoutes.marketplace);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userFacingErrorMessage(e)),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }
}

// ── Offers section ────────────────────────────────────────────────────────────

String _fmtRate(double rate) {
  if (rate == 0) return '0';
  final abs = rate.abs();
  final decimals = abs >= 1 ? 2 : (abs >= 0.001 ? 4 : 6);
  final str = rate.toStringAsFixed(decimals);
  if (str.contains('.')) {
    final trimmed =
        str.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    return trimmed;
  }
  return str;
}

class _OffersSection extends StatelessWidget {
  const _OffersSection({
    required this.listing,
    required this.offers,
    required this.authState,
  });

  final ForexListingModel listing;
  final List<ForexOfferModel> offers;
  final AuthState authState;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canSeePro = authState is AuthAuthenticated &&
        (authState as AuthAuthenticated).user.subscriptionPlan ==
            SubscriptionPlan.pro;

    if (offers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          'Exact rates are visible only to the request owner and participants.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return Column(
      children: offers.map((offer) {
        final servedAmount = offer.amountAvailable * offer.rateOffered;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${l10n?.rateOfferedLabel ?? 'Rate offered'} ${_fmtRate(offer.rateOffered)}',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${l10n?.forexServesLabel ?? 'Serves'} ${listing.currencyNeeded} ${_fmtAmount(servedAmount)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (canSeePro && offer.professionalTag != null) ...[
                    const SizedBox(width: 8),
                    _ProfessionalTag(offer.professionalTag!),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${l10n?.amountToExchangeOut ?? 'Amount to exchange out'}: ${listing.currencyHeld} ${_fmtAmount(offer.amountAvailable)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 10),
              TrustBadgeRow(
                ratingAvg: offer.trustRatingAvg,
                reviewCount: offer.trustReviewCount,
                completedDealsCount: offer.trustCompletedDealsCount,
                isRepeatParticipant: offer.trustIsRepeatParticipant,
                phoneVerified: offer.trustPhoneVerified,
                responseTimeBucket: offer.trustResponseTimeBucket,
                isVerified: offer.trustIsVerified,
                showReviews: true,
                showCompletedDeals: true,
              ),
              const SizedBox(height: 10),
              Text(
                offer.status,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _fmtAmount(num amount) {
    final formatted =
        amount % 1 == 0 ? amount.toInt().toString() : amount.toStringAsFixed(2);
    final parts = formatted.split('.');
    final integer = parts[0];
    final buffer = StringBuffer();
    for (int i = 0; i < integer.length; i++) {
      if (i > 0 && (integer.length - i) % 3 == 0) buffer.write(',');
      buffer.write(integer[i]);
    }
    if (parts.length > 1) buffer.write('.${parts[1]}');
    return buffer.toString();
  }
}

// ── Professional tag chip ─────────────────────────────────────────────────────

class _ProfessionalTag extends StatelessWidget {
  const _ProfessionalTag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.accent,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ── Make Offer bottom sheet ───────────────────────────────────────────────────

class _MakeOfferSheet extends StatefulWidget {
  const _MakeOfferSheet({
    required this.requestId,
    this.listing,
    required this.onClose,
    required this.onOfferPlaced,
  });

  final String requestId;
  final ForexListingModel? listing;
  final VoidCallback onClose;
  final VoidCallback onOfferPlaced;

  @override
  State<_MakeOfferSheet> createState() => _MakeOfferSheetState();
}

class _MakeOfferSheetState extends State<_MakeOfferSheet> {
  final _rateController = TextEditingController();
  final _amountController = TextEditingController();
  final _termsController = TextEditingController();
  bool _submitting = false;
  int _step = 0; // 0 = Enter Terms, 1 = Preview, 2 = Sent

  // ── Parsed values ──────────────────────────────────────────────────────────
  double get _parsedRate => double.tryParse(_rateController.text) ?? 0.0;
  int get _parsedAmount =>
      int.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;

  double? get _calculatedReceive {
    if (_parsedRate <= 0 || _parsedAmount <= 0) return null;
    return _parsedAmount * _parsedRate;
  }

  bool get _isFormReady => _parsedRate > 0 && _parsedAmount > 0;

  // ── Loss / Overpayment Calculations ────────────────────────────────────────
  double get _baselineReceive {
    final pref = widget.listing?.preferredRate;
    if (pref == null || pref <= 0 || _parsedAmount <= 0) return 0.0;
    return _parsedAmount * pref;
  }

  double get _offeredReceive => _calculatedReceive ?? 0.0;

  double get _overpaymentLoss {
    if (_baselineReceive <= 0) return 0.0;
    return (_offeredReceive - _baselineReceive).clamp(0.0, 999999999.0);
  }

  double get _overpaymentPct {
    final pref = widget.listing?.preferredRate;
    if (pref == null || pref <= 0 || _parsedRate <= 0) return 0.0;
    return ((_parsedRate - pref) / pref) * 100.0;
  }

  // True if rate offered is > 5% higher than preferred rate (giving away money / loss risk for offer maker)
  bool get _isLossRisk => _overpaymentPct > 5.0;

  bool get _isBelowPreferred {
    final pref = widget.listing?.preferredRate;
    if (pref == null || pref <= 0) return false;
    return _parsedRate < pref;
  }

  bool get _isAbovePreferred {
    final pref = widget.listing?.preferredRate;
    if (pref == null || pref <= 0) return false;
    return _parsedRate > pref;
  }

  double get _rateSliderMin {
    final pref = widget.listing?.preferredRate ?? 1.0;
    return (pref * 0.5).clamp(0.0001, 9999.0);
  }

  double get _rateSliderMax {
    final pref = widget.listing?.preferredRate ?? 5.0;
    return (pref * 2.0).clamp(0.0002, 99999.0);
  }

  // ── Formatting ─────────────────────────────────────────────────────────────
  String _fmtAmount(num amount) {
    final formatted = amount % 1 == 0
        ? amount.toInt().toString()
        : amount.toStringAsFixed(2);
    final parts = formatted.split('.');
    final integer = parts[0];
    final buffer = StringBuffer();
    for (int i = 0; i < integer.length; i++) {
      if (i > 0 && (integer.length - i) % 3 == 0) buffer.write(',');
      buffer.write(integer[i]);
    }
    if (parts.length > 1) buffer.write('.${parts[1]}');
    return buffer.toString();
  }

  // ── Loss Warning Prompt Dialog ──────────────────────────────────────────────
  Future<bool?> _showLossWarningDialog() {
    final l10n = AppLocalizations.of(context);
    final currency = widget.listing?.currencyNeeded ?? '';
    final pref = widget.listing?.preferredRate ?? 0.0;
    final lossAmt = _overpaymentLoss;

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: AppColors.danger,
          size: 40,
        ),
        title: Text(
          l10n?.principalLossWarningTitle ?? 'Unfavorable Rate Warning',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.danger, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Rate is +${_overpaymentPct.toStringAsFixed(1)}% higher than requester target (${_fmtRate(pref)}).',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Your rate of ${_fmtRate(_parsedRate)} gives the requester ${_fmtAmount(_offeredReceive)} $currency instead of the baseline ${_fmtAmount(_baselineReceive)} $currency.\n\n'
              'This creates an uncompensated extra payout of ${_fmtAmount(lossAmt)} $currency.\n\n'
              'Are you sure you want to proceed with this offer?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n?.cancel ?? 'Adjust Offer'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n?.sendAnyway ?? 'Send Offer Anyway'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final listing = widget.listing;
    if (listing != null) {
      if (listing.preferredRate != null && listing.preferredRate! > 0) {
        _rateController.text = _fmtRate(listing.preferredRate!);
      }
      _amountController.text = listing.amount.toString();
    }
    _rateController.addListener(_onInputChanged);
    _amountController.addListener(_onInputChanged);
  }

  void _onInputChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _rateController.removeListener(_onInputChanged);
    _amountController.removeListener(_onInputChanged);
    _rateController.dispose();
    _amountController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  // ── Steppers ───────────────────────────────────────────────────────────────
  void _adjustRate(double direction) {
    final current = _parsedRate;
    final step = current >= 100 ? 1.0 : (current >= 1 ? 0.1 : 0.0001);
    final next = (current + (direction * step)).clamp(0.0001, 999999.0);
    setState(() => _rateController.text = _fmtRate(next));
  }

  void _adjustAmount(int delta) {
    final listing = widget.listing;
    final max = listing != null ? listing.amount * 2 : 10000000;
    final next = (_parsedAmount + delta).clamp(1, max);
    setState(() => _amountController.text = next.toString());
  }

  // ── Submit ─────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _submitting = true);
    try {
      await getIt<ForexRepository>().makeOffer(
        requestId: widget.requestId,
        rateOffered: _parsedRate,
        amountAvailable: _parsedAmount,
        terms: _termsController.text.trim().isEmpty
            ? null
            : _termsController.text.trim(),
      );
      if (mounted) setState(() => _step = 2);
      await Future.delayed(const Duration(milliseconds: 600));
      widget.onOfferPlaced();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is AppException
                ? e.message
                : (l10n?.couldNotSendOffer ?? 'Could not send offer.'),
          ),
          backgroundColor: AppColors.warning,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ── Preview modal ──────────────────────────────────────────────────────────
  Future<void> _showPreview() async {
    if (_isLossRisk) {
      final confirm = await _showLossWarningDialog();
      if (confirm != true) return;
    }

    setState(() => _step = 1);
    final listing = widget.listing;
    final receive = _calculatedReceive;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.receipt_long_rounded,
                        color: AppColors.accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Preview Your Offer',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Review before submitting',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.08),
                      Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    _previewRow(
                      context,
                      icon: Icons.arrow_upward_rounded,
                      iconColor: AppColors.warning,
                      label: 'You Give',
                      value:
                          '${listing?.currencyHeld ?? ''} ${_fmtAmount(_parsedAmount)}',
                      valueColor: AppColors.warning,
                    ),
                    const SizedBox(height: 8),
                    _previewRow(
                      context,
                      icon: Icons.swap_horiz_rounded,
                      iconColor: AppColors.accent,
                      label: 'Exchange Rate',
                      value:
                          '1 ${listing?.currencyHeld ?? ''} = ${_fmtRate(_parsedRate)} ${listing?.currencyNeeded ?? ''}',
                    ),
                    const SizedBox(height: 8),
                    _previewRow(
                      context,
                      icon: Icons.arrow_downward_rounded,
                      iconColor: Colors.green,
                      label: 'They Receive',
                      value: receive != null
                          ? '${listing?.currencyNeeded ?? ''} ${_fmtAmount(receive)}'
                          : '—',
                      valueColor: Colors.green,
                      bold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (listing?.preferredRate != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _isLossRisk
                        ? AppColors.danger.withValues(alpha: 0.1)
                        : _isBelowPreferred
                            ? AppColors.warning.withValues(alpha: 0.08)
                            : Colors.green.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isLossRisk
                          ? AppColors.danger.withValues(alpha: 0.4)
                          : _isBelowPreferred
                              ? AppColors.warning.withValues(alpha: 0.3)
                              : Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isLossRisk
                            ? Icons.warning_amber_rounded
                            : _isBelowPreferred
                                ? Icons.info_outline_rounded
                                : Icons.check_circle_outline_rounded,
                        color: _isLossRisk
                            ? AppColors.danger
                            : _isBelowPreferred
                                ? AppColors.warning
                                : Colors.green,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isLossRisk
                              ? '🔴 OVERPAYMENT LOSS RISK: Rate is +${_overpaymentPct.toStringAsFixed(1)}% above target. You give an extra ${_fmtAmount(_overpaymentLoss)} ${listing?.currencyNeeded ?? ''}!'
                              : _isBelowPreferred
                                  ? '📈 HIGHER PROFIT MARGIN: Your rate (${_fmtRate(_parsedRate)}) is below target (${_fmtRate(listing!.preferredRate!)}). You keep more profit! (Requester may prefer a higher rate).'
                                  : _isAbovePreferred
                                      ? 'Your rate (${_fmtRate(_parsedRate)}) is above target — competitive offer rate!'
                                      : 'Your rate matches the requester\'s target rate.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: _isLossRisk ? AppColors.danger : null,
                                fontWeight: _isLossRisk ? FontWeight.w600 : null,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (_termsController.text.trim().isNotEmpty) ...[
                Text(
                  'Settlement Terms',
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _termsController.text.trim(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Edit Offer'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: const Text('Confirm & Send'),
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true) {
      await _submit();
    } else {
      if (mounted) setState(() => _step = 0);
    }
  }

  Widget _previewRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    Color? valueColor,
    bool bold = false,
  }) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 14),
        ),
        const SizedBox(width: 10),
        Expanded(
            child:
                Text(label, style: Theme.of(context).textTheme.bodySmall)),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                color: valueColor,
              ),
        ),
      ],
    );
  }

  // ── Step bar ───────────────────────────────────────────────────────────────
  Widget _buildStepBar(BuildContext context) {
    const steps = ['Enter Terms', 'Preview', 'Sent'];
    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          return Expanded(
            child: Container(
              height: 2,
              color: (i ~/ 2) < _step
                  ? AppColors.accent
                  : Theme.of(context).dividerColor,
            ),
          );
        }
        final s = i ~/ 2;
        final done = s < _step;
        final active = s == _step;
        return Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: (done || active)
                ? AppColors.accent
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
            border: Border.all(
              color: (done || active)
                  ? AppColors.accent
                  : Theme.of(context).dividerColor,
            ),
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check, size: 13, color: Colors.white)
                : Text(
                    '${s + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: active
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
          ),
        );
      }),
    );
  }

  // ── Rate slider ────────────────────────────────────────────────────────────
  Widget _buildRateSlider(BuildContext context) {
    final min = _rateSliderMin;
    final max = _rateSliderMax;
    final rate = _parsedRate.clamp(min, max);
    final sliderColor = _isLossRisk ? AppColors.danger : AppColors.accent;

    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 2.5,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        activeTrackColor: sliderColor,
        thumbColor: sliderColor,
        inactiveTrackColor: sliderColor.withValues(alpha: 0.18),
      ),
      child: Slider(
        value: rate,
        min: min,
        max: max,
        onChanged: (v) =>
            setState(() => _rateController.text = _fmtRate(v)),
      ),
    );
  }

  // ── Stepper suffix ─────────────────────────────────────────────────────────
  Widget _stepperSuffix({
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    const size = 26.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onMinus,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.remove_rounded, size: 14),
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onPlus,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.add_rounded,
                size: 14, color: AppColors.accent),
          ),
        ),
      ],
    );
  }

  // ── Amount presets ─────────────────────────────────────────────────────────
  Widget _buildAmountPresets(BuildContext context) {
    final listing = widget.listing;
    if (listing == null) return const SizedBox.shrink();
    final full = listing.amount;
    final presets = [
      ('50%', (full * 0.5).round()),
      ('75%', (full * 0.75).round()),
      ('100%', full),
    ];
    return Wrap(
      spacing: 6,
      children: presets.map((p) {
        final selected = _parsedAmount == p.$2;
        return GestureDetector(
          onTap: () =>
              setState(() => _amountController.text = p.$2.toString()),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.accent.withValues(alpha: 0.18)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? AppColors.accent
                    : Theme.of(context).dividerColor,
                width: selected ? 1.2 : 0.8,
              ),
            ),
            child: Text(
              p.$1,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: selected
                    ? AppColors.accent
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Live calc panel ────────────────────────────────────────────────────────
  Widget _buildLiveCalcPanel(BuildContext context) {
    final listing = widget.listing;
    final receive = _calculatedReceive;
    if (receive == null) return const SizedBox.shrink();

    final pref = listing?.preferredRate;
    final lossAmt = _overpaymentLoss;

    final Color panelColor;
    final IconData panelIcon;
    final String panelLabel;

    if (_isLossRisk) {
      panelColor = AppColors.danger;
      panelIcon = Icons.warning_amber_rounded;
      panelLabel = '🔴 OVERPAYMENT LOSS RISK (+${_overpaymentPct.toStringAsFixed(1)}%)';
    } else if (_isBelowPreferred) {
      panelColor = Colors.green;
      panelIcon = Icons.trending_up_rounded;
      panelLabel = '📈 HIGHER PROFIT FOR YOU (Target Unreached)';
    } else if (_isAbovePreferred) {
      panelColor = AppColors.accent;
      panelIcon = Icons.check_circle_outline_rounded;
      panelLabel = '🟢 COMPETITIVE OFFER RATE';
    } else {
      panelColor = AppColors.accent;
      panelIcon = Icons.calculate_rounded;
      panelLabel = '🤝 EXACT TARGET MATCH';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: panelColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: panelColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(panelIcon, color: panelColor, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  panelLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: panelColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You Give',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${listing?.currencyHeld ?? ''} ${_fmtAmount(_parsedAmount)}',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'They Receive',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${listing?.currencyNeeded ?? ''} ${_fmtAmount(receive)}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: panelColor,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (pref != null && pref > 0) ...[
            const SizedBox(height: 8),
            Container(height: 1, color: panelColor.withValues(alpha: 0.15)),
            const SizedBox(height: 8),
            if (_isLossRisk)
              Text(
                '⚠️ Extra payout of ${_fmtAmount(lossAmt)} ${listing?.currencyNeeded ?? ''} vs target (${_fmtRate(pref)}). You are giving away extra money (LOSS for you)!',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.danger,
                ),
              )
            else if (_isBelowPreferred)
              Text(
                '📈 Higher profit for you! You give less ${_fmtAmount(_baselineReceive - _offeredReceive)} ${listing?.currencyNeeded ?? ''} vs requester target (${_fmtRate(pref)}). (Requester may prefer higher rate).',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              )
            else
              Text(
                'Requester target: ${_fmtRate(pref)}  ·  Your rate: ${_fmtRate(_parsedRate)}  ·  Δ ${(_parsedRate - pref) >= 0 ? '+' : ''}${_fmtRate((_parsedRate - pref).abs())}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: panelColor,
                      fontWeight: FontWeight.w500,
                    ),
              ),
          ],
        ],
      ),
    );
  }

  // ── Trust badge ────────────────────────────────────────────────────────────
  Widget _buildTrustBadge(BuildContext context) {
    final listing = widget.listing;
    if (listing == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                listing.currencyHeld.isNotEmpty
                    ? listing.currencyHeld[0]
                    : '?',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${listing.currencyHeld} → ${listing.currencyNeeded}',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (listing.trustIsVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded,
                          size: 14, color: AppColors.accent),
                    ],
                  ],
                ),
                Row(
                  children: [
                    if (listing.trustRatingAvg != null) ...[
                      const Icon(Icons.star_rounded,
                          size: 13, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(listing.trustRatingAvg!.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(width: 6),
                    ],
                    if (listing.trustCompletedDealsCount > 0) ...[
                      const Icon(Icons.handshake_outlined,
                          size: 13, color: Colors.green),
                      const SizedBox(width: 2),
                      Text('${listing.trustCompletedDealsCount} deals',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(listing.country,
                  style: Theme.of(context).textTheme.labelSmall),
              Text(
                _fmtAmount(listing.amount),
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    l10n?.makeAnOffer ?? 'Make an offer',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Step bar
              _buildStepBar(context),
              const SizedBox(height: 16),

              // Trust badge
              _buildTrustBadge(context),
              const SizedBox(height: 16),

              // Fill preferred rate button
              if (widget.listing?.preferredRate != null) ...[
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _rateController.text =
                          _fmtRate(widget.listing!.preferredRate!);
                      _amountController.text =
                          widget.listing!.amount.toString();
                    });
                  },
                  icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                  label: Text(
                      'Fill Requester\'s Rate (${_fmtRate(widget.listing!.preferredRate!)})'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: BorderSide(
                        color: AppColors.accent.withValues(alpha: 0.5)),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Rate label + ⓘ
              Row(
                children: [
                  Text(
                    l10n?.rateOfferedLabel ?? 'Rate offered',
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        icon: const Icon(Icons.currency_exchange_rounded,
                            color: AppColors.accent),
                        title: const Text('Exchange Rate'),
                        content: const Text(
                          'How much of the needed currency you offer per unit of the held currency.\n\n'
                          'Example: Requester holds UGX, needs USD. '
                          'A rate of 0.00027 means 1 UGX = 0.00027 USD.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Got it'),
                          ),
                        ],
                      ),
                    ),
                    child: const Icon(Icons.info_outline_rounded,
                        size: 14, color: AppColors.accent),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Rate field
              TextField(
                controller: _rateController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: '0.0000',
                  prefixIcon:
                      const Icon(Icons.currency_exchange_rounded, size: 18),
                  suffix: _stepperSuffix(
                    onMinus: () => _adjustRate(-1),
                    onPlus: () => _adjustRate(1),
                  ),
                ),
              ),

              // Rate slider
              _buildRateSlider(context),
              const SizedBox(height: 4),

              // Slider range labels
              if (widget.listing?.preferredRate != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_fmtRate(_rateSliderMin),
                        style: Theme.of(context).textTheme.bodySmall),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Preferred: ${_fmtRate(widget.listing!.preferredRate!)}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.accent),
                      ),
                    ),
                    Text(_fmtRate(_rateSliderMax),
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              const SizedBox(height: 14),

              // Amount label
              Text(
                l10n?.amountAvailableLabel ?? 'Amount you can give',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),

              // Amount field
              TextField(
                controller: _amountController,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '0',
                  prefixText: '${widget.listing?.currencyHeld ?? ''} ',
                  suffix: _stepperSuffix(
                    onMinus: () => _adjustAmount(-10000),
                    onPlus: () => _adjustAmount(10000),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildAmountPresets(context),
              const SizedBox(height: 14),

              // Live calc panel
              _buildLiveCalcPanel(context),
              const SizedBox(height: 14),

              // Settlement terms
              TextField(
                controller: _termsController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText:
                      l10n?.settlementTermsLabel ?? 'Settlement terms',
                  hintText:
                      'e.g. Cash in person, Kampala CBD, Monday 9am–5pm',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),

              // Preview button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed:
                      (_submitting || !_isFormReady) ? null : _showPreview,
                  icon: _submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.visibility_rounded, size: 18),
                  label: Text(
                    _submitting ? 'Sending…' : 'Preview Offer',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Data holder ───────────────────────────────────────────────────────────────

class _ForexDetailData {
  const _ForexDetailData({required this.listing, required this.offers});

  final ForexListingModel listing;
  final List<ForexOfferModel> offers;
}
