import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/marketplace_repository.dart';
import '../../domain/models/marketplace_item.dart';

class NeedsDetailPage extends StatelessWidget {
  const NeedsDetailPage({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<NeedsListing>(
      future: getIt<MarketplaceRepository>().getNeedsDetail(requestId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          if (snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text('Unable to load this Need.')),
            );
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final need = snapshot.data!;
        final theme = Theme.of(context);
        final detailSurface = theme.brightness == Brightness.dark
            ? AppColors.bg2Dark
            : theme.colorScheme.surface;
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            title: const Text('Need details'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 32),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                decoration: BoxDecoration(
                  color: detailSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            need.category.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.warning,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        _UrgencyBadge(urgency: need.urgency),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      need.title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _budget(need),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppColors.warning,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 18,
                      runSpacing: 12,
                      children: [
                        _NeedFact(
                          icon: Icons.location_on_rounded,
                          label: 'Location',
                          value: need.location,
                        ),
                        _NeedFact(
                          icon: Icons.priority_high_rounded,
                          label: 'Urgency',
                          value: need.urgency,
                        ),
                        if (need.trustIsVerified)
                          const _NeedFact(
                            icon: Icons.verified_user_rounded,
                            label: 'Trust',
                            value: 'Verified requester',
                          ),
                      ],
                    ),
                    if (need.specification.trim().isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'ABOUT THE NEED',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        need.specification,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _budget(NeedsListing need) => need.budget > 0
      ? '${need.currency} ${need.budget}'
      : 'Open to suitable proposals';
}

class _UrgencyBadge extends StatelessWidget {
  const _UrgencyBadge({required this.urgency});

  final String urgency;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time_rounded,
              size: 11, color: AppColors.warning),
          const SizedBox(width: 4),
          Text(
            urgency,
            style: const TextStyle(
              color: AppColors.warning,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _NeedFact extends StatelessWidget {
  const _NeedFact({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 145,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accent, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.55),
                        )),
                const SizedBox(height: 2),
                Text(value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
