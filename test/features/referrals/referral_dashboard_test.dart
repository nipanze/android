import 'package:flutter_test/flutter_test.dart';
import 'package:nipanze/features/referrals/domain/models/referral_dashboard.dart';

void main() {
  group('ReferralDashboard', () {
    final map = {
      'marketer': {
        'marketer_id': 'm-1',
        'user_id': 'u-1',
        'referral_code': 'JAMES2026',
        'referral_link': 'https://nipanze.app/r/JAMES2026',
        'status': 'active',
        'marketing_enabled': true,
      },
      'summary': {
        'total_referrals': 10,
        'registered': 7,
        'verified': 4,
        'qualified': 2,
        'pending_rewards': 1,
        'available_rewards': 1,
        'paid_rewards': 2,
        'total_earned': 30000,
        'total_paid': 20000,
        'currency': 'UGX',
      },
      'history': [
        {
          'id': 'h-1',
          'display_name': 'Alice',
          'registered_at': '2026-01-01T00:00:00.000',
          'status': 'verified',
          'qualification_status': 'qualified',
          'reward_amount': 10000,
          'reward_currency': 'UGX',
          'reward_status': 'available',
          'payout_status': 'none',
        },
      ],
    };

    test('fromMap parses nested dashboard', () {
      final dashboard = ReferralDashboard.fromMap(map);

      expect(dashboard.marketer.referralCode, 'JAMES2026');
      expect(dashboard.marketer.referralLink, 'https://nipanze.app/r/JAMES2026');
      expect(dashboard.marketer.marketingEnabled, isTrue);
      expect(dashboard.summary.totalReferrals, 10);
      expect(dashboard.summary.registered, 7);
      expect(dashboard.summary.verified, 4);
      expect(dashboard.summary.qualified, 2);
      expect(dashboard.summary.totalEarned, 30000);
      expect(dashboard.summary.totalPaid, 20000);
      expect(dashboard.summary.currency, 'UGX');
      expect(dashboard.history, hasLength(1));
      expect(dashboard.history.first.displayName, 'Alice');
      expect(dashboard.history.first.status, 'verified');
      expect(dashboard.history.first.rewardAmount, 10000);
      expect(dashboard.history.first.rewardCurrency, 'UGX');
    });

    test('fromMap defaults empty sections', () {
      final dashboard = ReferralDashboard.fromMap(const {});

      expect(dashboard.marketer.referralCode, '');
      expect(dashboard.summary.totalReferrals, 0);
      expect(dashboard.summary.currency, 'UGX');
      expect(dashboard.history, isEmpty);
    });

    test('ReferralSummary defaults all counters to zero', () {
      final summary = ReferralSummary.fromMap(const {});
      expect(summary.totalReferrals, 0);
      expect(summary.verified, 0);
      expect(summary.totalEarned, 0);
      expect(summary.currency, 'UGX');
    });

    test('ReferralHistoryItem defaults', () {
      final item = ReferralHistoryItem.fromMap(const {});
      expect(item.displayName, 'Nipanze user');
      expect(item.status, 'registered');
      expect(item.rewardStatus, 'none');
      expect(item.payoutStatus, 'none');
      expect(item.rewardCurrency, 'UGX');
    });
  });
}
