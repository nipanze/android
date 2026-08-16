import 'package:flutter_test/flutter_test.dart';
import 'package:nipanze/shared/models/forex_listing_model.dart';

void main() {
  final baseMap = {
    'request_id': 'fx-1',
    'requester_id': 'user-1',
    'currency_held': 'UGX',
    'currency_needed': 'USD',
    'amount': 1000000,
    'country': 'UG',
    'settlement_preference': 'mobile_money',
    'preferred_rate': 0.00027,
    'status': 'active',
    'number_of_offers': 2,
    'listed_at': '2026-01-01T00:00:00.000',
    'expires_at': '2026-02-01T00:00:00.000',
    'kyc_status': 'approved',
    'trust_rating_avg': 4.2,
  };

  group('ForexListingModel', () {
    test('fromMap parses all fields', () {
      final listing = ForexListingModel.fromMap(baseMap);

      expect(listing.requestId, 'fx-1');
      expect(listing.requesterId, 'user-1');
      expect(listing.currencyHeld, 'UGX');
      expect(listing.currencyNeeded, 'USD');
      expect(listing.amount, 1000000);
      expect(listing.country, 'UG');
      expect(listing.settlementPreference, 'mobile_money');
      expect(listing.preferredRate, 0.00027);
      expect(listing.status, 'active');
      expect(listing.numberOfOffers, 2);
      expect(listing.kycStatus, 'approved');
      expect(listing.trustRatingAvg, 4.2);
    });

    test('fromMap defaults missing fields', () {
      final listing = ForexListingModel.fromMap({
        'request_id': 'fx-1',
      });

      expect(listing.currencyHeld, 'UGX');
      expect(listing.currencyNeeded, 'USD');
      expect(listing.amount, 0);
      expect(listing.country, 'UG');
      expect(listing.status, 'active');
      expect(listing.numberOfOffers, 0);
      expect(listing.preferredRate, isNull);
    });

    test('receiveEstimate rounds amount times rate', () {
      final listing = ForexListingModel.fromMap(baseMap);
      expect(listing.receiveEstimate, (1000000 * 0.00027).round());
    });

    test('receiveEstimate is zero when no preferred rate', () {
      final listing = ForexListingModel.fromMap(
          {...baseMap, 'preferred_rate': null});
      expect(listing.receiveEstimate, 0);
    });

    test('closing-soon getters', () {
      final closingSoon = ForexListingModel.fromMap({
        ...baseMap,
        'expires_at':
            DateTime.now().add(const Duration(hours: 3)).toIso8601String(),
      });
      expect(closingSoon.isClosingSoon24h, isTrue);
      expect(closingSoon.isClosingSoon6h, isTrue);
      expect(closingSoon.isExpired, isFalse);

      final expired = ForexListingModel.fromMap({
        ...baseMap,
        'expires_at':
            DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
      });
      expect(expired.isExpired, isTrue);
      expect(expired.isClosingSoon24h, isFalse);
    });

    test('equality is based on props', () {
      final a = ForexListingModel.fromMap(baseMap);
      final b = ForexListingModel.fromMap(baseMap);
      expect(a, equals(b));
    });
  });
}
