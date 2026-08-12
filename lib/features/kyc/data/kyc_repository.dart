import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../domain/models/kyc_verification.dart';

@lazySingleton
class KycRepository {
  KycRepository(this._client);

  final SupabaseClient _client;

  String get _uid {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('User is not authenticated. Please log in.');
    }
    return user.id;
  }

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

  /// Upload a single document to Supabase storage.
  /// Uses XFile & Uint8List (cross-platform) so it works on web, mobile, desktop.
  /// Uploads strictly to the [StorageBuckets.kycDocuments] bucket.
  /// Throws a clear [AppException] if the upload fails — no silent fallback.
  Future<String> uploadDocument(XFile xfile, String docType) async {
    try {
      final uid = _uid;
      final rawBytes = await xfile.readAsBytes();
      final bytes = Uint8List.fromList(rawBytes);

      // Derive extension: prefer MIME sniffing, fall back to path extension.
      final mimeType =
          lookupMimeType(xfile.name, headerBytes: bytes) ?? 'image/jpeg';
      final ext = (extensionFromMime(mimeType) ?? 'jpg').replaceAll('.', '');
      final path =
          '$uid/${docType}_${DateTime.now().millisecondsSinceEpoch}.$ext';

      final bucket = StorageBuckets.kycDocuments; // 'verification-documents'

      // ignore: avoid_print
      print('[Storage] Uploading to bucket "$bucket" at path "$path"...');

      await _client.storage.from(bucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(upsert: true, contentType: mimeType),
          );

      // ignore: avoid_print
      print('[Storage] Upload succeeded. Creating signed URL...');

      try {
        return await _client.storage
            .from(bucket)
            .createSignedUrl(path, 60 * 60 * 24 * 365);
      } catch (_) {
        return _client.storage.from(bucket).getPublicUrl(path);
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('[Storage] uploadDocument error (${e.runtimeType}): $e\n$st');
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
      final column = '${docType}_url';
      // ignore: avoid_print
      print('[KYC Repo] saveDocumentUrl for docType: $docType, column: $column, url: $url');

      // Check if record exists
      final existing = await _client
          .from(TableNames.kycVerifications)
          .select('id')
          .eq('user_id', _uid)
          .maybeSingle();

      // ignore: avoid_print
      print('[KYC Repo] existing record: $existing');

      if (existing == null) {
        // Insert new record
        final data = await _client
            .from(TableNames.kycVerifications)
            .insert({'user_id': _uid, column: url})
            .select()
            .single();
        // ignore: avoid_print
        print('[KYC Repo] Inserted new KYC record: $data');
        return KycVerification.fromMap(data);
      } else {
        // Update existing
        final data = await _client
            .from(TableNames.kycVerifications)
            .update({
              column: url,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', _uid)
            .select()
            .single();
        // ignore: avoid_print
        print('[KYC Repo] Updated KYC record: $data');
        return KycVerification.fromMap(data);
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('[KYC Repo] saveDocumentUrl fatal error: $e\n$st');
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
