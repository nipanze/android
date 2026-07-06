import 'package:equatable/equatable.dart';

enum RepTier { platinum, gold, silver, bronze, restricted }

enum SubscriptionPlan { watchlist, borrower, lender, pro }

enum KycStatus { notSubmitted, pending, approved, rejected, expired }

class NipanzeUser extends Equatable {
  const NipanzeUser({
    required this.id,
    required this.email,
    this.fullName,
    this.phone,
    this.district,
    this.creditScore = 50,
    this.repTier = RepTier.bronze,
    this.lenderToken,
    this.subscriptionPlan = SubscriptionPlan.watchlist,
    this.kycStatus = KycStatus.notSubmitted,
    this.role = 'user',
    this.isEmailVerified = false,
  });

  final String id;
  final String email;
  final String? fullName;
  final String? phone;
  final String? district;
  final int creditScore;
  final RepTier repTier;
  final String? lenderToken;
  final SubscriptionPlan subscriptionPlan;
  final KycStatus kycStatus;
  final String role;
  final bool isEmailVerified;

  bool get isAdmin => role == 'admin';
  bool get isNegotiator => role == 'negotiator';
  bool get canBorrow => true;
  bool get canSuggestBorrowerTerms => subscriptionPlan == SubscriptionPlan.pro;
  bool get canLend =>
      subscriptionPlan == SubscriptionPlan.lender ||
      subscriptionPlan == SubscriptionPlan.pro;
  bool get kycApproved => kycStatus == KycStatus.approved;

  factory NipanzeUser.fromMap(Map<String, dynamic> map) {
    return NipanzeUser(
      id: map['id'] as String,
      email: map['email'] as String? ?? '',
      fullName: map['full_name'] as String?,
      phone: map['phone'] as String?,
      district: map['district'] as String?,
      creditScore: map['credit_score'] as int? ?? 50,
      repTier:
          _repTierFromString(map['reputation_tier'] as String? ?? 'bronze'),
      lenderToken: map['lender_token'] as String?,
      subscriptionPlan:
          _planFromString(map['subscription_plan'] as String? ?? 'watchlist'),
      kycStatus:
          _kycFromString(map['kyc_status'] as String? ?? 'not_submitted'),
      role: map['role'] as String? ?? 'user',
      isEmailVerified: map['is_email_verified'] as bool? ?? false,
    );
  }

  static RepTier _repTierFromString(String s) {
    switch (s) {
      case 'platinum':
        return RepTier.platinum;
      case 'gold':
        return RepTier.gold;
      case 'silver':
        return RepTier.silver;
      case 'restricted':
        return RepTier.restricted;
      default:
        return RepTier.bronze;
    }
  }

  static SubscriptionPlan _planFromString(String s) {
    switch (s) {
      case 'borrower':
        return SubscriptionPlan.borrower;
      case 'lender':
        return SubscriptionPlan.lender;
      case 'pro':
        return SubscriptionPlan.pro;
      default:
        return SubscriptionPlan.watchlist;
    }
  }

  static KycStatus _kycFromString(String s) {
    switch (s) {
      case 'pending':
        return KycStatus.pending;
      case 'approved':
        return KycStatus.approved;
      case 'rejected':
        return KycStatus.rejected;
      case 'expired':
        return KycStatus.expired;
      default:
        return KycStatus.notSubmitted;
    }
  }

  @override
  List<Object?> get props =>
      [id, email, repTier, subscriptionPlan, kycStatus, role];
}
