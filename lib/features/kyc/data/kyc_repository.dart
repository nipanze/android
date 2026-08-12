// lib/features/kyc/data/kyc_repository.dart
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../domain/models/kyc_verification.dart';

@lazySingleton
class KycRepository {
  KycRepository(this._client);

  final SupabaseClient _client;

  String get _uid => _client.auth.currentUser!.id;

  /// Fetch the current user's KYC record.
  /// Returns null if no record exists yet.
  Future<KycVerification?> getMyKyc() async {
    try {
      final data = await _client
          .from(TableNames.kycVerifications)
          .select()
          .eq('user_id', _uid)
          .maybeSingle();

      return data != null ? KycVerification.fromMap(data) : null;
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  /// Upload a single document to the kyc-documents bucket.
  /// Uses XFile (cross-platform) so it works on web (no dart:io).
  /// Returns a signed URL valid for 1 year.
  Future<String> uploadDocument(XFile xfile, String docType) async {
    try {
      final bytes = await xfile.readAsBytes();

      // Derive extension: prefer MIME sniffing, fall back to path extension.
      final mimeType =
          lookupMimeType(xfile.name, headerBytes: bytes) ?? 'image/jpeg';
      final ext = (extensionFromMime(mimeType) ?? 'jpg').replaceAll('.', '');
      final path =
          '$_uid/${docType}_${DateTime.now().millisecondsSinceEpoch}.$ext';

      await _client.storage
          .from(StorageBuckets.kycDocuments)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(upsert: true, contentType: mimeType),
          );

      // Return signed URL valid for 1 year (admin review window)
      final url = await _client.storage
          .from(StorageBuckets.kycDocuments)
          .createSignedUrl(path, 60 * 60 * 24 * 365);

      return url;
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  /// Create or update the KYC record with uploaded document URLs.
  Future<KycVerification> saveDocumentUrl({
    required String
        docType, // 'national_id_front' | 'national_id_back' | 'selfie'
    required String url,
  }) async {
    try {
      // Check if record exists
      final existing = await _client
          .from(TableNames.kycVerifications)
          .select('id')
          .eq('user_id', _uid)
          .maybeSingle();

      final column = '${docType}_url';

      if (existing == null) {
        // Insert new record
        final data = await _client
            .from(TableNames.kycVerifications)
            .insert({'user_id': _uid, column: url})
            .select()
            .single();
        return KycVerification.fromMap(data);
      } else {
        // Update existing
        final data = await _client
            .from(TableNames.kycVerifications)
            .update({column: url})
            .eq('user_id', _uid)
            .select()
            .single();
        return KycVerification.fromMap(data);
      }
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  /// Submit KYC for admin review.
  /// Sets status to 'pending' and records submitted_at.
  Future<KycVerification> submitForReview() async {
    try {
      final data = await _client
          .from(TableNames.kycVerifications)
          .update({
            'status': 'pending',
            'submitted_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', _uid)
          .select()
          .single();

      return KycVerification.fromMap(data);
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }
}
