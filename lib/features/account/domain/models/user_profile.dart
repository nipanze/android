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
    // subscription
    this.subscriptionPlan,
    this.subscriptionStatus,
    this.subscriptionExpiresAt,
    // kyc
    this.kycStatus,
    this.kycExpiresAt,
    // marketplace activity
    this.activeListings = 0,
    this.activeOffers = 0,
    this.revealedContacts = 0,
  });

  final String  id;
  final String  email;
  final String? fullName;
  final String? phone;
  final String? district;
  final String? employmentType;
  final String? employerName;
  final int?    monthlyIncomeUgx;
  final String  accountStatus;

  final String?   subscriptionPlan;
  final String?   subscriptionStatus;
  final DateTime? subscriptionExpiresAt;

  final String?   kycStatus;
  final DateTime? kycExpiresAt;

  final int activeListings;
  final int activeOffers;
  final int revealedContacts;

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
  
  // Borrowing is free for everyone in v4.0 (but check status)
  bool get canBorrow => accountStatus == 'active';
  
  // Lending requires subscription
  bool get canLend =>
      (subscriptionPlan == 'lender' || subscriptionPlan == 'pro') && 
      subscriptionStatus == 'active';

  @override
  List<Object?> get props => [id, subscriptionPlan, kycStatus, accountStatus];
}
