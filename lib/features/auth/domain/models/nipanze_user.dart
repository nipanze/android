// lib/features/auth/domain/models/nipanze_user.dart
import 'package:equatable/equatable.dart';

/// Mirrors subscription_plan_enum in schema.sql (free | lender | pro).
/// 'watchlist' and 'borrower' no longer exist in the v4.1 DB schema.
enum SubscriptionPlan { free, lender, pro }

enum KycStatus { notSubmitted, pending, approved, rejected, expired }

enum EmploymentType {
  employed,
  governmentEmployee,
  selfEmployed,
  smallBusinessOwner,
  businessOwner,
  student,
  other,
}

class NipanzeUser extends Equatable {
  const NipanzeUser({
    required this.id,
    required this.email,
    this.fullName,
    this.phone,
    this.district,
    this.streetAddress,
    this.employmentType,
    this.employerName,
    this.monthlyIncome,
    this.incomeCurrency = 'UGX',
    this.country = 'UG',
    this.subscriptionPlan = SubscriptionPlan.free,
    this.kycStatus = KycStatus.notSubmitted,
    this.isAdmin = false,
    this.isEmailVerified = false,
  });

  final String id;
  final String email;
  final String? fullName;
  final String? phone;
  final String? district;
  final String? streetAddress;
  final EmploymentType? employmentType;
  final String? employerName;
  final int? monthlyIncome;
  final String incomeCurrency;
  final String country;
  int? get monthlyIncomeUgx => monthlyIncome;
  final SubscriptionPlan subscriptionPlan;
  final KycStatus kycStatus;
  final bool isAdmin;
  final bool isEmailVerified;

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
      streetAddress: map['street_address'] as String?,
      employmentType: _employmentFromString(map['employment_type'] as String?),
      employerName: map['employer_name'] as String?,
      monthlyIncome: (map['monthly_income'] as num?)?.toInt(),
      incomeCurrency: map['income_currency'] as String? ?? 'UGX',
      country: map['country'] as String? ?? 'UG',
      subscriptionPlan:
          _planFromString(map['subscription_plan'] as String? ?? 'free'),
      kycStatus:
          _kycFromString(map['kyc_status'] as String? ?? 'not_submitted'),
      isAdmin: map['is_admin'] as bool? ?? false,
      isEmailVerified: map['is_email_verified'] as bool? ?? false,
    );
  }

  static SubscriptionPlan _planFromString(String s) {
    switch (s) {
      case 'lender':
        return SubscriptionPlan.lender;
      case 'pro':
        return SubscriptionPlan.pro;
      default:
        return SubscriptionPlan.free;
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

  static EmploymentType? _employmentFromString(String? s) {
    switch (s) {
      case 'employed':
        return EmploymentType.employed;
      case 'government_employee':
        return EmploymentType.governmentEmployee;
      case 'self_employed':
        return EmploymentType.selfEmployed;
      case 'small_business_owner':
        return EmploymentType.smallBusinessOwner;
      case 'business_owner':
        return EmploymentType.businessOwner;
      case 'student':
        return EmploymentType.student;
      case 'other':
        return EmploymentType.other;
      default:
        return null;
    }
  }

  static String? employmentToString(EmploymentType? type) {
    switch (type) {
      case EmploymentType.employed:
        return 'employed';
      case EmploymentType.governmentEmployee:
        return 'government_employee';
      case EmploymentType.selfEmployed:
        return 'self_employed';
      case EmploymentType.smallBusinessOwner:
        return 'small_business_owner';
      case EmploymentType.businessOwner:
        return 'business_owner';
      case EmploymentType.student:
        return 'student';
      case EmploymentType.other:
        return 'other';
      case null:
        return null;
    }
  }

  @override
  List<Object?> get props =>
      [id, email, subscriptionPlan, kycStatus, isAdmin, employmentType, streetAddress, country];
}
