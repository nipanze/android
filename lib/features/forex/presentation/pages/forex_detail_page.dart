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
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../../shared/widgets/trust_badges.dart';
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

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ForexDetailData> _load() async {
    final repo = getIt<ForexRepository>();
    final listing = await repo.getRequestDetail(widget.requestId);
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
    // ForexListingModel does not carry ownerId — offer button is always shown
    // to non-anonymous users; access is gated by canLend check below.

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
          ),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.marketplace),
        ),
        title: Text(l10n?.forexRequestTitle ?? 'Forex request'),
      ),
      body: FutureBuilder<_ForexDetailData>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            }
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          final listing = data.listing;

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
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (listing.isUrgent) ...[
                          const Row(
                            children: [
                              UrgentBadge(),
                              Spacer(),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                        // Send → Rate → Receive panel
                        SendRateReceivePanel(
                          listing: listing,
                          showBorder: false,
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
              onClose: () => setState(() => _showOfferSheet = false),
              onOfferPlaced: () {
                setState(() => _showOfferSheet = false);
                _refresh();
              },
            )
          : null,
    );
  }
}

// ── Offers section ────────────────────────────────────────────────────────────

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
      children: offers
          .map(
            (offer) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Row(
                children: [
                  Expanded(
                    child: Text('Rate ${offer.rateOffered.toStringAsFixed(4)}'),
                  ),
                  if (canSeePro && offer.professionalTag != null) ...[
                    const SizedBox(width: 8),
                    _ProfessionalTag(offer.professionalTag!),
                  ],
                ],
              ),
              subtitle: Text(
                'Available ${listing.currencyHeld} ${offer.amountAvailable}',
              ),
              trailing: Text(offer.status),
            ),
          )
          .toList(),
    );
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
    required this.onClose,
    required this.onOfferPlaced,
  });

  final String requestId;
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

  @override
  void dispose() {
    _rateController.dispose();
    _amountController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final rate = double.tryParse(_rateController.text);
    final amount = int.tryParse(_amountController.text);
    if (rate == null || amount == null || rate <= 0 || amount <= 0) return;
    setState(() => _submitting = true);
    try {
      await getIt<ForexRepository>().makeOffer(
        requestId: widget.requestId,
        rateOffered: rate,
        amountAvailable: amount,
        terms: _termsController.text.trim(),
      );
      widget.onOfferPlaced();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is AppException ? e.message : (l10n?.couldNotSendOffer ?? 'Could not send offer.'),
          ),
          backgroundColor: AppColors.warning,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  l10n?.makeAnOffer ?? 'Make an offer',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: widget.onClose,
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _rateController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l10n?.rateOfferedLabel ?? 'Rate offered',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _amountController,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n?.amountAvailableLabel ?? 'Amount available',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _termsController,
              decoration: InputDecoration(
                labelText: l10n?.settlementTermsLabel ?? 'Settlement terms',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n?.makeAnOffer ?? 'Make an offer'),
            ),
          ],
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
