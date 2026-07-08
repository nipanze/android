// lib/features/account/domain/models/user_profile.dart
import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    this.phone,
    this.district,
    this.employmentType,
    this.employerName,
    this.monthlyIncomeUgx,
    required this.creditScore,
    required this.reputationTier,
    this.lenderToken, // String? — may be absent from the view
    required this.accountStatus,
    // subscription
    this.subscriptionPlan,
    this.subscriptionStatus,
    this.subscriptionExpiresAt,
    // kyc
    this.kycStatus,
    this.kycExpiresAt,
    // portfolio counts
    this.activeListings = 0,
    this.contractedAsBorrower = 0,
    this.activeBids = 0,
    this.contractedAsLender = 0,
  });

  final String id;
  final String email;
  final String? fullName;
  final String? phone;
  final String? district;
  final String? employmentType;
  final String? employerName;
  final int? monthlyIncomeUgx;
  final int creditScore;
  final String reputationTier;
  final String? lenderToken; // nullable — not always present
  final String accountStatus;
  final String? subscriptionPlan;
  final String? subscriptionStatus;
  final DateTime? subscriptionExpiresAt;
  final String? kycStatus;
  final DateTime? kycExpiresAt;
  final int activeListings;
  final int contractedAsBorrower;
  final int activeBids;
  final int contractedAsLender;

  // ── Computed helpers ───────────────────────────────────────────────────────

  String get displayName => fullName?.isNotEmpty == true ? fullName! : email;

  String get initials {
    if (fullName?.isNotEmpty == true) {
      final parts = fullName!.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      }
      return fullName![0].toUpperCase();
    }
    return email[0].toUpperCase();
  }

  bool get isKycApproved => kycStatus == 'approved';

  bool get canBorrow =>
      subscriptionPlan == 'borrower' || subscriptionPlan == 'pro';

  bool get canLend => subscriptionPlan == 'lender' || subscriptionPlan == 'pro';

  // ── Factory ────────────────────────────────────────────────────────────────

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['user_id'] as String,
      // Fix: was incorrectly reading 'full_name' for email
      email: map['email'] as String? ?? '',
      fullName: map['full_name'] as String?,
      phone: map['phone'] as String?,
      district: map['district'] as String?,
      employmentType: map['employment_type'] as String?,
      employerName: map['employer_name'] as String?,
      monthlyIncomeUgx: map['monthly_income_ugx'] as int?,
      creditScore: map['credit_score'] as int? ?? 50,
      reputationTier: map['reputation_tier'] as String? ?? 'bronze',
      lenderToken: map['lender_token'] as String?,
      accountStatus: map['account_status'] as String? ?? 'active',
      subscriptionPlan: map['subscription_plan'] as String?,
      subscriptionStatus: map['subscription_status'] as String?,
      subscriptionExpiresAt: map['subscription_expires_at'] != null
          ? DateTime.tryParse(map['subscription_expires_at'] as String)
          : null,
      kycStatus: map['kyc_status'] as String?,
      kycExpiresAt: map['kyc_expires_at'] != null
          ? DateTime.tryParse(map['kyc_expires_at'] as String)
          : null,
      activeListings: (map['active_listings'] as int?) ?? 0,
      contractedAsBorrower: (map['contracted_as_borrower'] as int?) ?? 0,
      activeBids: (map['active_bids'] as int?) ?? 0,
      contractedAsLender: (map['contracted_as_lender'] as int?) ?? 0,
    );
  }

  // ── CopyWith ───────────────────────────────────────────────────────────────

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? district,
    String? employmentType,
    String? employerName,
    int? monthlyIncomeUgx,
    int? creditScore,
    String? reputationTier,
    String? lenderToken,
    String? accountStatus,
    String? subscriptionPlan,
    String? subscriptionStatus,
    DateTime? subscriptionExpiresAt,
    String? kycStatus,
    DateTime? kycExpiresAt,
    int? activeListings,
    int? contractedAsBorrower,
    int? activeBids,
    int? contractedAsLender,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      district: district ?? this.district,
      employmentType: employmentType ?? this.employmentType,
      employerName: employerName ?? this.employerName,
      monthlyIncomeUgx: monthlyIncomeUgx ?? this.monthlyIncomeUgx,
      creditScore: creditScore ?? this.creditScore,
      reputationTier: reputationTier ?? this.reputationTier,
      lenderToken: lenderToken ?? this.lenderToken,
      accountStatus: accountStatus ?? this.accountStatus,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      subscriptionExpiresAt:
          subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      kycStatus: kycStatus ?? this.kycStatus,
      kycExpiresAt: kycExpiresAt ?? this.kycExpiresAt,
      activeListings: activeListings ?? this.activeListings,
      contractedAsBorrower: contractedAsBorrower ?? this.contractedAsBorrower,
      activeBids: activeBids ?? this.activeBids,
      contractedAsLender: contractedAsLender ?? this.contractedAsLender,
    );
  }

  @override
  List<Object?> get props => [
        id,
        creditScore,
        subscriptionPlan,
        kycStatus,
        lenderToken,
      ];
}
