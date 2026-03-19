import 'package:equatable/equatable.dart';

/// Maps to `public.bids`.
class BidModel extends Equatable {
  const BidModel({
    required this.bidId,
    required this.requestId,
    required this.lenderId,
    required this.bidAmount,
    required this.interestRate,
    required this.status,
    required this.autoAccept,
    required this.createdAt,
    this.acceptedAt,
    this.withdrawnAt,
    this.expiresAt,
  });

  final String bidId;
  final String requestId;
  final String lenderId;
  final double bidAmount;
  final double interestRate;
  final String status; // 'pending'|'accepted'|'rejected'|'withdrawn'|'expired'
  final bool autoAccept;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? withdrawnAt;
  final DateTime? expiresAt;

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';

  factory BidModel.fromJson(Map<String, dynamic> json) => BidModel(
        bidId: json['bid_id'] as String,
        requestId: json['request_id'] as String,
        lenderId: json['lender_id'] as String,
        bidAmount: (json['bid_amount'] as num).toDouble(),
        interestRate: (json['interest_rate'] as num).toDouble(),
        status: json['status'] as String,
        autoAccept: json['auto_accept'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
        acceptedAt: json['accepted_at'] == null
            ? null
            : DateTime.parse(json['accepted_at'] as String),
        withdrawnAt: json['withdrawn_at'] == null
            ? null
            : DateTime.parse(json['withdrawn_at'] as String),
        expiresAt: json['expires_at'] == null
            ? null
            : DateTime.parse(json['expires_at'] as String),
      );

  @override
  List<Object?> get props => [bidId, requestId, lenderId, status, bidAmount];
}
