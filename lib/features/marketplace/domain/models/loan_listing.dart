import 'package:equatable/equatable.dart';

// ─── LoanListing ──────────────────────────────────────────────────────────────
// v5 schema: no total_bid_amount / funding_percentage on loan_requests.
// Bid activity is represented by number_of_bids + best_bid_rate only.

class LoanListing extends Equatable {
  const LoanListing({
    required this.requestId,
    required this.title,
    required this.purpose,
    required this.district,
    required this.durationMonths,
    required this.requestedAmount,
    required this.maxInterestRate,
    required this.riskCategory,
    required this.creditScoreBand,
    required this.status,
    required this.listedAt,
    required this.expiresAt,
    required this.numberOfBids,
    this.bestBidRate,
  });

  final String requestId;
  final String title;
  final String purpose;
  final String district;
  final int durationMonths;
  final int requestedAmount;
  final double maxInterestRate;
  final String riskCategory;
  final String creditScoreBand;
  final String status;
  final DateTime listedAt;
  final DateTime expiresAt;
  final int numberOfBids;
  final double? bestBidRate;

  Duration get timeRemaining => expiresAt.difference(DateTime.now());
  bool get isClosingSoon24h => timeRemaining.inHours < 24 && !timeRemaining.isNegative;
  bool get isClosingSoon6h => timeRemaining.inHours < 6 && !timeRemaining.isNegative;
  bool get isExpired => timeRemaining.isNegative;

  String get timeRemainingLabel {
    if (isExpired) return 'Expired';
    final d = timeRemaining;
    if (d.inDays > 0) return '${d.inDays}d ${d.inHours % 24}h left';
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m left';
    return '${d.inMinutes}m left';
  }

  factory LoanListing.fromMap(Map<String, dynamic> map) {
    return LoanListing(
      requestId: map['request_id'] as String,
      title: map['title'] as String? ?? 'Untitled',
      purpose: map['purpose'] as String? ?? '',
      district: map['district'] as String? ?? '',
      durationMonths: map['duration_months'] as int? ?? 0,
      requestedAmount: (map['requested_amount'] as num?)?.toInt() ?? 0,
      maxInterestRate: (map['max_interest_rate'] as num?)?.toDouble() ?? 0,
      riskCategory: map['risk_category'] as String? ?? 'medium',
      creditScoreBand: map['credit_score_band'] as String? ?? 'B',
      status: map['status'] as String? ?? 'active',
      listedAt: DateTime.tryParse(map['listed_at'] as String? ?? '') ?? DateTime.now(),
      expiresAt: DateTime.tryParse(map['expires_at'] as String? ?? '') ?? DateTime.now(),
      numberOfBids: map['number_of_bids'] as int? ?? 0,
      bestBidRate: (map['best_bid_rate'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [requestId, status, numberOfBids, bestBidRate];
}

// ─── LoanBid ──────────────────────────────────────────────────────────────────

class LoanBid extends Equatable {
  const LoanBid({
    required this.id,
    required this.requestId,
    required this.amount,
    required this.interestRate,
    required this.status,
    required this.placedAt,
    this.lenderToken,
  });

  final String id;
  final String requestId;
  final int amount;
  final double interestRate;
  final String status;
  final DateTime placedAt;
  final String? lenderToken; // anonymised — e.g. L-#482

  factory LoanBid.fromMap(Map<String, dynamic> map) {
    return LoanBid(
      id: map['id'] as String,
      requestId: map['request_id'] as String,
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      interestRate: (map['interest_rate'] as num?)?.toDouble() ?? 0,
      status: map['status'] as String? ?? 'pending',
      placedAt: DateTime.tryParse(map['placed_at'] as String? ?? '') ?? DateTime.now(),
      lenderToken: map['lender_token'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, status, interestRate];
}

// ─── ContractSummary ──────────────────────────────────────────────────────────
// Returned by v_user_portfolio / contract detail queries.
// indicative_* fields reflect the SP-generated schedule, not a custodial balance.

class ContractSummary extends Equatable {
  const ContractSummary({
    required this.contractId,
    required this.requestId,
    required this.agreedRate,
    required this.indicativeMonthlyPaymentUgx,
    required this.indicativeTotalRepayableUgx,
    required this.status,
    required this.contractedAt,
  });

  final String contractId;
  final String requestId;
  final double agreedRate;
  final int indicativeMonthlyPaymentUgx;
  final int indicativeTotalRepayableUgx;
  final String status; // 'active' | 'completed' | 'defaulted'
  final DateTime contractedAt;

  factory ContractSummary.fromMap(Map<String, dynamic> map) {
    return ContractSummary(
      contractId: map['id'] as String,
      requestId: map['request_id'] as String,
      agreedRate: (map['agreed_rate'] as num?)?.toDouble() ?? 0,
      indicativeMonthlyPaymentUgx:
          (map['indicative_monthly_payment_ugx'] as num?)?.toInt() ?? 0,
      indicativeTotalRepayableUgx:
          (map['indicative_total_repayable_ugx'] as num?)?.toInt() ?? 0,
      status: map['status'] as String? ?? 'active',
      contractedAt:
          DateTime.tryParse(map['contracted_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [contractId, status];
}

// ─── RepaymentLine ────────────────────────────────────────────────────────────
// participant-reported only — platform never holds or moves funds.

class RepaymentLine extends Equatable {
  const RepaymentLine({
    required this.id,
    required this.contractId,
    required this.periodNumber,
    required this.reportedStatus,
    this.reportedAt,
  });

  final String id;
  final String contractId;
  final int periodNumber;
  /// 'pending' | 'paid' | 'overdue' — self-reported by participant
  final String reportedStatus;
  final DateTime? reportedAt;

  bool get isPaid => reportedStatus == 'paid';
  bool get isOverdue => reportedStatus == 'overdue';

  factory RepaymentLine.fromMap(Map<String, dynamic> map) {
    return RepaymentLine(
      id: map['id'] as String,
      contractId: map['contract_id'] as String,
      periodNumber: map['period_number'] as int? ?? 0,
      reportedStatus: map['reported_status'] as String? ?? 'pending',
      reportedAt: map['reported_at'] != null
          ? DateTime.tryParse(map['reported_at'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [id, reportedStatus];
}
