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
    required this.accountStatus,
    // filter preferences (patch v4.5)
    this.preferredEmploymentTypes,
    this.preferredIncomeBracket,
    this.prefersSuggestedTerms = false,
    this.prefersVerifiedOnly = false,
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
    this.activeOffers = 0,
    this.revealedContacts = 0,
    this.freeUnlocksRemaining = 1,
    // membership
    this.memberSince,
    // trust / reputation
    this.trustRatingAvg,
    this.trustReviewCount = 0,
    this.trustCompletedDealsCount = 0,
    this.trustIsRepeatParticipant = false,
    this.trustPhoneVerified = false,
    this.trustResponseTimeBucket,
    this.trustIsVerified = false,
    this.trustSuccessRate,
    this.trustReliabilityScore,
  });

  final String id;
  final String email;
  final String? fullName;
  final String? phone;
  final String? district;
  final String? employmentType;
  final String? employerName;
  final int? monthlyIncomeUgx;
  final String accountStatus;

  // filter preferences
  final List<String>? preferredEmploymentTypes;
  final String? preferredIncomeBracket;
  final bool prefersSuggestedTerms;
  final bool prefersVerifiedOnly;

  // subscription
  final String? subscriptionPlan;
  final String? subscriptionStatus;
  final DateTime? subscriptionExpiresAt;

  // kyc
  final String? kycStatus;
  final DateTime? kycExpiresAt;

  // portfolio counts
  final int activeListings;
  final int contractedAsBorrower;
  final int activeBids;
  final int contractedAsLender;
  final int activeOffers;
  final int revealedContacts;
  final int freeUnlocksRemaining;

  // membership
  final DateTime? memberSince;

  // trust / reputation
  final double? trustRatingAvg;
  final int trustReviewCount;
  final int trustCompletedDealsCount;
  final bool trustIsRepeatParticipant;
  final bool trustPhoneVerified;
  final String? trustResponseTimeBucket;
  final bool trustIsVerified;
  final double? trustSuccessRate;
  final int? trustReliabilityScore;

  String get displayName =>
      fullName?.isNotEmpty == true ? fullName! : email;

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

  bool get canLend =>
      subscriptionPlan == 'lender' || subscriptionPlan == 'pro';

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['user_id'] as String,
      email: map['email'] as String? ?? '',
      fullName: map['full_name'] as String?,
      phone: map['phone'] as String?,
      district: map['district'] as String?,
      employmentType: map['employment_type'] as String?,
      employerName: map['employer_name'] as String?,
      monthlyIncomeUgx: map['monthly_income_ugx'] as int?,
      accountStatus: map['account_status'] as String? ?? 'active',
      preferredEmploymentTypes:
          map['preferred_employment_types'] == null
              ? null
              : List<String>.from(
                  map['preferred_employment_types'] as List),
      preferredIncomeBracket:
          map['preferred_income_bracket'] as String?,
      prefersSuggestedTerms:
          map['prefers_suggested_terms'] as bool? ?? false,
      prefersVerifiedOnly:
          map['prefers_verified_only'] as bool? ?? false,
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
      activeOffers: (map['active_offers'] as int?) ?? 0,
      revealedContacts: (map['revealed_contacts'] as int?) ?? 0,
      freeUnlocksRemaining: (map['free_unlocks_remaining'] as int?) ?? 1,
      memberSince: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
      trustRatingAvg: (map['rating_avg'] as num?)?.toDouble(),
      trustReviewCount: (map['review_count'] as num?)?.toInt() ?? 0,
      trustCompletedDealsCount:
          (map['completed_deals_count'] as num?)?.toInt() ?? 0,
      trustIsRepeatParticipant:
          map['is_repeat_participant'] as bool? ?? false,
      trustPhoneVerified: map['phone_verified'] as bool? ?? false,
      trustResponseTimeBucket: map['response_time_bucket'] as String?,
      trustIsVerified: map['is_verified'] as bool? ?? false,
      trustSuccessRate: (map['success_rate'] as num?)?.toDouble(),
      trustReliabilityScore:
          (map['reliability_score'] as num?)?.toInt(),
    );
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? district,
    String? employmentType,
    String? employerName,
    int? monthlyIncomeUgx,
    String? accountStatus,
    List<String>? preferredEmploymentTypes,
    String? preferredIncomeBracket,
    bool? prefersSuggestedTerms,
    bool? prefersVerifiedOnly,
    String? subscriptionPlan,
    String? subscriptionStatus,
    DateTime? subscriptionExpiresAt,
    String? kycStatus,
    DateTime? kycExpiresAt,
    int? activeListings,
    int? contractedAsBorrower,
    int? activeBids,
    int? contractedAsLender,
    int? activeOffers,
    int? revealedContacts,
    int? freeUnlocksRemaining,
    DateTime? memberSince,
    double? trustRatingAvg,
    int? trustReviewCount,
    int? trustCompletedDealsCount,
    bool? trustIsRepeatParticipant,
    bool? trustPhoneVerified,
    String? trustResponseTimeBucket,
    bool? trustIsVerified,
    double? trustSuccessRate,
    int? trustReliabilityScore,
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
      accountStatus: accountStatus ?? this.accountStatus,
      preferredEmploymentTypes:
          preferredEmploymentTypes ?? this.preferredEmploymentTypes,
      preferredIncomeBracket:
          preferredIncomeBracket ?? this.preferredIncomeBracket,
      prefersSuggestedTerms:
          prefersSuggestedTerms ?? this.prefersSuggestedTerms,
      prefersVerifiedOnly: prefersVerifiedOnly ?? this.prefersVerifiedOnly,
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
      activeOffers: activeOffers ?? this.activeOffers,
      revealedContacts: revealedContacts ?? this.revealedContacts,
      freeUnlocksRemaining: freeUnlocksRemaining ?? this.freeUnlocksRemaining,
      memberSince: memberSince ?? this.memberSince,
      trustRatingAvg: trustRatingAvg ?? this.trustRatingAvg,
      trustReviewCount: trustReviewCount ?? this.trustReviewCount,
      trustCompletedDealsCount:
          trustCompletedDealsCount ?? this.trustCompletedDealsCount,
      trustIsRepeatParticipant:
          trustIsRepeatParticipant ?? this.trustIsRepeatParticipant,
      trustPhoneVerified: trustPhoneVerified ?? this.trustPhoneVerified,
      trustResponseTimeBucket:
          trustResponseTimeBucket ?? this.trustResponseTimeBucket,
      trustIsVerified: trustIsVerified ?? this.trustIsVerified,
      trustSuccessRate: trustSuccessRate ?? this.trustSuccessRate,
      trustReliabilityScore:
          trustReliabilityScore ?? this.trustReliabilityScore,
    );
  }

  @override
  List<Object?> get props => [
        id,
        subscriptionPlan,
        kycStatus,
        prefersSuggestedTerms,
        prefersVerifiedOnly,
        preferredEmploymentTypes,
        preferredIncomeBracket,
      ];
}
