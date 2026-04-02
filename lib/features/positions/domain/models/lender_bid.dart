// lib/features/positions/domain/models/lender_bid.dart
import 'package:equatable/equatable.dart';

enum BidStatus { pending, accepted, rejected, withdrawn, expired }

class LenderBid extends Equatable {
  const LenderBid({
    required this.bidId,
    required this.requestId,
    required this.listingTitle,
    required this.district,
    required this.durationMonths,
    required this.riskCategory,
    required this.bidAmount,
    required this.bidRate,
    required this.bidStatus,
    required this.placedAt,
    this.acceptedAt,
    this.contractId,
    this.contractStatus,
    this.repaymentStartDate,
  });

  final String    bidId;
  final String    requestId;
  final String    listingTitle;
  final String    district;
  final int       durationMonths;
  final String    riskCategory;
  final int       bidAmount;
  final double    bidRate;
  final BidStatus bidStatus;
  final DateTime  placedAt;
  final DateTime? acceptedAt;
  final String?   contractId;
  final String?   contractStatus;
  final DateTime? repaymentStartDate;

  bool get isPending    => bidStatus == BidStatus.pending;
  bool get isAccepted   => bidStatus == BidStatus.accepted;
  bool get isWithdrawn  => bidStatus == BidStatus.withdrawn;
  bool get isContracted => contractId != null;

  factory LenderBid.fromMap(Map<String, dynamic> map) {
    return LenderBid(
      bidId:          map['bid_id']        as String,
      requestId:      map['request_id']    as String,
      listingTitle:   map['listing_title'] as String? ?? 'Untitled',
      district:       map['district']      as String? ?? '',
      durationMonths: map['duration_months'] as int? ?? 0,
      riskCategory:   map['risk_category'] as String? ?? 'medium',
      bidAmount:      (map['bid_amount']   as num?)?.toInt() ?? 0,
      bidRate:        (map['bid_rate']     as num?)?.toDouble() ?? 0,
      bidStatus:      _statusFromString(map['bid_status'] as String? ?? 'pending'),
      placedAt:       DateTime.tryParse(map['placed_at'] as String? ?? '') ?? DateTime.now(),
      acceptedAt: map['accepted_at'] != null
          ? DateTime.tryParse(map['accepted_at'] as String) : null,
      contractId:     map['contract_id']     as String?,
      contractStatus: map['contract_status'] as String?,
      repaymentStartDate: map['repayment_start_date'] != null
          ? DateTime.tryParse(map['repayment_start_date'] as String) : null,
    );
  }

  static BidStatus _statusFromString(String s) {
    switch (s) {
      case 'accepted':  return BidStatus.accepted;
      case 'rejected':  return BidStatus.rejected;
      case 'withdrawn': return BidStatus.withdrawn;
      case 'expired':   return BidStatus.expired;
      default:          return BidStatus.pending;
    }
  }

  @override
  List<Object?> get props => [bidId, bidStatus, contractStatus];
}