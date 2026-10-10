// test/features/settings/platform_limits_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nipanze/features/auth/domain/models/nipanze_user.dart';
import 'package:nipanze/features/settings/data/system_settings_repository.dart';

void main() {
  group('PlatformLimits', () {
    group('defaults', () {
      test('listingDurationDays is 30 for Loans', () {
        expect(PlatformLimits.defaults.listingDurationDays, 30);
      });

      test('forexListingDurationDays is 7 for Forex', () {
        expect(PlatformLimits.defaults.forexListingDurationDays, 7);
      });
    });

    group('durationForNeedsCategory', () {
      const limits = PlatformLimits.defaults;

      test('machinery_equipment is 14 days', () {
        expect(limits.durationForNeedsCategory('machinery_equipment'), 14);
      });

      test('professional_services is 14 days', () {
        expect(limits.durationForNeedsCategory('professional_services'), 14);
      });

      test('transport_logistics is 7 days', () {
        expect(limits.durationForNeedsCategory('transport_logistics'), 7);
      });

      test('specialized_products is 14 days', () {
        expect(limits.durationForNeedsCategory('specialized_products'), 14);
      });

      test('travel_international is 14 days', () {
        expect(limits.durationForNeedsCategory('travel_international'), 14);
      });

      test('unknown category falls back to 14 days', () {
        expect(limits.durationForNeedsCategory('education_training'), 14);
        expect(limits.durationForNeedsCategory('unknown_slug'), 14);
        expect(limits.durationForNeedsCategory(''), 14);
      });
    });

    group('durationForNeedsCategory — custom map', () {
      test('uses custom category duration over default', () {
        const custom = PlatformLimits(
          needsDurationByCategory: {
            'transport_logistics': 10,
            'machinery_equipment': 21,
          },
        );
        expect(custom.durationForNeedsCategory('transport_logistics'), 10);
        expect(custom.durationForNeedsCategory('machinery_equipment'), 21);
      });

      test('falls back to built-in switch for unmapped slugs', () {
        const custom = PlatformLimits(
          needsDurationByCategory: {'transport_logistics': 10},
        );
        // professional_services not in custom map → switch fallback
        expect(custom.durationForNeedsCategory('professional_services'), 14);
      });
    });

    group('maxActiveRequestsFor', () {
      const limits = PlatformLimits.defaults;

      test('free plan limit', () {
        expect(
          limits.maxActiveRequestsFor(SubscriptionPlan.free),
          limits.maxActiveRequestsFree,
        );
      });

      test('lender plan limit', () {
        expect(
          limits.maxActiveRequestsFor(SubscriptionPlan.lender),
          limits.maxActiveRequestsLender,
        );
      });

      test('pro plan limit', () {
        expect(
          limits.maxActiveRequestsFor(SubscriptionPlan.pro),
          limits.maxActiveRequestsPro,
        );
      });
    });
  });
}
