// lib/features/watchlist/data/watchlist_repository.dart
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/forex_listing_model.dart';
import '../../marketplace/domain/models/loan_listing.dart';
import '../../marketplace/domain/models/marketplace_item.dart';

@lazySingleton
class WatchlistRepository {
  WatchlistRepository(this._client);

  final SupabaseClient _client;

  Future<List<String>> getWatchlist() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];
      final data = await _client
          .from('watchlist')
          .select('request_id, forex_request_id')
          .eq('user_id', userId);
      return (data as List)
          .map((e) => (e['request_id'] ?? e['forex_request_id']) as String?)
          .whereType<String>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Get watched listings with full details.
  Future<List<MarketplaceItem>> getWatchedListings() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      // Fetch watched request IDs
      final watchlistData = await _client
          .from('watchlist')
          .select('request_id, forex_request_id')
          .eq('user_id', userId);

      final requestIds = (watchlistData as List)
          .map((e) => e['request_id'] as String?)
          .whereType<String>()
          .toList();
      final forexRequestIds = watchlistData
          .map((e) => e['forex_request_id'] as String?)
          .whereType<String>()
          .toList();

      if (requestIds.isEmpty && forexRequestIds.isEmpty) return [];

      // Fetch full listing details from v_loan_listings for each watched request
      final listings = <MarketplaceItem>[];
      for (final requestId in requestIds) {
        try {
          final data = await _client
              .from('v_loan_listings')
              .select()
              .eq('request_id', requestId)
              .single();
          listings.add(MarketplaceItem.loan(LoanListing.fromMap(data)));
        } catch (_) {
          // If a listing doesn't exist or is deleted, skip silently
        }
      }
      for (final requestId in forexRequestIds) {
        try {
          final data = await _client
              .from('v_forex_listings')
              .select()
              .eq('request_id', requestId)
              .single();
          listings.add(MarketplaceItem.forex(ForexListingModel.fromMap(data)));
        } catch (_) {}
      }

      // Sort by listed_at descending
      listings.sort((a, b) => b.listedAt.compareTo(a.listedAt));
      return listings;
    } catch (_) {
      return [];
    }
  }

  /// Watch for changes to watched listings.
  /// Polls for updates by refetching when watchlist table changes.
  Stream<List<MarketplaceItem>> watchWatchedListings() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return const Stream.empty();
    }

    // Subscribe to watchlist changes and refetch listings
    return _client
        .from('watchlist')
        .stream(primaryKey: ['user_id', 'request_id'])
        .eq('user_id', userId)
        .asyncMap((_) => getWatchedListings());
  }

  Future<void> add(String requestId, {bool forex = false}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client.from('watchlist').upsert({
      'user_id': userId,
      if (forex) 'forex_request_id': requestId else 'request_id': requestId,
    });
  }

  Future<void> remove(String requestId, {bool forex = false}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    var query = _client.from('watchlist').delete().eq('user_id', userId);
    query = forex
        ? query.eq('forex_request_id', requestId)
        : query.eq('request_id', requestId);
    await query;
  }
}
