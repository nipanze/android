// lib/features/watchlist/data/watchlist_repository.dart
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../marketplace/domain/models/loan_listing.dart';

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
          .select('request_id')
          .eq('user_id', userId);
      return (data as List)
          .map((e) => e['request_id'] as String)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Get watched listings with full details.
  Future<List<LoanListing>> getWatchedListings() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      // Fetch watched request IDs
      final watchlistData = await _client
          .from('watchlist')
          .select('request_id')
          .eq('user_id', userId);

      final requestIds =
          (watchlistData as List).map((e) => e['request_id'] as String).toList();

      if (requestIds.isEmpty) return [];

      // Fetch full listing details from v_loan_listings for each watched request
      final listings = <LoanListing>[];
      for (final requestId in requestIds) {
        try {
          final data = await _client
              .from('v_loan_listings')
              .select()
              .eq('request_id', requestId)
              .single();
          listings.add(LoanListing.fromMap(data));
        } catch (_) {
          // If a listing doesn't exist or is deleted, skip silently
        }
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
  Stream<List<LoanListing>> watchWatchedListings() {
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

  Future<void> add(String requestId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client.from('watchlist').upsert({
      'user_id': userId,
      'request_id': requestId,
    });
  }

  Future<void> remove(String requestId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client
        .from('watchlist')
        .delete()
        .eq('user_id', userId)
        .eq('request_id', requestId);
  }
}