// lib/features/watchlist/data/watchlist_repository.dart
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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