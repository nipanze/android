import 'package:equatable/equatable.dart';

/// Maps to `public.loan_contracts`.
class ContractModel extends Equatable {
  const ContractModel({
    required this.contractId,
    required this.requestId,
    required this.borrowerId,
    required this.totalAmount,
    required this.weightedInterestRate,
    required this.durationMonths,
    required this.monthlyPayment,
    required this.totalRepayment,
    required this.totalInterest,
    required this.status,
    required this.borrowerSigned,
    required this.allLendersSigned,
    required this.disbursed,
    required this.totalRepaid,
    this.outstandingBalance,
    this.nextPaymentDate,
    this.lastPaymentDate,
    required this.daysOverdue,
    this.maturityDate,
    this.contractActivatedAt,
    this.contractDocumentUrl,
    required this.createdAt,
  });

  final String contractId;
  final String requestId;
  final String borrowerId;
  final double totalAmount;
  final double weightedInterestRate;
  final int durationMonths;
  final double monthlyPayment;
  final double totalRepayment;
  final double totalInterest;
  final String status; // 'draft'|'active'|'completed'|'defaulted'|'cancelled'
  final bool borrowerSigned;
  final bool allLendersSigned;
  final bool disbursed;
  final double totalRepaid;
  final double? outstandingBalance;
  final DateTime? nextPaymentDate;
  final DateTime? lastPaymentDate;
  final int daysOverdue;
  final DateTime? maturityDate;
  final DateTime? contractActivatedAt;
  final String? contractDocumentUrl;
  final DateTime createdAt;

  bool get isActive => status == 'active';
  bool get isDraft => status == 'draft';
  bool get isCompleted => status == 'completed';
  bool get isDefaulted => status == 'defaulted';
  bool get isActivated => contractActivatedAt != null;
  bool get readyToActivate => borrowerSigned && allLendersSigned;

  factory ContractModel.fromJson(Map<String, dynamic> json) => ContractModel(
        contractId: json['contract_id'] as String,
        requestId: json['request_id'] as String,
        borrowerId: json['borrower_id'] as String,
        totalAmount: (json['total_amount'] as num).toDouble(),
        weightedInterestRate: (json['weighted_interest_rate'] as num).toDouble(),
        durationMonths: json['duration_months'] as int,
        monthlyPayment: (json['monthly_payment'] as num).toDouble(),
        totalRepayment: (json['total_repayment'] as num).toDouble(),
        totalInterest: (json['total_interest'] as num).toDouble(),
        status: json['status'] as String,
        borrowerSigned: json['borrower_signed'] as bool? ?? false,
        allLendersSigned: json['all_lenders_signed'] as bool? ?? false,
        disbursed: json['disbursed'] as bool? ?? false,
        totalRepaid: (json['total_repaid'] as num?)?.toDouble() ?? 0.0,
        outstandingBalance: json['outstanding_balance'] == null
            ? null
            : (json['outstanding_balance'] as num).toDouble(),
        nextPaymentDate: json['next_payment_date'] == null
            ? null
            : DateTime.parse(json['next_payment_date'] as String),
        lastPaymentDate: json['last_payment_date'] == null
            ? null
            : DateTime.parse(json['last_payment_date'] as String),
        daysOverdue: json['days_overdue'] as int? ?? 0,
        maturityDate: json['maturity_date'] == null
            ? null
            : DateTime.parse(json['maturity_date'] as String),
        contractActivatedAt: json['contract_activated_at'] == null
            ? null
            : DateTime.parse(json['contract_activated_at'] as String),
        contractDocumentUrl: json['contract_document_url'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  @override
  List<Object?> get props => [contractId, status, totalAmount, totalRepaid];
}
