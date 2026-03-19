import 'package:equatable/equatable.dart';

/// Maps to `public.v_loan_listings` — the anonymised marketplace view.
///
/// PRIVACY CONTRACT: This model must NEVER contain borrower_id, borrower name,
/// email, phone, full address, employment details, or raw credit score.
/// Only the fields explicitly listed here are safe for public display.
class LoanListingModel extends Equatable {
  const LoanListingModel({
    required this.requestId,
    required this.requestedAmount,
    required this.durationMonths,
    required this.maxInterestRate,
    required this.purpose,
    required this.district,
    this.riskCategory,
    this.creditScoreBand,
    required this.fundingPercentage,
    required this.numberOfBids,
    this.listedAt,
    required this.status,
  });

  final String requestId;
  final double requestedAmount;
  final int durationMonths;
  final double? maxInterestRate;
  final String purpose;
  final String? district;
  final String? riskCategory; // 'low' | 'medium' | 'high' | 'very_high'
  final String? creditScoreBand; // e.g. '700-749' — never raw score
  final double fundingPercentage;
  final int numberOfBids;
  final DateTime? listedAt;
  final String status; // 'active' | 'partially_funded'

  factory LoanListingModel.fromJson(Map<String, dynamic> json) => LoanListingModel(
        requestId: json['request_id'] as String,
        requestedAmount: (json['requested_amount'] as num).toDouble(),
        durationMonths: json['duration_months'] as int,
        maxInterestRate: json['max_interest_rate'] == null
            ? null
            : (json['max_interest_rate'] as num).toDouble(),
        purpose: json['purpose'] as String,
        district: json['district'] as String?,
        riskCategory: json['risk_category'] as String?,
        creditScoreBand: json['credit_score_band'] as String?,
        fundingPercentage: (json['funding_percentage'] as num?)?.toDouble() ?? 0.0,
        numberOfBids: json['number_of_bids'] as int? ?? 0,
        listedAt: json['listed_at'] == null ? null : DateTime.parse(json['listed_at'] as String),
        status: json['status'] as String,
      );

  @override
  List<Object?> get props => [requestId, requestedAmount, status, fundingPercentage];
}
