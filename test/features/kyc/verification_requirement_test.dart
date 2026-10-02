import 'package:flutter_test/flutter_test.dart';
import 'package:nipanze/features/kyc/domain/models/verification_requirement.dart';

void main() {
  group('VerificationRequirement', () {
    final baseMap = {
      'id': 'vr-1',
      'scope_type': 'category',
      'scope_id': 'travel_international',
      'identity_required': true,
      'phone_required': true,
      'provider_verification_required': true,
      'evidence_requirements': ['license', 'insurance'],
      'is_active': true,
      'created_at': '2026-01-01T10:00:00.000Z',
      'updated_at': '2026-01-02T12:00:00.000Z',
    };

    test('fromMap parses all fields properly', () {
      final req = VerificationRequirement.fromMap(baseMap);

      expect(req.id, 'vr-1');
      expect(req.scopeType, 'category');
      expect(req.scopeId, 'travel_international');
      expect(req.identityRequired, isTrue);
      expect(req.phoneRequired, isTrue);
      expect(req.providerVerificationRequired, isTrue);
      expect(req.evidenceRequirements, ['license', 'insurance']);
      expect(req.isActive, isTrue);
      expect(req.createdAt, isNotNull);
      expect(req.updatedAt, isNotNull);
    });

    test('fromMap handles default/missing values', () {
      final req = VerificationRequirement.fromMap({});

      expect(req.id, '');
      expect(req.scopeType, 'global');
      expect(req.scopeId, 'global');
      expect(req.identityRequired, isTrue);
      expect(req.phoneRequired, isFalse);
      expect(req.providerVerificationRequired, isFalse);
      expect(req.evidenceRequirements, isEmpty);
      expect(req.isActive, isTrue);
    });

    test('toMap converts accurately', () {
      final req = VerificationRequirement.fromMap(baseMap);
      final map = req.toMap();

      expect(map['id'], 'vr-1');
      expect(map['scope_type'], 'category');
      expect(map['scope_id'], 'travel_international');
      expect(map['identity_required'], true);
      expect(map['phone_required'], true);
      expect(map['provider_verification_required'], true);
      expect(map['evidence_requirements'], ['license', 'insurance']);
      expect(map['is_active'], true);
    });
  });

  group('VerificationCheckResult', () {
    test('allowedResult returns allowed=true without reasons', () {
      const res = VerificationCheckResult.allowedResult;
      expect(res.allowed, isTrue);
      expect(res.reason, isNull);
      expect(res.missingRequirements, isEmpty);
      expect(res.requiresIdentity, isFalse);
      expect(res.requiresProviderVerification, isFalse);
      expect(res.requiresPhone, isFalse);
    });

    test('fromMap parses blocked result for identity requirement', () {
      final res = VerificationCheckResult.fromMap({
        'allowed': false,
        'reason': 'identity_verification_required',
        'missing_requirements': ['identity_verification_required'],
      });

      expect(res.allowed, isFalse);
      expect(res.reason, 'identity_verification_required');
      expect(res.requiresIdentity, isTrue);
      expect(res.requiresProviderVerification, isFalse);
      expect(res.requiresPhone, isFalse);
    });

    test('fromMap parses blocked result for provider verification requirement', () {
      final res = VerificationCheckResult.fromMap({
        'allowed': false,
        'reason': 'provider_verification_required',
        'missing_requirements': ['provider_verification_required'],
        'scope_type': 'capability',
        'scope_id': 'hajj_umrah',
        'identity_required': true,
        'provider_verification_required': true,
      });

      expect(res.allowed, isFalse);
      expect(res.reason, 'provider_verification_required');
      expect(res.requiresProviderVerification, isTrue);
      expect(res.requirement, isNotNull);
      expect(res.requirement?.scopeId, 'hajj_umrah');
    });

    test('fromMap parses blocked result for phone verification requirement', () {
      final res = VerificationCheckResult.fromMap({
        'allowed': false,
        'reason': 'phone_verification_required',
        'missing_requirements': ['phone_verification_required'],
      });

      expect(res.allowed, isFalse);
      expect(res.requiresPhone, isTrue);
    });
  });
}
