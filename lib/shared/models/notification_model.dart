import 'package:equatable/equatable.dart';

/// Maps to `public.notifications`.
class NotificationModel extends Equatable {
  const NotificationModel({
    required this.notificationId,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    required this.read,
    this.readAt,
    required this.createdAt,
  });

  final String notificationId;
  final String userId;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic>? data; // deep-link context: {bid_id, request_id, contract_id}
  final bool read;
  final DateTime? readAt;
  final DateTime createdAt;

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
        notificationId: json['notification_id'] as String,
        userId: json['user_id'] as String,
        type: json['type'] as String,
        title: json['title'] as String,
        message: json['message'] as String,
        data: json['data'] as Map<String, dynamic>?,
        read: json['read'] as bool? ?? false,
        readAt: json['read_at'] == null ? null : DateTime.parse(json['read_at'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  @override
  List<Object?> get props => [notificationId, read, type];
}
