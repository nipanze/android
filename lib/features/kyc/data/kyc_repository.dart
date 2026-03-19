import 'dart:io';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_errors.dart';

/// KYC document types matching kyc_verifications columns.
enum KycDocType {
  idFront('id_front', 'id_front_url'),
  idBack('id_back', 'id_back_url'),
  selfie('selfie', 'selfie_url'),
  proofOfAddress('proof_of_address', 'proof_of_address_url'),
  businessRegistration('business_registration', 'business_registration_url'),
  businessLicense('business_license', 'business_license_url'),
  taxClearance('tax_clearance', 'tax_clearance_url');

  const KycDocType(this.filePrefix, this.urlColumn);
  final String filePrefix;
  final String urlColumn;
}

@lazySingleton
class KycRepository {
  KycRepository(this._supabase);
  final SupabaseClient _supabase;

  /// Upload a KYC document to Supabase Storage.
  /// Creates or updates the kyc_verifications row for this user.
  /// Admin then reviews and sets status='approved' in Studio.
  Future<void> uploadDocument({
    required String userId,
    required File file,
    required KycDocType docType,
    required String idType, // 'national_id' | 'passport' | 'business_registration'
  }) async {
    try {
      final ext = file.path.split('.').last.toLowerCase();
      final path =
          '$userId/${docType.filePrefix}-${DateTime.now().millisecondsSinceEpoch}.$ext';

      // Upload to Storage
      await _supabase.storage
          .from(Buckets.kycDocuments)
          .upload(path, file, fileOptions: const FileOptions(upsert: true));

      final url =
          _supabase.storage.from(Buckets.kycDocuments).getPublicUrl(path);

      // Upsert kyc_verifications row
      await _supabase.from(Tables.kycVerifications).upsert(
        {
          'user_id': userId,
          'status': 'pending',
          'id_type': idType,
          docType.urlColumn: url,
          'submitted_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id',
      );
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  /// Get current KYC verification record for user.
  Future<Map<String, dynamic>?> getKycRecord(String userId) async {
    final rows = await _supabase
        .from(Tables.kycVerifications)
        .select()
        .eq('user_id', userId)
        .limit(1);
    return rows.isEmpty ? null : rows.first;
  }

  /// Real-time KYC status stream.
  Stream<Map<String, dynamic>?> watchKycStatus(String userId) {
    return _supabase
        .from(Tables.kycVerifications)
        .stream(primaryKey: ['verification_id'])
        .eq('user_id', userId)
        .map((rows) => rows.isEmpty ? null : rows.first);
  }
}
