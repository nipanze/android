import 'package:equatable/equatable.dart';

/// Maps to `public.wallet_balances`.
///
/// Three segregated pools — never blend or aggregate these columns:
///   lendableBalance      — own deposited funds; only pool eligible for bids
///   lockedRepayment      — reserved when bid is accepted; unlocked on repayment
///   nonLendableBorrowed  — credited on disbursement; permanently ineligible for lending
class WalletModel extends Equatable {
  const WalletModel({
    required this.walletId,
    required this.userId,
    required this.lendableBalance,
    required this.lockedRepayment,
    required this.nonLendableBorrowed,
    required this.updatedAt,
  });

  final String walletId;
  final String userId;

  /// Own deposited capital. UI label: "Available to Lend".
  final double lendableBalance;

  /// Reserved for active loan repayments. Cannot be withdrawn or lent.
  final double lockedRepayment;

  /// Received from loan disbursements. Can never be lent.
  final double nonLendableBorrowed;

  final DateTime updatedAt;

  double get totalBalance => lendableBalance + lockedRepayment + nonLendableBorrowed;

  factory WalletModel.fromJson(Map<String, dynamic> json) => WalletModel(
        walletId: json['wallet_id'] as String,
        userId: json['user_id'] as String,
        lendableBalance: (json['lendable_balance'] as num).toDouble(),
        lockedRepayment: (json['locked_repayment'] as num).toDouble(),
        nonLendableBorrowed: (json['non_lendable_borrowed'] as num).toDouble(),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  @override
  List<Object?> get props =>
      [walletId, userId, lendableBalance, lockedRepayment, nonLendableBorrowed];
}
