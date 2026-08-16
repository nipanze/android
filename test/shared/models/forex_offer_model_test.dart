import 'package:flutter_test/flutter_test.dart';
import 'package:nipanze/shared/models/forex_offer_model.dart';

void main() {
  final baseMap = {
    'id': 'fx-offer-1',
    'request_id': 'fx-1',
    'offer_maker_id': 'user-2',
    'rate_offered': 0.00027,
    'amount_available': 500000,
    'terms': 'Bank transfer within 24h',
    'status': 'pending',
    'offered_at': '2026-01-01T00:00:00.000',
  };

  group('ForexOfferModel', () {
    test('fromMap parses fields', () {
      final offer = ForexOfferModel.fromMap(baseMap);

      expect(offer.id, 'fx-offer-1');
      expect(offer.requestId, 'fx-1');
      expect(offer.offerMakerId, 'user-2');
      expect(offer.rateOffered, 0.00027);
      expect(offer.amountAvailable, 500000);
      expect(offer.terms, 'Bank transfer within 24h');
      expect(offer.status, 'pending');
      expect(offer.hasMaskedOfferMaker, isFalse);
    });

    test('fromMap supports legacy snake_case offer keys', () {
      final offer = ForexOfferModel.fromMap({
        ...baseMap,
        'id': null,
        'offer_id': 'fx-offer-2',
        'offer_maker_id': null,
        'lender_id': 'user-3',
        'status': null,
        'offer_status': 'accepted',
      });

      expect(offer.id, 'fx-offer-2');
      expect(offer.offerMakerId, 'user-3');
      expect(offer.status, 'accepted');
    });

    test('hasMaskedOfferMaker true for public offers', () {
      final offer = ForexOfferModel.fromMap(
          {...baseMap, 'offer_maker_id': 'public-offer-xyz'});
      expect(offer.hasMaskedOfferMaker, isTrue);
    });

    test('professionalTag maps institution types', () {
      final offer = ForexOfferModel.fromMap(
          {...baseMap, 'institution_type': 'bank', 'show_professional_tag': true});
      expect(offer.professionalTag, 'Bank');

      final noTag = ForexOfferModel.fromMap(
          {...baseMap, 'institution_type': 'bank', 'show_professional_tag': false});
      expect(noTag.professionalTag, isNull);
    });
  });
}
