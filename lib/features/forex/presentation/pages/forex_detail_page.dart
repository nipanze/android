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
import '../../../auth/domain/models/nipanze_user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/forex_repository.dart';

class ForexDetailPage extends StatefulWidget {
  const ForexDetailPage({super.key, required this.requestId});

  final String requestId;

  @override
  State<ForexDetailPage> createState() => _ForexDetailPageState();
}

class _ForexDetailPageState extends State<ForexDetailPage> {
  late Future<_ForexDetailData> _future;

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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
          ),
          onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.marketplace),
        ),
        title: Text(AppLocalizations.of(context)?.forexRequestTitle ?? 'Forex request'),
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
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SendRateReceivePanel(
                    listing: data.listing,
                    showBorder: false,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  data.listing.settlementPreference,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TrustBadgeRow(
                  ratingAvg: data.listing.trustRatingAvg,
                  reviewCount: data.listing.trustReviewCount,
                  completedDealsCount: data.listing.trustCompletedDealsCount,
                  isRepeatParticipant: data.listing.trustIsRepeatParticipant,
                  phoneVerified: data.listing.trustPhoneVerified,
                  responseTimeBucket: data.listing.trustResponseTimeBucket,
                ),
                const SizedBox(height: 18),
                _OffersPanel(
                  listing: data.listing,
                  offers: data.offers,
                  onChanged: _refresh,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OffersPanel extends StatelessWidget {
  const _OffersPanel({
    required this.listing,
    required this.offers,
    required this.onChanged,
  });

  final ForexListingModel listing;
  final List<ForexOfferModel> offers;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final canOffer = authState is AuthAuthenticated && authState.user.canLend;
    final canSeeProfessionalTags = authState is AuthAuthenticated &&
        authState.user.subscriptionPlan == SubscriptionPlan.pro;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Offers', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            Text(
              '${listing.numberOfOffers} · ${listing.rateCoverageTier ?? 'low'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (offers.isEmpty)
          Text(
            'Exact rates are visible only to the request owner and participants.',
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          ...offers.map(
            (offer) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Row(
                children: [
                  Expanded(
                    child: Text('Rate ${offer.rateOffered.toStringAsFixed(4)}'),
                  ),
                  if (canSeeProfessionalTags &&
                      offer.professionalTag != null) ...[
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
          ),
        const SizedBox(height: 18),
        if (canOffer)
          _MakeOfferForm(requestId: listing.requestId, onChanged: onChanged)
        else
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.lock_outline_rounded),
            label: const Text('Lender or Pro required to make offers'),
          ),
      ],
    );
  }
}

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

class _MakeOfferForm extends StatefulWidget {
  const _MakeOfferForm({required this.requestId, required this.onChanged});

  final String requestId;
  final VoidCallback onChanged;

  @override
  State<_MakeOfferForm> createState() => _MakeOfferFormState();
}

class _MakeOfferFormState extends State<_MakeOfferForm> {
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
      widget.onChanged();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(e is AppException ? e.message : 'Could not send offer.'),
          backgroundColor: AppColors.warning,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _rateController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Rate offered'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _amountController,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Amount available'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _termsController,
          decoration: const InputDecoration(labelText: 'Settlement terms'),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submit,
            child: const Text('Make an offer'),
          ),
        ),
      ],
    );
  }
}

class _ForexDetailData {
  const _ForexDetailData({required this.listing, required this.offers});

  final ForexListingModel listing;
  final List<ForexOfferModel> offers;
}
