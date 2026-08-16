import 'package:equatable/equatable.dart';

class ReferralDashboard extends Equatable {
  const ReferralDashboard({
    required this.marketer,
    required this.summary,
    required this.history,
  });

  final ReferralMarketer marketer;
  final ReferralSummary summary;
  final List<ReferralHistoryItem> history;

  factory ReferralDashboard.fromMap(Map<String, dynamic> map) {
    return ReferralDashboard(
      marketer: ReferralMarketer.fromMap(
        Map<String, dynamic>.from(map['marketer'] as Map? ?? const {}),
      ),
      summary: ReferralSummary.fromMap(
        Map<String, dynamic>.from(map['summary'] as Map? ?? const {}),
      ),
      history: ((map['history'] as List?) ?? const [])
          .map((e) => ReferralHistoryItem.fromMap(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [marketer, summary, history];
}

class ReferralMarketer extends Equatable {
  const ReferralMarketer({
    required this.id,
    required this.userId,
    required this.referralCode,
    required this.referralLink,
    required this.status,
    required this.marketingEnabled,
    this.marketingCountry,
    this.joinedAt,
  });

  final String id;
  final String userId;
  final String referralCode;
  final String referralLink;
  final String status;
  final bool marketingEnabled;
  final String? marketingCountry;
  final DateTime? joinedAt;

  factory ReferralMarketer.fromMap(Map<String, dynamic> map) {
    return ReferralMarketer(
      id: map['marketer_id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      referralCode: map['referral_code'] as String? ?? '',
      referralLink: map['referral_link'] as String? ?? '',
      status: map['status'] as String? ?? 'active',
      marketingEnabled: map['marketing_enabled'] as bool? ?? false,
      marketingCountry: map['marketing_country'] as String?,
      joinedAt: DateTime.tryParse(map['joined_at'] as String? ?? ''),
    );
  }

  @override
  List<Object?> get props => [id, referralCode, status, marketingEnabled];
}

class ReferralSummary extends Equatable {
  const ReferralSummary({
    required this.totalReferrals,
    required this.registered,
    required this.verified,
    required this.qualified,
    required this.pendingRewards,
    required this.availableRewards,
    required this.paidRewards,
    required this.totalEarned,
    required this.totalPaid,
    required this.currency,
  });

  final int totalReferrals;
  final int registered;
  final int verified;
  final int qualified;
  final int pendingRewards;
  final int availableRewards;
  final int paidRewards;
  final int totalEarned;
  final int totalPaid;
  final String currency;

  factory ReferralSummary.fromMap(Map<String, dynamic> map) {
    int readInt(String key) => (map[key] as num?)?.toInt() ?? 0;
    return ReferralSummary(
      totalReferrals: readInt('total_referrals'),
      registered: readInt('registered'),
      verified: readInt('verified'),
      qualified: readInt('qualified'),
      pendingRewards: readInt('pending_rewards'),
      availableRewards: readInt('available_rewards'),
      paidRewards: readInt('paid_rewards'),
      totalEarned: readInt('total_earned'),
      totalPaid: readInt('total_paid'),
      currency: map['currency'] as String? ?? 'UGX',
    );
  }

  @override
  List<Object?> get props => [
        totalReferrals,
        registered,
        verified,
        qualified,
        pendingRewards,
        availableRewards,
        paidRewards,
        totalEarned,
        totalPaid,
        currency,
      ];
}

class ReferralHistoryItem extends Equatable {
  const ReferralHistoryItem({
    required this.id,
    required this.displayName,
    required this.registeredAt,
    required this.status,
    required this.qualificationStatus,
    required this.rewardAmount,
    required this.rewardCurrency,
    required this.rewardStatus,
    required this.payoutStatus,
    this.source,
  });

  final String id;
  final String displayName;
  final DateTime registeredAt;
  final String status;
  final String qualificationStatus;
  final int rewardAmount;
  final String rewardCurrency;
  final String rewardStatus;
  final String payoutStatus;
  final String? source;

  factory ReferralHistoryItem.fromMap(Map<String, dynamic> map) {
    return ReferralHistoryItem(
      id: map['id'] as String? ?? '',
      displayName: map['display_name'] as String? ?? 'Nipanze user',
      registeredAt: DateTime.tryParse(map['registered_at'] as String? ?? '') ??
          DateTime.now(),
      status: map['status'] as String? ?? 'registered',
      qualificationStatus: map['qualification_status'] as String? ?? 'pending',
      rewardAmount: (map['reward_amount'] as num?)?.toInt() ?? 0,
      rewardCurrency: map['reward_currency'] as String? ?? 'UGX',
      rewardStatus: map['reward_status'] as String? ?? 'none',
      payoutStatus: map['payout_status'] as String? ?? 'none',
      source: map['source'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, status, rewardStatus, payoutStatus];
}
