import 'package:flutter_test/flutter_test.dart';
import 'package:nipanze/features/notifications/domain/models/app_notification.dart';

void main() {
  group('AppNotification', () {
    test('fromMap parses a bid_received notification', () {
      final notification = AppNotification.fromMap({
        'id': 'n-1',
        'user_id': 'u-1',
        'type': 'bid_received',
        'title': 'New offer',
        'body': 'You received an offer',
        'is_read': false,
        'created_at': '2026-01-01T00:00:00.000',
        'request_id': 'req-1',
      });

      expect(notification.id, 'n-1');
      expect(notification.userId, 'u-1');
      expect(notification.type, NotificationType.bidReceived);
      expect(notification.title, 'New offer');
      expect(notification.body, 'You received an offer');
      expect(notification.isRead, isFalse);
      expect(notification.requestId, 'req-1');
    });

    test('fromMap maps every supported type string', () {
      const cases = {
        'bid_accepted': NotificationType.bidAccepted,
        'bid_rejected': NotificationType.bidRejected,
        'bid_withdrawn': NotificationType.bidWithdrawn,
        'negotiator_assigned': NotificationType.negotiatorAssigned,
        'contract_draft_available': NotificationType.contractDraftAvailable,
        'kyc_approved': NotificationType.kycApproved,
        'kyc_rejected': NotificationType.kycRejected,
        'closing_soon_24h': NotificationType.closingSoon24h,
        'closing_soon_6h': NotificationType.closingSoon6h,
        'watchlist_new_bid': NotificationType.watchlistNewBid,
        'watchlist_rate_change': NotificationType.watchlistRateChange,
        'contact_revealed': NotificationType.contactRevealed,
        'referral_registered': NotificationType.referralRegistered,
        'referral_verified': NotificationType.referralVerified,
        'referral_qualified': NotificationType.referralQualified,
        'referral_reward_available': NotificationType.referralRewardAvailable,
        'referral_reward_approved': NotificationType.referralRewardApproved,
        'referral_reward_paid': NotificationType.referralRewardPaid,
        'referral_reward_rejected': NotificationType.referralRewardRejected,
        'system': NotificationType.system,
        'unknown': NotificationType.system,
      };

      cases.forEach((typeString, expected) {
        final notification = AppNotification.fromMap({
          'id': 'n-1',
          'user_id': 'u-1',
          'type': typeString,
          'title': '',
          'body': '',
          'is_read': false,
          'created_at': '2026-01-01T00:00:00.000',
        });
        expect(notification.type, expected, reason: 'for $typeString');
      });
    });

    test('deepLinkRoute prefers forex over loan', () {
      final forex = AppNotification.fromMap({
        'id': 'n-1',
        'user_id': 'u-1',
        'type': 'bid_received',
        'title': '',
        'body': '',
        'is_read': false,
        'created_at': '2026-01-01T00:00:00.000',
        'forex_request_id': 'fx-1',
        'request_id': 'req-1',
      });

      expect(forex.hasDeepLink, isTrue);
      expect(forex.deepLinkRoute, '/forex/fx-1');
    });

    test('deepLinkRoute falls back to loan route', () {
      final loan = AppNotification.fromMap({
        'id': 'n-1',
        'user_id': 'u-1',
        'type': 'bid_received',
        'title': '',
        'body': '',
        'is_read': false,
        'created_at': '2026-01-01T00:00:00.000',
        'request_id': 'req-1',
      });

      expect(loan.deepLinkRoute, '/marketplace/req-1');
    });

    test('deepLinkRoute routes kyc and referral notifications', () {
      final kyc = AppNotification.fromMap({
        'id': 'n-1',
        'user_id': 'u-1',
        'type': 'kyc_approved',
        'title': '',
        'body': '',
        'is_read': false,
        'created_at': '2026-01-01T00:00:00.000',
      });
      final referral = AppNotification.fromMap({
        'id': 'n-2',
        'user_id': 'u-1',
        'type': 'referral_registered',
        'title': '',
        'body': '',
        'is_read': false,
        'created_at': '2026-01-01T00:00:00.000',
      });
      final plain = AppNotification.fromMap({
        'id': 'n-3',
        'user_id': 'u-1',
        'type': 'system',
        'title': '',
        'body': '',
        'is_read': false,
        'created_at': '2026-01-01T00:00:00.000',
      });

      expect(kyc.deepLinkRoute, '/kyc');
      expect(referral.deepLinkRoute, '/referrals');
      expect(plain.hasDeepLink, isFalse);
      expect(plain.deepLinkRoute, isNull);
    });

    test('offerId accepts either offer key', () {
      final a = AppNotification.fromMap({
        'id': 'n-1',
        'user_id': 'u-1',
        'type': 'system',
        'title': '',
        'body': '',
        'is_read': false,
        'created_at': '2026-01-01T00:00:00.000',
        'offer_id': 'o-1',
      });
      final b = AppNotification.fromMap({
        'id': 'n-1',
        'user_id': 'u-1',
        'type': 'system',
        'title': '',
        'body': '',
        'is_read': false,
        'created_at': '2026-01-01T00:00:00.000',
        'forex_offer_id': 'o-2',
      });

      expect(a.offerId, 'o-1');
      expect(b.offerId, 'o-2');
    });
  });
}
