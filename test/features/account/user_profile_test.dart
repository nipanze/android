import 'package:flutter_test/flutter_test.dart';
import 'package:nipanze/features/account/domain/models/user_profile.dart';

const _base = UserProfile(
  id: 'u-1',
  email: 'user@test.com',
  fullName: 'James Okello',
  accountStatus: 'active',
);

void main() {
  group('UserProfile', () {
    test('displayName prefers fullName over email', () {
      expect(_base.displayName, 'James Okello');
    });

    test('initials from two-part name', () {
      expect(_base.initials, 'JO');
    });

    test('initials from single name', () {
      expect(_base.copyWith(fullName: 'James').initials, 'J');
    });

    test('initials from email when no name', () {
      const noName = UserProfile(
        id: 'u-1',
        email: 'user@test.com',
        accountStatus: 'active',
      );
      expect(noName.initials, 'U');
    });

    test('isKycApproved only when status is approved', () {
      expect(_base.copyWith(kycStatus: 'approved').isKycApproved, isTrue);
      expect(_base.copyWith(kycStatus: 'pending').isKycApproved, isFalse);
    });

    test('hasActiveProPlan requires pro + active', () {
      expect(_base
          .copyWith(subscriptionPlan: 'pro', subscriptionStatus: 'active')
          .hasActiveProPlan, isTrue);
      expect(_base
          .copyWith(subscriptionPlan: 'pro', subscriptionStatus: 'expired')
          .hasActiveProPlan, isFalse);
      expect(_base
          .copyWith(subscriptionPlan: 'lender', subscriptionStatus: 'active')
          .hasActiveProPlan, isFalse);
    });

    test('canBorrow requires active account', () {
      expect(_base.canBorrow, isTrue);
      expect(_base.copyWith(accountStatus: 'suspended').canBorrow, isFalse);
    });

    test('canLend requires lender or pro plan active', () {
      expect(_base
          .copyWith(subscriptionPlan: 'lender', subscriptionStatus: 'active')
          .canLend, isTrue);
      expect(_base
          .copyWith(subscriptionPlan: 'pro', subscriptionStatus: 'active')
          .canLend, isTrue);
      expect(_base
          .copyWith(subscriptionPlan: 'free', subscriptionStatus: 'active')
          .canLend, isFalse);
      expect(_base
          .copyWith(subscriptionPlan: 'lender', subscriptionStatus: 'expired')
          .canLend, isFalse);
    });

    test('canUnlockFree for paid plan or free unlocks remaining', () {
      expect(_base
          .copyWith(subscriptionPlan: 'lender', subscriptionStatus: 'active')
          .canUnlockFree, isTrue);
      expect(_base.copyWith(freeUnlocksRemaining: 1).canUnlockFree, isTrue);
      expect(_base.copyWith(freeUnlocksRemaining: 0).canUnlockFree, isFalse);
    });

    test('copyWith only changes provided fields', () {
      final updated = _base.copyWith(fullName: 'New Name');

      expect(updated.fullName, 'New Name');
      expect(updated.email, 'user@test.com');
      expect(updated.id, 'u-1');
    });
  });
}
