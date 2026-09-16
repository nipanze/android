import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';

@lazySingleton
class NeedsRepository {
  NeedsRepository(this._client);

  final SupabaseClient _client;

  String get _uid => _client.auth.currentUser!.id;

  Future<String> createRequest({
    required String title,
    required String specification,
    required String category,
    required int budget,
    required String currency,
    required String location,
    required String urgency,
    required String country,
  }) async {
    try {
      final data = await _client
          .from(TableNames.needsRequests)
          .insert({
            'requester_id': _uid,
            'title': title.trim(),
            'specification': specification.trim(),
            'category': category,
            'budget': budget,
            'currency': currency,
            'location': location.trim(),
            'urgency': urgency,
            'country': country,
          })
          .select('request_id')
          .single();

      return data['request_id'] as String;
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }
}
