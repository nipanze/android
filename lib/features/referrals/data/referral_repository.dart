import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/models/referral_dashboard.dart';

@lazySingleton
class ReferralRepository {
  ReferralRepository(this._client);

  final SupabaseClient _client;

  Future<ReferralDashboard> getDashboard() async {
    try {
      final data = await _client.rpc('get_my_referral_dashboard');
      if (data == null) {
        return const ReferralDashboard(
          marketer: ReferralMarketer(
            id: '',
            userId: '',
            referralCode: '',
            referralLink: '',
            status: 'active',
            marketingEnabled: false,
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
            currency: 'UGX',
          ),
          history: [],
        );
      }
      return ReferralDashboard.fromMap(Map<String, dynamic>.from(data as Map));
    } catch (e) {
      throw parseSupabaseError(e);
    }
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
