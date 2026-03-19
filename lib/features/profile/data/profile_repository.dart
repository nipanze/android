import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_errors.dart';
import '../../../shared/models/user_model.dart';

@lazySingleton
class ProfileRepository {
  ProfileRepository(this._supabase);
  final SupabaseClient _supabase;

  Stream<UserModel> watchUser(String userId) {
    return _supabase
        .from(Tables.users)
        .stream(primaryKey: ['user_id'])
        .eq('user_id', userId)
        .map((rows) {
          if (rows.isEmpty) throw ServerException('User $userId not found');
          return UserModel.fromJson(rows.first);
        });
  }

  Future<UserModel?> getUser(String userId) async {
    final rows = await _supabase
        .from(Tables.users)
        .select()
        .eq('user_id', userId)
        .limit(1);
    if (rows.isEmpty) return null;
    return UserModel.fromJson(rows.first);
  }

  // Profile (extended personal, address, employment data)
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final rows = await _supabase
        .from(Tables.userProfiles)
        .select()
        .eq('user_id', userId)
        .limit(1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> createProfile(String userId, Map<String, dynamic> data) async {
    try {
      final pct = _computeCompletion(data);
      await _supabase.from(Tables.userProfiles).insert({
        'user_id': userId,
        'profile_completion_percentage': pct,
        'profile_completed': pct == 100,
        ...data,
      });
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    try {
      final pct = _computeCompletion(data);
      await _supabase.from(Tables.userProfiles).update({
        'profile_completion_percentage': pct,
        'profile_completed': pct == 100,
        ...data,
      }).eq('user_id', userId);
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  // KYC status stream
  Stream<Map<String, dynamic>?> watchKycStatus(String userId) {
    return _supabase
        .from(Tables.kycVerifications)
        .stream(primaryKey: ['verification_id'])
        .eq('user_id', userId)
        .map((rows) => rows.isEmpty ? null : rows.first);
  }

  // Current risk assessment
  Future<Map<String, dynamic>?> getCurrentRiskAssessment(String userId) async {
    final rows = await _supabase
        .from(Tables.riskAssessments)
        .select()
        .eq('user_id', userId)
        .eq('is_current', true)
        .limit(1);
    return rows.isEmpty ? null : rows.first;
  }

  /// Public settings (is_public=TRUE) — used for client-side validators.
  Future<Map<String, dynamic>> getPublicSettings() async {
    final rows = await _supabase
        .from(Tables.systemSettings)
        .select('setting_key, setting_value, setting_type')
        .eq('is_public', true);
    return {
      for (final r in rows)
        r['setting_key'] as String: _parseSetting(r),
    };
  }

  dynamic _parseSetting(Map<String, dynamic> row) {
    final val = row['setting_value'] as String?;
    if (val == null) return null;
    return switch (row['setting_type'] as String) {
      'number' => double.tryParse(val) ?? val,
      'boolean' => val == 'true',
      _ => val,
    };
  }

  int _computeCompletion(Map<String, dynamic> data) {
    final fields = [
      'first_name', 'last_name', 'date_of_birth', 'gender',
      'district', 'city', 'address_line1',
      'employment_status', 'monthly_income',
    ];
    final filled = fields.where((f) {
      final v = data[f];
      return v != null && v.toString().isNotEmpty;
    }).length;
    return ((filled / fields.length) * 100).round();
  }
}
