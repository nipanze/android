import 'package:equatable/equatable.dart';

/// Maps to `public.users` in the database.
/// NOTE: `reputation_tier` is auto-synced by `trg_sync_reputation_tier` —
/// never write it directly; update `reputation_score` instead.
class UserModel extends Equatable {
  const UserModel({
    required this.userId,
    required this.email,
    this.phoneNumber,
    required this.role,
    required this.status,
    required this.emailVerified,
    required this.phoneVerified,
    required this.twoFactorEnabled,
    required this.reputationScore,
    required this.reputationTier,
    this.lastLoginAt,
    this.lockedUntil,
    required this.createdAt,
    required this.updatedAt,
  });

  final String userId;
  final String email;
  final String? phoneNumber;
  final String role; // 'borrower' | 'lender' | 'both' | 'admin'
  final String status; // 'active' | 'suspended' | 'deactivated' | 'pending_verification'
  final bool emailVerified;
  final bool phoneVerified;
  final bool twoFactorEnabled;
  final int reputationScore; // 0–100
  final String reputationTier; // 'restricted'|'bronze'|'silver'|'gold'|'platinum'
  final DateTime? lastLoginAt;
  final DateTime? lockedUntil;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isActive => status == 'active';
  bool get canBorrow => role == 'borrower' || role == 'both';
  bool get canLend => role == 'lender' || role == 'both';
  bool get isAdmin => role == 'admin';

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        userId: json['user_id'] as String,
        email: json['email'] as String,
        phoneNumber: json['phone_number'] as String?,
        role: json['role'] as String,
        status: json['status'] as String,
        emailVerified: json['email_verified'] as bool? ?? false,
        phoneVerified: json['phone_verified'] as bool? ?? false,
        twoFactorEnabled: json['two_factor_enabled'] as bool? ?? false,
        reputationScore: json['reputation_score'] as int? ?? 50,
        reputationTier: json['reputation_tier'] as String? ?? 'bronze',
        lastLoginAt: json['last_login_at'] == null
            ? null
            : DateTime.parse(json['last_login_at'] as String),
        lockedUntil: json['locked_until'] == null
            ? null
            : DateTime.parse(json['locked_until'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'email': email,
        'phone_number': phoneNumber,
        'role': role,
        'status': status,
        'email_verified': emailVerified,
        'phone_verified': phoneVerified,
        'two_factor_enabled': twoFactorEnabled,
        'reputation_score': reputationScore,
        'reputation_tier': reputationTier,
        'last_login_at': lastLoginAt?.toIso8601String(),
        'locked_until': lockedUntil?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [userId, email, role, status, reputationScore, reputationTier];
}
