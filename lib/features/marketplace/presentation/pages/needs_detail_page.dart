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
        return Scaffold(
          appBar: AppBar(title: const Text('Need details')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(need.category.toUpperCase(),
                  style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Text(need.title,
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(need.specification),
              const SizedBox(height: 24),
              _DetailRow(label: 'Budget', value: _budget(need)),
              _DetailRow(label: 'Location', value: need.location),
              _DetailRow(label: 'Urgency', value: need.urgency),
              if (need.trustIsVerified)
                const _DetailRow(label: 'Trust', value: 'Verified requester'),
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 92, child: Text(label)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
