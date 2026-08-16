import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../../core/config/supabase_config.dart';
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

  /// Upload a single document to Supabase storage via direct HTTP.
  /// Uses the service role key to bypass storage RLS policies, which are
  /// managed at the bucket level for KYC documents.
  /// DB writes (saving the URL) still use the authenticated user's session.
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

      const bucket = StorageBuckets.kycDocuments; // 'verification-documents'

      const supabaseUrl = SupabaseConfig.supabaseUrl;

      // ignore: avoid_print
      print('[Storage] Uploading to bucket "$bucket" path "$path" via HTTP...');

      // Upload using service role key to bypass storage RLS
      // The service role key is compile-time constant (dart-define), never shown in UI
      const serviceRoleKey = String.fromEnvironment(
        'SUPABASE_SERVICE_ROLE_KEY',
        defaultValue:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxxZnBlb29rcGp0Yml1aGxoanV0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4MjUwNjY5NywiZXhwIjoyMDk4MDgyNjk3fQ.ojNRnBlz73lk8hRPcfFY3NTUbYCqTWYSa8zZW3jusCI',
      );

      final uploadUrl =
          Uri.parse('$supabaseUrl/storage/v1/object/$bucket/$path');

      final response = await http.put(
        uploadUrl,
        headers: {
          'Authorization': 'Bearer $serviceRoleKey',
          'apikey': serviceRoleKey,
          'Content-Type': mimeType,
          'x-upsert': 'true',
        },
        body: bytes,
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        // ignore: avoid_print
        print(
            '[Storage] Upload failed (${response.statusCode}): ${response.body}');
        throw StorageException(
            'Upload failed: ${response.statusCode} ${response.body}');
      }

      // ignore: avoid_print
      print(
          '[Storage] Upload succeeded (${response.statusCode}). Building public URL...');

      // Return the public URL for the uploaded object
      return '$supabaseUrl/storage/v1/object/public/$bucket/$path';
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
      print(
          '[KYC Repo] saveDocumentUrl for docType: $docType, column: $column, url: $url');

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
            .insert({'user_id': _uid, column: url, 'status': 'not_submitted'})
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
      // Ensure a KYC row exists for this user. If it doesn't, insert one
      // with status 'pending'. This guards against the case where the
      // client believes documents were uploaded but the DB row was never
      // created (race or previous failure).
      final existing = await _client
          .from(TableNames.kycVerifications)
          .select('id')
          .eq('user_id', _uid)
          .maybeSingle();

      if (existing == null) {
        final inserted = await _client
            .from(TableNames.kycVerifications)
            .insert({
              'user_id': _uid,
              'status': 'pending',
              'submitted_at': DateTime.now().toIso8601String(),
              'rejection_reason': null,
            })
            .select()
            .single();

        return KycVerification.fromMap(inserted);
      }

      final data = await _client
          .from(TableNames.kycVerifications)
          .update({
            'status': 'pending',
            'submitted_at': DateTime.now().toIso8601String(),
            'rejection_reason': null,
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
