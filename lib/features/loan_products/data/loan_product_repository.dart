import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../core/errors/app_exception.dart';

@lazySingleton
class LoanProductRepository {
  LoanProductRepository(this._client);

  final SupabaseClient _client;

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Not authenticated');
    return user.id;
  }

  Future<List<Map<String, dynamic>>> getCatalog(String table) async {
    if (!const {
      'loan_product_categories',
      'loan_product_purposes',
      'loan_product_interest_methods',
      'loan_product_repayment_frequencies',
    }.contains(table)) {
      throw const ValidationException('Unknown loan product catalogue.');
    }
    try {
      final rows = await _client
          .from(table)
          .select()
          .eq('is_active', true)
          .order('sort_order');
      return (rows as List)
          .whereType<Map>()
          .map((row) => row.cast<String, dynamic>())
          .toList();
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getProviderCapabilities() async {
    try {
      final rows = await _client
          .from('provider_capabilities')
          .select('''
            id,identity_type,verification_level,is_active,
            need_capabilities!inner(slug,name,category_slug)
          ''')
          .eq('user_id', _userId)
          .eq('need_capabilities.category_slug', 'financial_services')
          .eq('need_capabilities.is_active', true);
      return (rows as List)
          .whereType<Map>()
          .map((row) => row.cast<String, dynamic>())
          .toList();
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  Future<String?> getSelectedIdentity() async {
    try {
      final row = await _client
          .from('provider_category_profiles')
          .select('provider_type')
          .eq('user_id', _userId)
          .eq('category_slug', 'financial_services')
          .maybeSingle();
      return row?['provider_type']?.toString();
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getCurrencies() async {
    try {
      final rows = await _client
          .from('currencies')
          .select('code,name,is_market_currency')
          .order('code');
      return (rows as List)
          .whereType<Map>()
          .map((row) => row.cast<String, dynamic>())
          .toList();
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getMyProducts() async {
    try {
      final rows = await _client.from('loan_products').select('''
            *,loan_product_categories(name),
            loan_product_purposes(name),provider_capabilities(need_capabilities(name))
          ''').eq('provider_id', _userId).order('updated_at', ascending: false);
      return (rows as List)
          .whereType<Map>()
          .map((row) => row.cast<String, dynamic>())
          .toList();
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getMarketplaceProducts() async {
    try {
      final rows = await _client
          .from('v_active_loan_products')
          .select()
          .order('is_featured', ascending: false)
          .order('published_at', ascending: false);
      return (rows as List)
          .whereType<Map>()
          .map((row) => row.cast<String, dynamic>())
          .toList();
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  Future<String> saveDraft(
      {String? productId, required Map<String, dynamic> payload}) async {
    try {
      final result = await _client.rpc(
        'save_loan_product_draft',
        params: {
          'p_product_id': productId,
          'p_payload': payload,
        },
      );
      return result.toString();
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  Future<Map<String, dynamic>> publish(String productId) async {
    try {
      final result = await _client.rpc(
        'publish_loan_product',
        params: {'p_product_id': productId},
      );
      return Map<String, dynamic>.from(result as Map);
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  Future<Map<String, dynamic>> getQuota() async {
    try {
      final result = await _client.rpc('get_my_loan_product_quota');
      return Map<String, dynamic>.from(result as Map);
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  Future<void> setStatus(String productId, String status) async {
    try {
      await _client.rpc('set_loan_product_status', params: {
        'p_product_id': productId,
        'p_status': status,
      });
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }
}
