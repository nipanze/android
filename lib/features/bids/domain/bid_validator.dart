/// Client-side bid validation.
/// Mirrors the DB trigger trg_fn_enforce_lendable_on_bid.
/// The DB is authoritative — this is UX-only pre-flight.
class BidValidationResult {
  const BidValidationResult({this.error});
  final String? error;
  bool get isValid => error == null;
}

class BidValidator {
  static BidValidationResult validate({
    required double bidAmount,
    required double lendableBalance,
    required double? maxRate,
    required double bidRate,
    required bool isBorrowerOwn,
  }) {
    if (isBorrowerOwn) {
      return const BidValidationResult(error: 'You cannot bid on your own loan request.');
    }
    if (bidAmount <= 0) {
      return const BidValidationResult(error: 'Bid amount must be greater than zero.');
    }
    if (bidAmount > lendableBalance) {
      return BidValidationResult(
        error:
            'Insufficient lendable balance. '
            'Available: ${lendableBalance.toStringAsFixed(0)} UGX, '
            'Required: ${bidAmount.toStringAsFixed(0)} UGX.',
      );
    }
    if (maxRate != null && bidRate > maxRate) {
      return BidValidationResult(
        error:
            'Interest rate ${bidRate.toStringAsFixed(1)}% exceeds the borrower\'s '
            'maximum of ${maxRate.toStringAsFixed(1)}%.',
      );
    }
    if (bidRate < 0 || bidRate > 100) {
      return const BidValidationResult(error: 'Interest rate must be between 0% and 100%.');
    }
    return const BidValidationResult();
  }
}
