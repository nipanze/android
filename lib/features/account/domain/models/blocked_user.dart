import 'package:equatable/equatable.dart';

class BlockedUser extends Equatable {
  const BlockedUser({
    required this.id,
    required this.blockedId,
    required this.createdAt,
    this.fullName,
    this.avatarUrl,
    this.email,
  });

  final String id;
  final String blockedId;
  final DateTime createdAt;
  final String? fullName;
  final String? avatarUrl;
  final String? email;

  String get displayName {
    final name = fullName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final fallback = email?.trim();
    if (fallback != null && fallback.isNotEmpty) return fallback;
    return 'Nipanze user';
  }

  String get initials {
    final name = displayName;
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  factory BlockedUser.fromMap(Map<String, dynamic> map) {
    final rawProfile = map['profiles'];
    final Map<String, dynamic> profile;
    if (rawProfile is List && rawProfile.isNotEmpty && rawProfile.first is Map) {
      profile = Map<String, dynamic>.from(rawProfile.first as Map);
    } else if (rawProfile is Map) {
      profile = Map<String, dynamic>.from(rawProfile);
    } else {
      profile = const <String, dynamic>{};
    }

    return BlockedUser(
      id: map['id'] as String,
      blockedId: map['blocked_id'] as String,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      fullName: profile['full_name'] as String?,
      avatarUrl: profile['avatar_url'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, blockedId, createdAt, fullName, avatarUrl];
}
