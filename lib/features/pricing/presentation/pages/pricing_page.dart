// lib/features/pricing/presentation/pages/pricing_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/country_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/domain/models/nipanze_user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

import '../../data/subscription_price_repository.dart';
import '../cubit/subscription_price_cubit.dart';
import '../widgets/flutterwave_checkout_sheet.dart';

/// The single place where marketplace capability and subscription prices are explained.
class PricingPage extends StatelessWidget {
  const PricingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    final current = state is AuthAuthenticated
        ? state.user.subscriptionPlan
        : SubscriptionPlan.free;

    final phone = state is AuthAuthenticated ? state.user.phone : null;
    final country = EastAfricaCountries.findByPhone(phone);

    return BlocProvider<SubscriptionPriceCubit>(
      create: (_) =>
          getIt<SubscriptionPriceCubit>()..load(country.code),
      child: _PricingPageBody(
        country: country,
        current: current,
      ),
    );
  }
}

class _PricingPageBody extends StatelessWidget {
  const _PricingPageBody({
    required this.country,
    required this.current,
  });

  final EastAfricaCountry country;
  final SubscriptionPlan current;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.plansAndPricing ?? 'Plans & pricing'),
      ),
      body: BlocBuilder<SubscriptionPriceCubit, SubscriptionPriceState>(
        builder: (context, priceState) {
          // Resolve effective prices: DB > fallback
          final SubscriptionPriceData prices = switch (priceState) {
            SubscriptionPriceLoaded(:final data) => data,
            SubscriptionPriceError(:final fallback) => fallback,
            _ => SubscriptionPriceData.fromCountryInfo(country),
          };
          final isLoading = priceState is SubscriptionPriceLoading ||
              priceState is SubscriptionPriceInitial;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n?.chooseAccessTitle ?? 'Choose the access you need',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n?.chooseAccessSubtitle(country.flag, country.name) ??
                              'Prices match your account region (${country.flag} ${country.name}).',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.bg2Dark,
                      border: Border.all(
                          color: AppColors.borderDark.withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(country.flag,
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          country.currency,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Free plan ──────────────────────────────────────────────────
              _PlanCard(
                plan: SubscriptionPlan.free,
                price: 'Free',
                subtitle: l10n?.freePlanSubtitle ??
                    'Browse, watch listings, post basic requests, and accept offers.',
                features: [
                  l10n?.freeFeature1 ?? 'Browse the marketplace',
                  l10n?.freeFeature2 ?? 'Post basic loan requests',
                  l10n?.freeFeature3 ?? 'Accept offers received',
                ],
                current: current,
                onChoose: () => _choosePlan(context, SubscriptionPlan.free,
                    country, prices),
              ),
              const SizedBox(height: 12),

              // ── Lender plan ────────────────────────────────────────────────
              _PlanCard(
                plan: SubscriptionPlan.lender,
                price: isLoading
                    ? '…'
                    : '${prices.lenderAmountFormatted}${l10n?.perMonth ?? ' / month'}',
                subtitle: l10n?.lenderTierDesc ??
                    'For anyone ready to make structured offers and earn returns on Nipanze.',
                features: [
                  l10n?.everythingInFree ?? 'Everything in Free',
                  l10n?.lenderFeature1 ??
                      'Make offers with full terms (rate, fee, schedule)',
                  l10n?.lenderFeature2 ??
                      'See offer detail where you participate',
                ],
                current: current,
                onChoose: () => _choosePlan(context, SubscriptionPlan.lender,
                    country, prices),
              ),
              const SizedBox(height: 12),

              // ── Pro plan ───────────────────────────────────────────────────
              _PlanCard(
                plan: SubscriptionPlan.pro,
                price: isLoading
                    ? '…'
                    : '${prices.proAmountFormatted}${l10n?.perMonth ?? ' / month'}',
                subtitle: l10n?.proTierDesc ??
                    'Full marketplace access, advanced filters and strong request positioning.',
                features: [
                  l10n?.everythingInLender ?? 'Everything in Lender',
                  l10n?.proFeature1 ??
                      'Suggest rates, late fees and repayment terms',
                  l10n?.proFeature2 ??
                      'Advanced filters (income, employment, verified)',
                  l10n?.proFeature3 ??
                      'Verified badge, reliability score and priority visibility',
                ],
                current: current,
                onChoose: () =>
                    _choosePlan(context, SubscriptionPlan.pro, country, prices),
                highlighted: true,
              ),
              const SizedBox(height: 24),

              Text(
                l10n?.paymentSecurityDisclaimer ??
                    'Nipanze does not hold or move funds. Subscription changes are confirmed through a secure payment flow.',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 11, color: AppColors.text3Dark),
              ),
            ],
          );
        },
      ),
    );
  }

  void _choosePlan(
    BuildContext context,
    SubscriptionPlan plan,
    EastAfricaCountry country,
    SubscriptionPriceData prices,
  ) {
    if (plan == SubscriptionPlan.free) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          l10n?.planSelectedMessage(_label(plan)) ??
              'Selected: ${_label(plan)}',
        ),
      ));
      return;
    }

    final priceFormatted = plan == SubscriptionPlan.lender
        ? '${prices.lenderAmountFormatted} / month'
        : '${prices.proAmountFormatted} / month';

    final priceMinorUnits = plan == SubscriptionPlan.lender
        ? prices.lenderMinorUnits
        : prices.proMinorUnits;

    FlutterwaveCheckoutSheet.show(
      context,
      plan: plan,
      priceFormatted: priceFormatted,
      country: country,
      priceMinorUnits: priceMinorUnits,
    );
  }

  static bool _isUpgrade(SubscriptionPlan from, SubscriptionPlan to) =>
      to.index > from.index;

  static String _label(SubscriptionPlan plan) => switch (plan) {
        SubscriptionPlan.free => 'Free',
        SubscriptionPlan.lender => 'Lender',
        SubscriptionPlan.pro => 'Pro',
      };
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.price,
    required this.subtitle,
    required this.features,
    required this.current,
    required this.onChoose,
    this.highlighted = false,
  });

  final SubscriptionPlan plan;
  final SubscriptionPlan current;
  final String price;
  final String subtitle;
  final List<String> features;
  final VoidCallback onChoose;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isCurrent = plan == current;
    final color = plan == SubscriptionPlan.pro
        ? AppColors.purple
        : plan == SubscriptionPlan.lender
            ? AppColors.accent
            : AppColors.success;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: color.withValues(alpha: highlighted ? .8 : .25),
          width: highlighted ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _PricingPageBody._label(plan),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                if (isCurrent)
                  Chip(label: Text(l10n?.currentPlan ?? 'Current plan')),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              price,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 5),
            Text(subtitle),
            const SizedBox(height: 12),
            ...features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 16, color: color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feature,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                )),
            if (_PricingPageBody._isUpgrade(current, plan)) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: onChoose,
                  child: Text(
                    plan == SubscriptionPlan.free
                        ? (l10n?.useFree ?? 'Use Free')
                        : (l10n?.choosePlan(_PricingPageBody._label(plan)) ??
                            'Choose ${_PricingPageBody._label(plan)}'),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
