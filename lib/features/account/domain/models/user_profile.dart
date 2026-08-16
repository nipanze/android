// lib/features/account/domain/models/user_profile.dart
import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    this.phone,
    this.district,
    this.employmentType,
    this.employerName,
    this.monthlyIncome,
    this.incomeCurrency = 'UGX',
    this.country = 'UG',
    this.preferredBank,
    this.institutionType,
    this.isBankAgent = false,
    this.showProfessionalTag = true,
    this.preferredEmploymentTypes,
    this.preferredIncomeBracket,
    this.prefersSuggestedTerms = false,
    this.prefersVerifiedOnly = false,
    required this.accountStatus,
    this.memberSince,
    // subscription
    this.subscriptionPlan,
    this.subscriptionStatus,
    this.subscriptionExpiresAt,
    // kyc
    this.kycStatus,
    this.kycExpiresAt,
    // public trust signals
    this.trustRatingAvg,
    this.trustReviewCount = 0,
    this.trustCompletedDealsCount = 0,
    this.trustIsRepeatParticipant = false,
    this.trustPhoneVerified = false,
    this.trustResponseTimeBucket,
    // Pro-only trust insights
    this.trustIsVerified = false,
    this.trustSuccessRate,
    this.trustReliabilityScore,
    // marketplace activity
    this.activeListings = 0,
    this.activeOffers = 0,
    this.revealedContacts = 0,
    this.freeUnlocksRemaining = 1,
    this.referralCode,
    this.referredBy,
    this.referralStatus = 'none',
    this.marketingEnabled = false,
    this.marketingCountry,
    this.marketingJoinedAt,
  });

  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final String? phone;
  final String? district;
  final String? employmentType;
  final String? employerName;
  final int? monthlyIncome;
  final String incomeCurrency;
  final String country;
  final String? preferredBank;
  final String? institutionType;
  final bool isBankAgent;
  final bool showProfessionalTag;
  int? get monthlyIncomeUgx => monthlyIncome;
  final List<String>? preferredEmploymentTypes;
  final String? preferredIncomeBracket;
  final bool prefersSuggestedTerms;
  final bool prefersVerifiedOnly;
  final String accountStatus;
  final DateTime? memberSince;

  final String? subscriptionPlan;
  final String? subscriptionStatus;
  final DateTime? subscriptionExpiresAt;

  final String? kycStatus;
  final DateTime? kycExpiresAt;

  final double? trustRatingAvg;
  final int trustReviewCount;
  final int trustCompletedDealsCount;
  final bool trustIsRepeatParticipant;
  final bool trustPhoneVerified;
  final String? trustResponseTimeBucket;
  final bool trustIsVerified;
  final double? trustSuccessRate;
  final int? trustReliabilityScore;

  final int activeListings;
  final int activeOffers;
  final int revealedContacts;
  final int freeUnlocksRemaining;
  final String? referralCode;
  final String? referredBy;
  final String referralStatus;
  final bool marketingEnabled;
  final String? marketingCountry;
  final DateTime? marketingJoinedAt;

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
  bool get hasActiveProPlan =>
      subscriptionPlan == 'pro' && subscriptionStatus == 'active';

  // Borrowing is free for everyone in v4.0 (but check status)
  bool get canBorrow => accountStatus == 'active';

  // Lending requires subscription
  bool get canLend =>
      (subscriptionPlan == 'lender' || subscriptionPlan == 'pro') &&
      subscriptionStatus == 'active';

  // Whether this user can unlock contacts for free (paid plan or has welcome credits)
  bool get canUnlockFree =>
      (subscriptionPlan == 'lender' || subscriptionPlan == 'pro') &&
          subscriptionStatus == 'active' ||
      freeUnlocksRemaining > 0;

  bool get hasIncompleteAccountSteps {
    final hasName = fullName?.trim().isNotEmpty == true;
    final hasPhone = phone?.trim().isNotEmpty == true;
    final hasDistrict = district?.trim().isNotEmpty == true;
    final isApproved = kycStatus == 'approved';
    return !hasName || !hasPhone || !hasDistrict || !isApproved;
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    String? phone,
    String? district,
    String? employmentType,
    String? employerName,
    int? monthlyIncome,
    String? incomeCurrency,
    String? country,
    String? preferredBank,
    String? institutionType,
    bool? isBankAgent,
    bool? showProfessionalTag,
    List<String>? preferredEmploymentTypes,
    String? preferredIncomeBracket,
    bool? prefersSuggestedTerms,
    bool? prefersVerifiedOnly,
    String? accountStatus,
    DateTime? memberSince,
    String? subscriptionPlan,
    String? subscriptionStatus,
    DateTime? subscriptionExpiresAt,
    String? kycStatus,
    DateTime? kycExpiresAt,
    double? trustRatingAvg,
    int? trustReviewCount,
    int? trustCompletedDealsCount,
    bool? trustIsRepeatParticipant,
    bool? trustPhoneVerified,
    String? trustResponseTimeBucket,
    bool? trustIsVerified,
    double? trustSuccessRate,
    int? trustReliabilityScore,
    int? activeListings,
    int? activeOffers,
    int? revealedContacts,
    int? freeUnlocksRemaining,
    String? referralCode,
    String? referredBy,
    String? referralStatus,
    bool? marketingEnabled,
    String? marketingCountry,
    DateTime? marketingJoinedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      district: district ?? this.district,
      employmentType: employmentType ?? this.employmentType,
      employerName: employerName ?? this.employerName,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      incomeCurrency: incomeCurrency ?? this.incomeCurrency,
      country: country ?? this.country,
      preferredBank: preferredBank ?? this.preferredBank,
      institutionType: institutionType ?? this.institutionType,
      isBankAgent: isBankAgent ?? this.isBankAgent,
      showProfessionalTag: showProfessionalTag ?? this.showProfessionalTag,
      preferredEmploymentTypes:
          preferredEmploymentTypes ?? this.preferredEmploymentTypes,
      preferredIncomeBracket:
          preferredIncomeBracket ?? this.preferredIncomeBracket,
      prefersSuggestedTerms:
          prefersSuggestedTerms ?? this.prefersSuggestedTerms,
      prefersVerifiedOnly: prefersVerifiedOnly ?? this.prefersVerifiedOnly,
      accountStatus: accountStatus ?? this.accountStatus,
      memberSince: memberSince ?? this.memberSince,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      subscriptionExpiresAt:
          subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      kycStatus: kycStatus ?? this.kycStatus,
      kycExpiresAt: kycExpiresAt ?? this.kycExpiresAt,
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
      activeListings: activeListings ?? this.activeListings,
      activeOffers: activeOffers ?? this.activeOffers,
      revealedContacts: revealedContacts ?? this.revealedContacts,
      freeUnlocksRemaining: freeUnlocksRemaining ?? this.freeUnlocksRemaining,
      referralCode: referralCode ?? this.referralCode,
      referredBy: referredBy ?? this.referredBy,
      referralStatus: referralStatus ?? this.referralStatus,
      marketingEnabled: marketingEnabled ?? this.marketingEnabled,
      marketingCountry: marketingCountry ?? this.marketingCountry,
      marketingJoinedAt: marketingJoinedAt ?? this.marketingJoinedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        monthlyIncome,
        incomeCurrency,
        country,
        subscriptionPlan,
        subscriptionStatus,
        kycStatus,
        accountStatus,
        trustRatingAvg,
        trustReviewCount,
        trustCompletedDealsCount,
        trustIsRepeatParticipant,
        trustPhoneVerified,
        trustResponseTimeBucket,
        trustIsVerified,
        trustSuccessRate,
        trustReliabilityScore,
        referralCode,
        referredBy,
        referralStatus,
        marketingEnabled,
        marketingCountry,
        marketingJoinedAt,
      ];
}
