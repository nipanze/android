import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/app_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/forex_listing_model.dart';
import '../../data/forex_repository.dart';

class MyForexRequestsPage extends StatelessWidget {
  const MyForexRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
          ),
          onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.marketplace),
        ),
        title: Text(l10n?.myForexRequestsTitle ?? 'My forex requests'),
      ),
      body: FutureBuilder<List<ForexListingModel>>(
        future: getIt<ForexRepository>().getMyForexRequests(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final requests = snapshot.data!;
          if (requests.isEmpty) {
            return Center(
              child: Text(
                l10n?.noForexRequestsYet ?? 'No forex requests yet.',
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final request = requests[index];
              return ListTile(
                title: Text(
                  '${request.currencyHeld} to ${request.currencyNeeded}',
                ),
                subtitle: Text(
                  '${request.amount} · ${request.settlementPreference}',
                ),
                trailing: Text(request.status),
                onTap: () => context.push('/forex/${request.requestId}'),
              );
            },
          );
        },
      ),
    );
  }
}
