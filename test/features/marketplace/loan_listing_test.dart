import 'package:flutter_test/flutter_test.dart';
import 'package:nipanze/features/marketplace/domain/models/loan_listing.dart';

void main() {
  group('LoanListing', () {
    test('fromMap parses all fields', () {
      final map = {
        'request_id': 'req-1',
        'title': 'School fees',
        'purpose': 'Education',
        'district': 'Kampala',
        'country': 'UG',
        'duration_months': 12,
        'requested_amount': 1000000,
        'income_source': 'Salaried',
        'preferred_repayment_plan': 'Monthly',
        'repayment_amount_per_period': 100000,
        'repayment_timeline': '12 months',
        'suggested_interest_rate_pct': 10.5,
        'has_collateral': true,
        'collateral_details': 'Land title',
        'status': 'active',
        'listed_at': '2026-01-01T00:00:00.000',
        'expires_at': '2026-02-01T00:00:00.000',
        'number_of_offers': 3,
        'kyc_status': 'approved',
        'trust_rating_avg': 4.5,
        'is_sponsored': true,
      };

      final listing = LoanListing.fromMap(map);

      expect(listing.requestId, 'req-1');
      expect(listing.title, 'School fees');
      expect(listing.purpose, 'Education');
      expect(listing.district, 'Kampala');
      expect(listing.country, 'UG');
      expect(listing.durationMonths, 12);
      expect(listing.requestedAmount, 1000000);
      expect(listing.incomeSource, 'Salaried');
      expect(listing.preferredRepaymentPlan, 'Monthly');
      expect(listing.repaymentAmountPerPeriod, 100000);
      expect(listing.repaymentTimeline, '12 months');
      expect(listing.suggestedInterestRatePct, 10.5);
      expect(listing.hasCollateral, isTrue);
      expect(listing.collateralDetails, 'Land title');
      expect(listing.status, 'active');
      expect(listing.numberOfOffers, 3);
      expect(listing.kycStatus, 'approved');
      expect(listing.trustRatingAvg, 4.5);
      expect(listing.isSponsored, isTrue);
      expect(listing.currency, 'UGX');
    });

    test('fromMap defaults missing optional fields', () {
      final listing = LoanListing.fromMap({
        'request_id': 'req-1',
        'listed_at': '2026-01-01T00:00:00.000',
        'expires_at': '2026-02-01T00:00:00.000',
      });

      expect(listing.title, 'Untitled');
      expect(listing.purpose, '');
      expect(listing.durationMonths, 0);
      expect(listing.requestedAmount, 0);
      expect(listing.status, 'active');
      expect(listing.numberOfOffers, 0);
      expect(listing.hasCollateral, isFalse);
      expect(listing.currency, 'UGX');
      expect(listing.trustIsVerified, isFalse);
    });

    test('fromMap maps country code to its default currency', () {
      final listing = LoanListing.fromMap({
        'request_id': 'req-1',
        'country': 'KE',
        'listed_at': '2026-01-01T00:00:00.000',
        'expires_at': '2026-02-01T00:00:00.000',
      });

      expect(listing.currency, 'KES');
    });

    test('professionalTag returns agent bank name when bank agent', () {
      final listing = LoanListing(
        requestId: 'req-1',
        title: 't',
        purpose: 'p',
        district: 'd',
        country: 'UG',
        durationMonths: 6,
        requestedAmount: 1000,
        incomeSource: 's',
        preferredRepaymentPlan: 'Monthly',
        repaymentAmountPerPeriod: 100,
        repaymentTimeline: '6 months',
        status: 'active',
        listedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 1)),
        numberOfOffers: 0,
        showProfessionalTag: true,
        isBankAgent: true,
        preferredBank: 'Stanbic',
      );

      expect(listing.professionalTag, 'Stanbic agent');
    });

    test('professionalTag is null when not showing tag', () {
      final listing = LoanListing(
        requestId: 'req-1',
        title: 't',
        purpose: 'p',
        district: 'd',
        country: 'UG',
        durationMonths: 6,
        requestedAmount: 1000,
        incomeSource: 's',
        preferredRepaymentPlan: 'Monthly',
        repaymentAmountPerPeriod: 100,
        repaymentTimeline: '6 months',
        status: 'active',
        listedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 1)),
        numberOfOffers: 0,
        institutionType: 'bank',
      );

      expect(listing.professionalTag, isNull);
    });

    test('collateralPreview truncates long details to 80 chars', () {
      final listing = LoanListing(
        requestId: 'req-1',
        title: 't',
        purpose: 'p',
        district: 'd',
        country: 'UG',
        durationMonths: 6,
        requestedAmount: 1000,
        incomeSource: 's',
        preferredRepaymentPlan: 'Monthly',
        repaymentAmountPerPeriod: 100,
        repaymentTimeline: '6 months',
        status: 'active',
        listedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 1)),
        numberOfOffers: 0,
        hasCollateral: true,
        collateralDetails: 'x' * 200,
      );

      expect(listing.collateralPreview, isNotNull);
      expect(listing.collateralPreview!.length, 80);
      expect(listing.collateralPreview, endsWith('...'));
    });

    test('collateralPreview is null when no collateral or no details', () {
      final noCollateral = LoanListing(
        requestId: 'req-1',
        title: 't',
        purpose: 'p',
        district: 'd',
        country: 'UG',
        durationMonths: 6,
        requestedAmount: 1000,
        incomeSource: 's',
        preferredRepaymentPlan: 'Monthly',
        repaymentAmountPerPeriod: 100,
        repaymentTimeline: '6 months',
        status: 'active',
        listedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 1)),
        numberOfOffers: 0,
        hasCollateral: false,
        collateralDetails: 'Land',
      );

      expect(noCollateral.collateralPreview, isNull);
    });

    test('timeRemainingLabel formats expired and active listings', () {
      final expired = LoanListing(
        requestId: 'req-1',
        title: 't',
        purpose: 'p',
        district: 'd',
        country: 'UG',
        durationMonths: 6,
        requestedAmount: 1000,
        incomeSource: 's',
        preferredRepaymentPlan: 'Monthly',
        repaymentAmountPerPeriod: 100,
        repaymentTimeline: '6 months',
        status: 'active',
        listedAt: DateTime.now().subtract(const Duration(days: 10)),
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
        numberOfOffers: 0,
      );

      expect(expired.isExpired, isTrue);
      expect(expired.timeRemainingLabel, 'Expired');
    });
  });

  group('LoanOffer', () {
    test('fromMap parses fields and defaults', () {
      final offer = LoanOffer.fromMap({
        'id': 'offer-1',
        'request_id': 'req-1',
        'lender_id': 'lender-1',
        'offer_amount': 500000,
        'interest_rate_pct': 12.0,
        'late_fee_pct': 2.0,
        'repayment_frequency': 'weekly',
        'installment_amount': 100000,
        'status': 'pending',
        'offered_at': '2026-01-01T00:00:00.000',
      });

      expect(offer.id, 'offer-1');
      expect(offer.requestId, 'req-1');
      expect(offer.lenderId, 'lender-1');
      expect(offer.offerAmount, 500000);
      expect(offer.interestRatePct, 12.0);
      expect(offer.lateFeePct, 2.0);
      expect(offer.repaymentFrequency, 'weekly');
      expect(offer.installmentAmount, 100000);
      expect(offer.status, 'pending');
      expect(offer.hasMaskedLender, isFalse);
    });

    test('hasMaskedLender true for public offers', () {
      final offer = LoanOffer.fromMap({
        'id': 'offer-1',
        'request_id': 'req-1',
        'lender_id': 'public-offer-abc',
        'offer_amount': 500000,
        'interest_rate_pct': 12.0,
        'late_fee_pct': 2.0,
        'repayment_frequency': 'monthly',
        'installment_amount': 100000,
        'status': 'pending',
        'offered_at': '2026-01-01T00:00:00.000',
      });

      expect(offer.hasMaskedLender, isTrue);
    });

    test('professionalTag maps institution types', () {
      LoanOffer base({
        String? institutionType,
        bool showTag = true,
        bool isBankAgent = false,
        String? preferredBank,
      }) =>
          LoanOffer(
            id: 'o1',
            requestId: 'r1',
            lenderId: 'l1',
            offerAmount: 1000,
            interestRatePct: 10,
            lateFeePct: 2,
            repaymentFrequency: 'monthly',
            installmentAmount: 100,
            status: 'pending',
            offeredAt: DateTime.now(),
            showProfessionalTag: showTag,
            isBankAgent: isBankAgent,
            preferredBank: preferredBank,
            institutionType: institutionType,
          );

      expect(base(institutionType: 'bank').professionalTag, 'Bank');
      expect(
          base(institutionType: 'forex_exchange').professionalTag,
          'Forex exchange');
      expect(base(institutionType: 'sacco').professionalTag, 'SACCO');
      expect(base(institutionType: 'company').professionalTag, 'Company');
      expect(base(institutionType: 'other').professionalTag, isNull);
      expect(base(showTag: false, institutionType: 'bank').professionalTag,
          isNull);
    });
  });
}
