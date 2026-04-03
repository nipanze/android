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
    required this.lenderToken,
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

  final String  id;
  final String  email;
  final String? fullName;
  final String? phone;
  final String? district;
  final String? employmentType;
  final String? employerName;
  final int?    monthlyIncomeUgx;
  final int     creditScore;
  final String  reputationTier;
  final String  lenderToken;
  final String  accountStatus;

  final String?   subscriptionPlan;
  final String?   subscriptionStatus;
  final DateTime? subscriptionExpiresAt;

  final String?   kycStatus;
  final DateTime? kycExpiresAt;

  final int activeListings;
  final int contractedAsBorrower;
  final int activeBids;
  final int contractedAsLender;

  String get displayName => fullName?.isNotEmpty == true ? fullName! : email;
  String get initials {
    if (fullName?.isNotEmpty == true) {
      final parts = fullName!.trim().split(' ');
      if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      return fullName![0].toUpperCase();
    }
    return email[0].toUpperCase();
  }

  bool get isKycApproved => kycStatus == 'approved';
  bool get canBorrow =>
      subscriptionPlan == 'borrower' || subscriptionPlan == 'pro';
  bool get canLend =>
      subscriptionPlan == 'lender' || subscriptionPlan == 'pro';

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id:              map['user_id']        as String,
      email:           map['full_name']      as String? ?? '',
      fullName:        map['full_name']      as String?,
      creditScore:     map['credit_score']   as int?    ?? 50,
      reputationTier:  map['reputation_tier'] as String? ?? 'bronze',
      lenderToken:     '',
      accountStatus:   'active',
      subscriptionPlan:    map['subscription_plan']       as String?,
      subscriptionStatus:  map['subscription_status']     as String?,
      subscriptionExpiresAt: map['subscription_expires_at'] != null
          ? DateTime.tryParse(map['subscription_expires_at'] as String)
          : null,
      kycStatus:    map['kyc_status']    as String?,
      kycExpiresAt: map['kyc_expires_at'] != null
          ? DateTime.tryParse(map['kyc_expires_at'] as String)
          : null,
      activeListings:       (map['active_listings']        as int?) ?? 0,
      contractedAsBorrower: (map['contracted_as_borrower'] as int?) ?? 0,
      activeBids:           (map['active_bids']            as int?) ?? 0,
      contractedAsLender:   (map['contracted_as_lender']   as int?) ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, creditScore, subscriptionPlan, kycStatus];
}
