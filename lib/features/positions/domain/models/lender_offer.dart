// lib/features/positions/domain/models/lender_offer.dart
import 'package:equatable/equatable.dart';

enum OfferStatus { pending, accepted, rejected, withdrawn, expired }

class LenderOffer extends Equatable {
  const LenderOffer({
    required this.offerId,
    required this.requestId,
    required this.listingTitle,
    required this.listingPurpose,
    required this.district,
    required this.durationMonths,
    required this.requestedAmount,
    required this.offerAmount,
    this.proposedExpectations,
    required this.status,
    required this.offeredAt,
    this.acceptedAt,
    this.revealStatus,
    this.revealedAt,
  });

  final String offerId;
  final String requestId;
  final String listingTitle;
  final String listingPurpose;
  final String district;
  final int durationMonths;
  final int requestedAmount;
  final int offerAmount;
  final String? proposedExpectations;
  final OfferStatus status;
  final DateTime offeredAt;
  final DateTime? acceptedAt;
  final String? revealStatus;
  final DateTime? revealedAt;

  // Compatibility aliases and helper getters
  DateTime get placedAt => offeredAt;
  bool get canWithdraw => status == OfferStatus.pending;
  bool get isPending => status == OfferStatus.pending;
  bool get isAccepted => status == OfferStatus.accepted;
  bool get isRevealed => revealStatus == 'revealed';

  LenderOffer copyWith({
    OfferStatus? status,
    String? revealStatus,
  }) => LenderOffer(
    offerId: offerId,
    requestId: requestId,
    listingTitle: listingTitle,
    listingPurpose: listingPurpose,
    district: district,
    durationMonths: durationMonths,
    requestedAmount: requestedAmount,
    offerAmount: offerAmount,
    proposedExpectations: proposedExpectations,
    status: status ?? this.status,
    offeredAt: offeredAt,
    acceptedAt: acceptedAt,
    revealStatus: revealStatus ?? this.revealStatus,
    revealedAt: revealedAt,
  );

  factory LenderOffer.fromMap(Map<String, dynamic> map) {
    return LenderOffer(
      offerId: map['offer_id'] as String,
      requestId: map['request_id'] as String,
      listingTitle: map['listing_title'] as String? ?? 'Untitled',
      listingPurpose: map['listing_purpose'] as String? ?? '',
      district: map['district'] as String? ?? '',
      durationMonths: map['duration_months'] as int? ?? 0,
      requestedAmount: (map['requested_amount'] as num?)?.toInt() ?? 0,
      offerAmount: (map['offer_amount'] as num?)?.toInt() ?? 0,
      proposedExpectations: map['proposed_expectations'] as String?,
      status: _statusFromString(map['offer_status'] as String? ?? 'pending'),
      offeredAt: DateTime.tryParse(map['offered_at'] as String? ?? '') ?? DateTime.now(),
      acceptedAt: map['accepted_at'] != null 
          ? DateTime.tryParse(map['accepted_at'] as String) 
          : null,
      revealStatus: map['reveal_status'] as String?,
      revealedAt: map['revealed_at'] != null 
          ? DateTime.tryParse(map['revealed_at'] as String) 
          : null,
    );
  }

  static OfferStatus _statusFromString(String s) {
    switch (s) {
      case 'accepted': return OfferStatus.accepted;
      case 'rejected': return OfferStatus.rejected;
      case 'withdrawn': return OfferStatus.withdrawn;
      case 'expired': return OfferStatus.expired;
      default: return OfferStatus.pending;
    }
  }

  @override
  List<Object?> get props => [offerId, status, revealStatus];
}
