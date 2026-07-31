import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../shared/models/forex_listing_model.dart';
import '../../data/forex_repository.dart';

class MyForexRequestsPage extends StatelessWidget {
  const MyForexRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My forex requests')),
      body: FutureBuilder<List<ForexListingModel>>(
        future: getIt<ForexRepository>().getMyForexRequests(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final requests = snapshot.data!;
          if (requests.isEmpty) {
            return const Center(child: Text('No forex requests yet.'));
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
