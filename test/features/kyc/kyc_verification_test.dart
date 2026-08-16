import 'package:flutter_test/flutter_test.dart';
import 'package:nipanze/features/kyc/domain/models/kyc_verification.dart';

void main() {
  group('KycVerification', () {
    final baseMap = {
      'id': 'kyc-1',
      'user_id': 'u-1',
      'status': 'pending',
      'national_id_front_url': 'https://cdn.test/front.png',
      'national_id_back_url': 'https://cdn.test/back.png',
      'selfie_url': 'https://cdn.test/selfie.png',
      'submitted_at': '2026-01-01T00:00:00.000',
    };

    test('fromMap parses all fields', () {
      final kyc = KycVerification.fromMap(baseMap);

      expect(kyc.id, 'kyc-1');
      expect(kyc.userId, 'u-1');
      expect(kyc.status, 'pending');
      expect(kyc.isPending, isTrue);
      expect(kyc.nationalIdFrontUrl, 'https://cdn.test/front.png');
      expect(kyc.hasFront, isTrue);
      expect(kyc.hasBack, isTrue);
      expect(kyc.hasSelfie, isTrue);
      expect(kyc.allDocsUploaded, isTrue);
    });

    test('status getters', () {
      expect(
          KycVerification.fromMap({...baseMap, 'status': 'approved'}).isApproved,
          isTrue);
      expect(
          KycVerification.fromMap({...baseMap, 'status': 'rejected'}).isRejected,
          isTrue);
      expect(
          KycVerification.fromMap({...baseMap, 'status': 'expired'}).isExpired,
          isTrue);
      expect(
          KycVerification.fromMap({...baseMap, 'status': 'not_submitted'})
              .notSubmitted,
          isTrue);
      expect(KycVerification.fromMap(baseMap).isApproved, isFalse);
    });

    test('allDocsUploaded is false when any document is missing', () {
      final partial = KycVerification.fromMap({
        ...baseMap,
        'selfie_url': null,
      });

      expect(partial.hasSelfie, isFalse);
      expect(partial.allDocsUploaded, isFalse);
    });

    test('fromMap defaults status to not_submitted', () {
      final kyc = KycVerification.fromMap({
        'id': 'kyc-1',
        'user_id': 'u-1',
      });

      expect(kyc.status, 'not_submitted');
      expect(kyc.allDocsUploaded, isFalse);
    });
  });
}
