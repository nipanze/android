// test/features/bids/bid_validator_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:opencapital/features/bids/domain/bid_validator.dart';

void main() {
  group('BidValidator', () {
    test('accepts a valid bid', () {
      final result = BidValidator.validate(
        bidAmount: 200000,
        lendableBalance: 500000,
        maxRate: 15,
        bidRate: 12,
        isBorrowerOwn: false,
      );
      expect(result.isValid, true);
      expect(result.error, isNull);
    });

    test('rejects bid exceeding lendable balance', () {
      final result = BidValidator.validate(
        bidAmount: 600000,
        lendableBalance: 500000,
        maxRate: 15,
        bidRate: 12,
        isBorrowerOwn: false,
      );
      expect(result.isValid, false);
      expect(result.error, contains('Insufficient'));
      expect(result.error, contains('500000'));
      expect(result.error, contains('600000'));
    });

    test('rejects bid on own loan', () {
      final result = BidValidator.validate(
        bidAmount: 100000,
        lendableBalance: 500000,
        maxRate: 15,
        bidRate: 12,
        isBorrowerOwn: true,
      );
      expect(result.isValid, false);
      expect(result.error, contains('own loan'));
    });

    test('rejects bid rate exceeding max rate', () {
      final result = BidValidator.validate(
        bidAmount: 100000,
        lendableBalance: 500000,
        maxRate: 12,
        bidRate: 15,
        isBorrowerOwn: false,
      );
      expect(result.isValid, false);
      expect(result.error, contains('15.0%'));
      expect(result.error, contains('12.0%'));
    });

    test('rejects zero bid amount', () {
      final result = BidValidator.validate(
        bidAmount: 0,
        lendableBalance: 500000,
        maxRate: 15,
        bidRate: 12,
        isBorrowerOwn: false,
      );
      expect(result.isValid, false);
      expect(result.error, contains('greater than zero'));
    });

    test('rejects negative bid amount', () {
      final result = BidValidator.validate(
        bidAmount: -1000,
        lendableBalance: 500000,
        maxRate: 15,
        bidRate: 12,
        isBorrowerOwn: false,
      );
      expect(result.isValid, false);
    });

    test('accepts bid exactly equal to lendable balance', () {
      final result = BidValidator.validate(
        bidAmount: 500000,
        lendableBalance: 500000,
        maxRate: 15,
        bidRate: 12,
        isBorrowerOwn: false,
      );
      expect(result.isValid, true);
    });

    test('accepts when maxRate is null (no upper bound set by borrower)', () {
      final result = BidValidator.validate(
        bidAmount: 100000,
        lendableBalance: 500000,
        maxRate: null,
        bidRate: 25,
        isBorrowerOwn: false,
      );
      expect(result.isValid, true);
    });

    test('rejects bid rate above 100', () {
      final result = BidValidator.validate(
        bidAmount: 100000,
        lendableBalance: 500000,
        maxRate: null,
        bidRate: 101,
        isBorrowerOwn: false,
      );
      expect(result.isValid, false);
    });
  });
}
