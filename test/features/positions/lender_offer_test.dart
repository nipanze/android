import 'package:flutter_test/flutter_test.dart';
import 'package:nipanze/features/positions/domain/models/lender_offer.dart';

void main() {
  final baseMap = {
    'offer_id': 'offer-1',
    'request_id': 'req-1',
    'listing_title': 'Medical Expense',
    'listing_purpose': 'Medical',
    'district': 'Kampala',
    'duration_months': 12,
    'requested_amount': 1000000,
    'offer_amount': 900000,
    'interest_rate_pct': 15.0,
    'late_fee_pct': 3.0,
    'repayment_frequency': 'monthly',
    'installment_amount': 86250,
    'offer_status': 'pending',
    'offered_at': '2026-01-01T00:00:00.000',
  };

  group('LenderOffer', () {
    test('fromMap parses fields and statuses', () {
      final offer = LenderOffer.fromMap(baseMap);

      expect(offer.offerId, 'offer-1');
      expect(offer.requestId, 'req-1');
      expect(offer.listingTitle, 'Medical Expense');
      expect(offer.durationMonths, 12);
      expect(offer.requestedAmount, 1000000);
      expect(offer.offerAmount, 900000);
      expect(offer.interestRatePct, 15.0);
      expect(offer.lateFeePct, 3.0);
      expect(offer.repaymentFrequency, 'monthly');
      expect(offer.status, OfferStatus.pending);
      expect(offer.isPending, isTrue);
      expect(offer.canWithdraw, isTrue);
      expect(offer.currency, 'UGX');
    });

    test('fromMap maps every offer status', () {
      expect(
          LenderOffer.fromMap({...baseMap, 'offer_status': 'accepted'}).status,
          OfferStatus.accepted);
      expect(
          LenderOffer.fromMap({...baseMap, 'offer_status': 'rejected'}).status,
          OfferStatus.rejected);
      expect(
          LenderOffer.fromMap({...baseMap, 'offer_status': 'withdrawn'}).status,
          OfferStatus.withdrawn);
      expect(
          LenderOffer.fromMap({...baseMap, 'offer_status': 'expired'}).status,
          OfferStatus.expired);
      expect(LenderOffer.fromMap({...baseMap, 'offer_status': 'x'}).status,
          OfferStatus.pending);
    });

    test('repaymentFrequencyLabel', () {
      expect(
          LenderOffer.fromMap({...baseMap, 'repayment_frequency': 'weekly'})
              .repaymentFrequencyLabel,
          'Weekly');
      expect(
          LenderOffer.fromMap({...baseMap, 'repayment_frequency': 'one_time'})
              .repaymentFrequencyLabel,
          'One-time');
      expect(LenderOffer.fromMap(baseMap).repaymentFrequencyLabel, 'Monthly');
    });

    test('totalRepayment includes interest', () {
      final offer = LenderOffer.fromMap(baseMap);
      expect(offer.totalRepayment,
          (900000 * (1 + 15 / 100)).round());
    });

    test('isRevealed depends on reveal_status', () {
      expect(LenderOffer.fromMap({...baseMap, 'reveal_status': 'revealed'})
          .isRevealed, isTrue);
      expect(LenderOffer.fromMap(baseMap).isRevealed, isFalse);
    });

    test('copyWith updates status and revealStatus', () {
      final offer = LenderOffer.fromMap(baseMap);
      final updated =
          offer.copyWith(status: OfferStatus.withdrawn, revealStatus: 'none');

      expect(updated.status, OfferStatus.withdrawn);
      expect(updated.revealStatus, 'none');
      expect(updated.offerId, offer.offerId);
    });

    test('acceptance flags', () {
      expect(
          LenderOffer.fromMap({...baseMap, 'offer_status': 'accepted'})
              .isAccepted,
          isTrue);
    });
  });
}
