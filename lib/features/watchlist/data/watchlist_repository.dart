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
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final data = await _client
        .from('watchlist')
        .select('request_id, forex_request_id, needs_request_id')
        .eq('user_id', userId);
    return (data as List)
        .expand((row) => [
              row['request_id'],
              row['forex_request_id'],
              row['needs_request_id'],
            ])
        .whereType<String>()
        .toList();
  }

  /// Get watched listings with full details.
  Future<List<MarketplaceItem>> getWatchedListings() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final watchlistData = await _client
        .from('watchlist')
        .select('request_id, forex_request_id, needs_request_id')
        .eq('user_id', userId);

    final loanIds = _idsFor(watchlistData, 'request_id');
    final forexIds = _idsFor(watchlistData, 'forex_request_id');
    final needsIds = _idsFor(watchlistData, 'needs_request_id');
    if (loanIds.isEmpty && forexIds.isEmpty && needsIds.isEmpty) return [];

    final listings = <MarketplaceItem>[];
    for (final requestId in loanIds) {
      final data = await _client
          .from('v_loan_listings')
          .select()
          .eq('request_id', requestId)
          .maybeSingle();
      if (data != null) {
        listings.add(MarketplaceItem.loan(LoanListing.fromMap(data)));
      }
    }
    for (final requestId in forexIds) {
      final data = await _client
          .from('v_forex_listings')
          .select()
          .eq('request_id', requestId)
          .maybeSingle();
      if (data != null) {
        listings.add(MarketplaceItem.forex(ForexListingModel.fromMap(data)));
      }
    }
    for (final requestId in needsIds) {
      final data = await _client
          .from('v_needs_listings')
          .select()
          .eq('request_id', requestId)
          .maybeSingle();
      if (data != null) {
        listings.add(MarketplaceItem.needs(NeedsListing.fromMap(data)));
      }
    }

    listings.sort((a, b) => b.listedAt.compareTo(a.listedAt));
    return listings;
  }

  List<String> _idsFor(List<dynamic> rows, String column) =>
      rows.map((row) => row[column] as String?).whereType<String>().toList();

  /// Emits when the user's watchlist rows change.
  Stream<void> watchWatchlistChanges() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return const Stream.empty();
    }

    return _client
        .from('watchlist')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map<void>((_) {});
  }

  Future<void> add(
    String requestId, {
    MarketplaceModule module = MarketplaceModule.loan,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Sign in before changing the watchlist.');
    }
    await _client.from('watchlist').upsert({
      'user_id': userId,
      _targetColumn(module): requestId,
    }, onConflict: 'user_id,${_targetColumn(module)}');
  }

  Future<void> remove(
    String requestId, {
    MarketplaceModule module = MarketplaceModule.loan,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Sign in before changing the watchlist.');
    }
    final query = _client.from('watchlist').delete().eq('user_id', userId);
    await query.eq(_targetColumn(module), requestId);
  }

  String _targetColumn(MarketplaceModule module) {
    return switch (module) {
      MarketplaceModule.loan => 'request_id',
      MarketplaceModule.forex => 'forex_request_id',
      MarketplaceModule.needs => 'needs_request_id',
    };
  }
}
