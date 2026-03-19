// ignore_for_file: directives_ordering, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/loan_listing_model.dart';
import '../cubit/marketplace_cubit.dart';

class MarketplacePage extends StatelessWidget {
  const MarketplacePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MarketplaceCubit(repository: getIt())..watch(),
      child: const _MarketplaceView(),
    );
  }
}

class _MarketplaceView extends StatelessWidget {
  const _MarketplaceView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: BlocBuilder<MarketplaceCubit, MarketplaceState>(
        builder: (ctx, state) {
          if (state is MarketplaceLoading || state is MarketplaceInitial) {
            return _Shimmer();
          }
          if (state is MarketplaceError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => ctx.read<MarketplaceCubit>().watch(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is MarketplaceLoaded) {
            final listings = state.display;
            if (listings.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off_rounded, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No loan requests found'),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: listings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _LoanCard(listing: listings[i]),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => BlocProvider.value(
        value: context.read<MarketplaceCubit>(),
        child: const _FilterSheet(),
      ),
    );
  }
}

class _LoanCard extends StatelessWidget {
  const _LoanCard({required this.listing});
  final LoanListingModel listing;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'en_UG');

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(Routes.loanDetailPath(listing.requestId)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      listing.purpose,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _RiskBadge(riskCategory: listing.riskCategory),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(listing.district ?? 'Uganda',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(width: 16),
                  const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${listing.durationMonths} months',
                      style: Theme.of(context).textTheme.bodySmall),
                  if (listing.maxInterestRate != null) ...[
                    const SizedBox(width: 16),
                    const Icon(Icons.percent_rounded, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('≤ ${listing.maxInterestRate!.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('UGX ${fmt.format(listing.requestedAmount)}',
                          style:
                              Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  )),
                      Text('${listing.numberOfBids} bid${listing.numberOfBids == 1 ? '' : 's'}',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LinearPercentIndicator(
                percent: listing.fundingPercentage / 100,
                lineHeight: 6,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                progressColor: AppColors.primary,
                barRadius: const Radius.circular(8),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: 4),
              Text('${listing.fundingPercentage.toStringAsFixed(0)}% funded',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                      )),
            ],
          ),
        ),
      ),
    );
  }
}

class _RiskBadge extends StatelessWidget {
  const _RiskBadge({this.riskCategory});
  final String? riskCategory;

  Color get _color => switch (riskCategory) {
        'low' => AppColors.success,
        'medium' => AppColors.warning,
        'high' => AppColors.error,
        'very_high' => const Color(0xFF7F1D1D),
        _ => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    if (riskCategory == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        riskCategory!.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet();

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String? _risk;
  double _maxRate = 30;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filter Loans', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          Text('Risk Category', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['low', 'medium', 'high', 'very_high'].map((r) {
              return ChoiceChip(
                label: Text(r.replaceAll('_', ' ')),
                selected: _risk == r,
                onSelected: (_) => setState(
                    () => _risk = _risk == r ? null : r),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Max Interest Rate', style: Theme.of(context).textTheme.labelLarge),
              Text('${_maxRate.toStringAsFixed(0)}%'),
            ],
          ),
          Slider(
            value: _maxRate,
            min: 5,
            max: 30,
            divisions: 25,
            onChanged: (v) => setState(() => _maxRate = v),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    context.read<MarketplaceCubit>().clearFilters();
                    Navigator.pop(context);
                  },
                  child: const Text('Clear'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    context.read<MarketplaceCubit>().applyFilters(
                          riskCategory: _risk,
                          maxRate: _maxRate,
                        );
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Shimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: 130,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
