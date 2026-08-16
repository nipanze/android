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
    final marketerMap = map['marketer'];
    final summaryMap = map['summary'];
    final historyList = map['history'];

    return ReferralDashboard(
      marketer: ReferralMarketer.fromMap(
        marketerMap is Map ? Map<String, dynamic>.from(marketerMap) : const {},
      ),
      summary: ReferralSummary.fromMap(
        summaryMap is Map ? Map<String, dynamic>.from(summaryMap) : const {},
      ),
      history: historyList is List
          ? historyList
              .whereType<Map>()
              .map((e) => ReferralHistoryItem.fromMap(
                    Map<String, dynamic>.from(e),
                  ))
              .toList()
          : const [],
    );
  }

  ReferralDashboard copyWithCurrency(String currency) {
    return ReferralDashboard(
      marketer: marketer,
      summary: ReferralSummary(
        totalReferrals: summary.totalReferrals,
        registered: summary.registered,
        verified: summary.verified,
        qualified: summary.qualified,
        pendingRewards: summary.pendingRewards,
        availableRewards: summary.availableRewards,
        paidRewards: summary.paidRewards,
        totalEarned: summary.totalEarned,
        totalPaid: summary.totalPaid,
        currency: currency,
      ),
      history: history.map((item) {
        if (item.rewardCurrency == 'UGX' || item.rewardCurrency.isEmpty) {
          return ReferralHistoryItem(
            id: item.id,
            displayName: item.displayName,
            registeredAt: item.registeredAt,
            status: item.status,
            qualificationStatus: item.qualificationStatus,
            rewardAmount: item.rewardAmount,
            rewardCurrency: currency,
            rewardStatus: item.rewardStatus,
            payoutStatus: item.payoutStatus,
            source: item.source,
          );
        }
        return item;
      }).toList(),
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
    final code = map['referral_code']?.toString() ?? '';
    final link = map['referral_link']?.toString() ??
        (code.isNotEmpty ? 'https://nipanze.app/r/$code' : '');
    return ReferralMarketer(
      id: map['marketer_id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      referralCode: code,
      referralLink: link,
      status: map['status']?.toString() ?? 'active',
      marketingEnabled: map['marketing_enabled'] as bool? ?? false,
      marketingCountry: map['marketing_country']?.toString(),
      joinedAt: DateTime.tryParse(map['joined_at']?.toString() ?? ''),
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
    int readInt(String key) {
      final val = map[key];
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }
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
      currency: map['currency']?.toString() ?? 'UGX',
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
    int readInt(String key) {
      final val = map[key];
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }
    return ReferralHistoryItem(
      id: map['id']?.toString() ?? '',
      displayName: map['display_name']?.toString() ?? 'Nipanze user',
      registeredAt: DateTime.tryParse(map['registered_at']?.toString() ?? '') ??
          DateTime.now(),
      status: map['status']?.toString() ?? 'registered',
      qualificationStatus: map['qualification_status']?.toString() ?? 'pending',
      rewardAmount: readInt('reward_amount'),
      rewardCurrency: map['reward_currency']?.toString() ?? 'UGX',
      rewardStatus: map['reward_status']?.toString() ?? 'none',
      payoutStatus: map['payout_status']?.toString() ?? 'none',
      source: map['source']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, status, rewardStatus, payoutStatus];
}
