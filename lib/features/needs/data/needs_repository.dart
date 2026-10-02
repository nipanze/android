import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../marketplace/domain/models/marketplace_item.dart';
import '../domain/models/need_capability.dart';
import '../domain/models/need_category.dart';
import '../domain/models/need_offer.dart';

@lazySingleton
class NeedsRepository {
  NeedsRepository(this._client);

  final SupabaseClient _client;

  String? get currentViewerId => _client.auth.currentUser?.id;
  String get _uid => _client.auth.currentUser!.id;

  Future<String?> _getCountryCode() async {
    final uid = currentViewerId;
    if (uid == null) return null;
    try {
      final profile = await _client
          .from(TableNames.profiles)
          .select('country')
          .eq('id', uid)
          .maybeSingle();
      return profile?['country'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Fetch active categories
  Future<List<NeedCategory>> getCategories() async {
    try {
      final countryCode = await _getCountryCode();
      final data = await _client
          .from(TableNames.needCategories)
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      return (data as List)
          .map((e) => NeedCategory.fromMap(e, countryCode: countryCode))
          .toList();
    } catch (_) {
      return NeedCategory.defaultCategories;
    }
  }

  /// Fetch capabilities for a category
  Future<List<NeedCapability>> getCapabilities({String? categorySlug}) async {
    try {
      final countryCode = await _getCountryCode();
      var query = _client.from(TableNames.needCapabilities).select();
      if (categorySlug != null) {
        query = query.eq('category_slug', categorySlug) as dynamic;
      }
      final data = await (query as PostgrestFilterBuilder)
          .eq('is_active', true)
          .order('name', ascending: true);

      return (data as List)
          .map((e) => NeedCapability.fromMap(e, countryCode: countryCode))
          .toList();
    } catch (_) {
      if (categorySlug != null) {
        return NeedCapability.defaults
            .where((c) => c.categorySlug == categorySlug)
            .toList();
      }
      return NeedCapability.defaults;
    }
  }

  /// Create a need request
  Future<String> createRequest({
    required String title,
    required String specification,
    required String categorySlug,
    required String categoryName,
    String? capabilitySlug,
    Map<String, dynamic> details = const {},
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
            'category_slug': categorySlug,
            'category': categoryName,
            if (capabilitySlug != null) 'capability_slug': capabilitySlug,
            'details': details,
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

  /// Get public or private offers for a need request
  Future<List<NeedOffer>> getOffers(String needId) async {
    try {
      final data = await _client.rpc(
        RpcNames.getPublicNeedOffers,
        params: {'p_need_id': needId},
      );

      return (data as List).map((e) => NeedOffer.fromMap(e)).toList();
    } catch (e) {
      return const [];
    }
  }

  /// Place an offer on a Need request
  Future<String> makeOffer({
    required String needId,
    required int price,
    required String currency,
    required String timelineText,
    required String message,
  }) async {
    try {
      final data = await _client
          .from(TableNames.needOffers)
          .insert({
            'need_id': needId,
            'offer_maker_id': _uid,
            'price': price,
            'currency': currency,
            'timeline_text': timelineText.trim(),
            'message': message.trim(),
          })
          .select('id')
          .single();

      return data['id'] as String;
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  /// Accept an offer on a Need request
  Future<String> acceptOffer({
    required String needId,
    required String offerId,
  }) async {
    try {
      final result = await _client.rpc(
        RpcNames.acceptNeedOffer,
        params: {
          'p_need_id': needId,
          'p_offer_id': offerId,
        },
      );
      return result as String;
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  /// Unlock contact details for an accepted offer
  Future<String> unlockContact({required String offerId}) async {
    try {
      final result = await _client.rpc(
        RpcNames.unlockNeedContact,
        params: {'p_offer_id': offerId},
      );
      return result as String;
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  /// Check user provider capabilities
  Future<List<String>> getUserCapabilities() async {
    try {
      final userId = currentViewerId;
      if (userId == null) return const [];
      final data = await _client
          .from(TableNames.providerCapabilities)
          .select('capability_slug')
          .eq('user_id', userId);

      return (data as List).map((e) => e['capability_slug'] as String).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Add a self-declared capability
  Future<void> addCapability(String capabilitySlug) async {
    try {
      await _client.from(TableNames.providerCapabilities).upsert({
        'user_id': _uid,
        'capability_slug': capabilitySlug,
        'verification_level': 'self_declared',
      });
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  /// Get personalized 'For You' needs
  Future<List<NeedsListing>> getForYouNeeds(
      {String country = 'UG', int limit = 10}) async {
    try {
      final data = await _client.rpc(
        RpcNames.getForYouNeeds,
        params: {'p_country': country, 'p_limit': limit},
      );
      return (data as List)
          .map((e) => NeedsListing.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      try {
        final fallback = await _client
            .from('v_needs_listings')
            .select()
            .order('listed_at', ascending: false)
            .limit(limit);
        return (fallback as List)
            .map((e) => NeedsListing.fromMap(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        return const [];
      }
    }
  }

  /// Record interest event for personalization
  Future<void> recordInterestEvent(String categorySlug, String event) async {
    try {
      if (currentViewerId == null) return;
      await _client.rpc(
        RpcNames.recordInterestEvent,
        params: {'p_category_slug': categorySlug, 'p_event': event},
      );
    } catch (_) {}
  }
}
