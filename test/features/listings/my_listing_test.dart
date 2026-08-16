import 'package:flutter_test/flutter_test.dart';
import 'package:nipanze/features/listings/domain/models/my_listing.dart';

void main() {
  final baseMap = {
    'id': 'req-1',
    'title': 'School fees',
    'purpose': 'Education',
    'district': 'Kampala',
    'duration_months': 6,
    'requested_amount': 1000000,
    'income_source': 'Salary',
    'preferred_repayment_plan': 'Monthly',
    'repayment_amount_per_period': 200000,
    'repayment_timeline': '6 months',
    'status': 'active',
    'number_of_offers': 2,
    'listed_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
    'expires_at':
        DateTime.now().add(const Duration(days: 7)).toIso8601String(),
  };

  group('MyListing', () {
    test('fromMap parses active listing', () {
      final listing = MyListing.fromMap(baseMap);

      expect(listing.id, 'req-1');
      expect(listing.title, 'School fees');
      expect(listing.purpose, 'Education');
      expect(listing.district, 'Kampala');
      expect(listing.durationMonths, 6);
      expect(listing.requestedAmount, 1000000);
      expect(listing.status, ListingStatus.active);
      expect(listing.numberOfOffers, 2);
      expect(listing.isActive, isTrue);
      expect(listing.isContracted, isFalse);
      expect(listing.currency, 'UGX');
    });

    test('fromMap maps every status string', () {
      expect(MyListing.fromMap({...baseMap, 'status': 'pending_kyc'}).status,
          ListingStatus.pendingKyc);
      expect(MyListing.fromMap({...baseMap, 'status': 'contracted'}).status,
          ListingStatus.contracted);
      expect(MyListing.fromMap({...baseMap, 'status': 'expired'}).status,
          ListingStatus.expired);
      expect(MyListing.fromMap({...baseMap, 'status': 'cancelled'}).status,
          ListingStatus.cancelled);
      expect(MyListing.fromMap({...baseMap, 'status': 'nonsense'}).status,
          ListingStatus.active);
    });

    test('fromMap resolves currency from nested countries object', () {
      final listing = MyListing.fromMap({
        ...baseMap,
        'countries': {'currency_code': 'KES'},
      });

      expect(listing.currency, 'KES');
    });

    test('fromMap falls back to flat currency keys', () {
      expect(MyListing.fromMap({...baseMap, 'currency_code': 'TZS'}).currency,
          'TZS');
      expect(MyListing.fromMap({...baseMap, 'currency': 'NGN'}).currency,
          'NGN');
      expect(MyListing.fromMap(baseMap).currency, 'UGX');
    });

    test('timeRemainingLabel is empty for non-active listings', () {
      final listing = MyListing.fromMap({
        ...baseMap,
        'status': 'cancelled',
        'expires_at': '2026-03-01T00:00:00.000',
      });

      expect(listing.timeRemainingLabel, '');
    });

    test('status getters', () {
      final listing = MyListing.fromMap(baseMap);
      expect(listing.isActive, isTrue);
      expect(listing.isCancelled, isFalse);
      expect(listing.isExpired, isFalse);
      expect(listing.hasExpired, isFalse);
    });
  });
}
