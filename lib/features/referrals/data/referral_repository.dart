import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/models/referral_dashboard.dart';

@lazySingleton
class ReferralRepository {
  ReferralRepository(this._client);

  final SupabaseClient _client;

  Future<ReferralDashboard> getDashboard() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      return _fallbackDashboard('');
    }
    try {
      final data = await _client.rpc('get_my_referral_dashboard');
      if (data != null && data is Map) {
        return ReferralDashboard.fromMap(Map<String, dynamic>.from(data));
      }
    } catch (_) {
      // Fallback below
    }

    try {
      final profile = await _client
          .from('profiles')
          .select('referral_code')
          .eq('id', uid)
          .maybeSingle();

      final code = profile?['referral_code'] as String? ?? '';
      return _fallbackDashboard(uid, code: code);
    } catch (_) {
      return _fallbackDashboard(uid);
    }
  }

  ReferralDashboard _fallbackDashboard(String uid, {String code = ''}) {
    return ReferralDashboard(
      marketer: ReferralMarketer(
        id: uid,
        userId: uid,
        referralCode: code,
        referralLink: code.isNotEmpty ? 'https://nipanze.app/r/$code' : '',
        status: 'active',
        marketingEnabled: true,
      ),
      summary: const ReferralSummary(
        totalReferrals: 0,
        registered: 0,
        verified: 0,
        qualified: 0,
        pendingRewards: 0,
        availableRewards: 0,
        paidRewards: 0,
        totalEarned: 0,
        totalPaid: 0,
        currency: 'UGX',
      ),
      history: const [],
    );
  }

  Future<void> attributeReferral({
    required String referralCode,
    String source = 'registration',
  }) async {
    final code = referralCode.trim();
    if (code.isEmpty) return;

    try {
      await _client.rpc('attribute_my_referral', params: {
        'p_referral_code': code,
        'p_source': source,
      });
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }
}
