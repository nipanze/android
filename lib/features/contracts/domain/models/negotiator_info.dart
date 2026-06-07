// lib/features/contracts/domain/models/negotiator_info.dart
import 'package:equatable/equatable.dart';

class NegotiatorInfo extends Equatable {
  const NegotiatorInfo({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    this.credentials,
    this.specialisation,
    this.dealsCompleted = 0,
    this.avgRating,
  });

  final String  id;
  final String  fullName;
  final String  phone;
  final String  email;
  final String? credentials;
  final String? specialisation;
  final int     dealsCompleted;
  final double? avgRating;

  factory NegotiatorInfo.fromMap(Map<String, dynamic> map) {
    return NegotiatorInfo(
      id:             map['id']              as String,
      fullName:       map['full_name']       as String,
      phone:          map['phone']           as String,
      email:          map['email']           as String,
      credentials:    map['credentials']    as String?,
      specialisation: map['specialisation'] as String?,
      dealsCompleted: map['deals_completed'] as int? ?? 0,
      avgRating:      (map['avg_rating'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [id];
}

class ContactReveal extends Equatable {
  const ContactReveal({
    required this.id,
    required this.contractId,
    required this.revealedBy,
    required this.revealsBorrower,
    required this.revealsLender,
    required this.revealsNegotiator,
    required this.status,
    this.revealedAt,
  });

  final String    id;
  final String    contractId;
  final String    revealedBy;
  final bool      revealsBorrower;
  final bool      revealsLender;
  final bool      revealsNegotiator;
  final String    status; // 'pending' | 'revealed'
  final DateTime? revealedAt;

  bool get isRevealed => status == 'revealed';

  factory ContactReveal.fromMap(Map<String, dynamic> map) {
    return ContactReveal(
      id:                map['id']                  as String,
      contractId:        map['contract_id']         as String,
      revealedBy:        map['revealed_by']         as String,
      revealsBorrower:   map['reveals_borrower']    as bool? ?? false,
      revealsLender:     map['reveals_lender']      as bool? ?? false,
      revealsNegotiator: map['reveals_negotiator']  as bool? ?? false,
      status:            map['status']              as String? ?? 'pending',
      revealedAt: map['revealed_at'] != null
          ? DateTime.tryParse(map['revealed_at'] as String) : null,
    );
  }

  @override
  List<Object?> get props => [id, status];
}
