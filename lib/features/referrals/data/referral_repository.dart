import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/country_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/models/referral_dashboard.dart';

@lazySingleton
class ReferralRepository {
  ReferralRepository(this._client);

  final SupabaseClient _client;

  Future<ReferralDashboard> getDashboard() async {
    final user = _client.auth.currentUser;
    final uid = user?.id;
    if (uid == null) {
      return _fallbackDashboard('');
    }

    String defaultCurrency = 'UGX';
    String referralCode = '';
    try {
      final profile = await _client
          .from('profiles')
          .select('referral_code, country, phone')
          .eq('id', uid)
          .maybeSingle();

      final countryCode = profile?['country'] as String? ?? '';
      final phone = profile?['phone'] as String? ?? user?.phone ?? '';
      final country = countryCode.isNotEmpty
          ? EastAfricaCountries.findByCode(countryCode)
          : EastAfricaCountries.findByPhone(phone);
      defaultCurrency = country.currency;
      referralCode = profile?['referral_code'] as String? ?? '';
    } catch (_) {}

    try {
      final data = await _client.rpc('get_my_referral_dashboard');
      if (data != null && data is Map) {
        final dashboard = ReferralDashboard.fromMap(Map<String, dynamic>.from(data));
        if (dashboard.summary.currency == 'UGX' && defaultCurrency != 'UGX') {
          return dashboard.copyWithCurrency(defaultCurrency);
        }
        return dashboard;
      }
    } catch (_) {
      // Fallback below
    }

    return _fallbackDashboard(uid, code: referralCode, currency: defaultCurrency);
  }

  ReferralDashboard _fallbackDashboard(
    String uid, {
    String code = '',
    String currency = 'UGX',
  }) {
    return ReferralDashboard(
      marketer: ReferralMarketer(
        id: uid,
        userId: uid,
        referralCode: code,
        referralLink: code.isNotEmpty ? 'https://nipanze.app/r/$code' : '',
        status: 'active',
        marketingEnabled: true,
      ),
      summary: ReferralSummary(
        totalReferrals: 0,
        registered: 0,
        verified: 0,
        qualified: 0,
        pendingRewards: 0,
        availableRewards: 0,
        paidRewards: 0,
        totalEarned: 0,
        totalPaid: 0,
        currency: currency,
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
