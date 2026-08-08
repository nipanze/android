// lib/features/notifications/domain/models/app_notification.dart
import 'package:equatable/equatable.dart';

enum NotificationType {
  bidReceived,
  bidAccepted,
  bidRejected,
  bidWithdrawn,
  negotiatorAssigned,
  contractDraftAvailable,
  kycApproved,
  kycRejected,
  closingSoon24h,
  closingSoon6h,
  watchlistNewBid,
  watchlistRateChange,
  contactRevealed,
  system,
}

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.requestId,
    this.forexRequestId,
    this.offerId,
    this.data,
  });

  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final String? requestId;
  final String? forexRequestId;
  final String? offerId;
  final Map<String, dynamic>? data;

  bool get hasDeepLink => deepLinkRoute != null;

  /// Deep link route — used to navigate on tap.
  String? get deepLinkRoute {
    if (forexRequestId != null) return '/forex/$forexRequestId';
    if (requestId != null) return '/marketplace/$requestId';
    return null;
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      type: _typeFromString(map['type'] as String? ?? 'system'),
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      isRead: map['is_read'] as bool? ?? false,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      requestId: map['request_id'] as String?,
      forexRequestId: map['forex_request_id'] as String?,
      offerId: (map['offer_id'] ?? map['forex_offer_id']) as String?,
      data: map['data'] != null
          ? Map<String, dynamic>.from(map['data'] as Map)
          : null,
    );
  }

  static NotificationType _typeFromString(String s) {
    switch (s) {
      case 'bid_received':
        return NotificationType.bidReceived;
      case 'bid_accepted':
        return NotificationType.bidAccepted;
      case 'bid_rejected':
        return NotificationType.bidRejected;
      case 'bid_withdrawn':
        return NotificationType.bidWithdrawn;
      case 'negotiator_assigned':
        return NotificationType.negotiatorAssigned;
      case 'contract_draft_available':
        return NotificationType.contractDraftAvailable;
      case 'kyc_approved':
        return NotificationType.kycApproved;
      case 'kyc_rejected':
        return NotificationType.kycRejected;
      case 'closing_soon_24h':
        return NotificationType.closingSoon24h;
      case 'closing_soon_6h':
        return NotificationType.closingSoon6h;
      case 'watchlist_new_bid':
        return NotificationType.watchlistNewBid;
      case 'watchlist_rate_change':
        return NotificationType.watchlistRateChange;
      case 'contact_revealed':
        return NotificationType.contactRevealed;
      default:
        return NotificationType.system;
    }
  }

  @override
  List<Object?> get props => [id, isRead];
}
