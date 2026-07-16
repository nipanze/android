import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/models/nipanze_user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

/// The single place where marketplace capability and subscription prices are
/// explained. Payment collection is intentionally not performed in Flutter;
/// a server-side payment flow can be attached to [_choosePlan].
class PricingPage extends StatelessWidget {
  const PricingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    final current = state is AuthAuthenticated
        ? state.user.subscriptionPlan
        : SubscriptionPlan.free;

    return Scaffold(
      appBar: AppBar(title: const Text('Plans & pricing')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Choose the access you need',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
              'One account can post requests and make offers. Your plan only unlocks capabilities.',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 20),
          _PlanCard(
            plan: SubscriptionPlan.free,
            price: 'Free',
            subtitle:
                'Browse, watch listings, post basic requests, and accept offers.',
            features: const [
              'Browse the marketplace',
              'Post basic loan requests',
              'Accept offers received'
            ],
            current: current,
            onChoose: () => _choosePlan(context, SubscriptionPlan.free),
          ),
          const SizedBox(height: 12),
          _PlanCard(
            plan: SubscriptionPlan.lender,
            price: 'UGX 35,000 / month',
            subtitle: 'For anyone ready to make structured offers.',
            features: const [
              'Everything in Free',
              'Make offers with full terms',
              'See offer detail where you participate'
            ],
            current: current,
            onChoose: () => _choosePlan(context, SubscriptionPlan.lender),
          ),
          const SizedBox(height: 12),
          _PlanCard(
            plan: SubscriptionPlan.pro,
            price: 'UGX 150,000 / month',
            subtitle:
                'Full marketplace access and stronger request positioning.',
            features: const [
              'Everything in Lender',
              'Suggest rates, late fees and repayment terms',
              'Priority visibility and improved matching'
            ],
            current: current,
            onChoose: () => _choosePlan(context, SubscriptionPlan.pro),
            highlighted: true,
          ),
          const SizedBox(height: 20),
          const Text(
              'Nipanze does not hold or move funds. Subscription changes are confirmed through a secure payment flow.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.text3Dark)),
        ],
      ),
    );
  }

  void _choosePlan(BuildContext context, SubscriptionPlan plan) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          '${_label(plan)} selected. Secure payment activation will be available shortly.'),
    ));
  }

  static String _label(SubscriptionPlan plan) => switch (plan) {
        SubscriptionPlan.free => 'Free',
        SubscriptionPlan.lender => 'Lender',
        SubscriptionPlan.pro => 'Pro',
      };
}

class _PlanCard extends StatelessWidget {
  const _PlanCard(
      {required this.plan,
      required this.price,
      required this.subtitle,
      required this.features,
      required this.current,
      required this.onChoose,
      this.highlighted = false});
  final SubscriptionPlan plan, current;
  final String price, subtitle;
  final List<String> features;
  final VoidCallback onChoose;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
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
              width: highlighted ? 1.5 : 1)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(PricingPage._label(plan),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: color)),
            const Spacer(),
            if (isCurrent) const Chip(label: Text('Current plan')),
          ]),
          const SizedBox(height: 6),
          Text(price,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text(subtitle),
          const SizedBox(height: 12),
          ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  Icon(Icons.check_circle_outline, size: 16, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                      child:
                          Text(feature, style: const TextStyle(fontSize: 12)))
                ]),
              )),
          if (!isCurrent) ...[
            const SizedBox(height: 8),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: onChoose,
                    child: Text(plan == SubscriptionPlan.free
                        ? 'Use Free'
                        : 'Choose ${PricingPage._label(plan)}'))),
          ],
        ]),
      ),
    );
  }
}
