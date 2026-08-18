import 'package:flutter_test/flutter_test.dart';
import 'package:nipanze/features/auth/domain/models/nipanze_user.dart';

void main() {
  const fullUser = NipanzeUser(
    id: 'uuid-1',
    email: 'james@nipanze.ug',
    fullName: 'James Okello',
    avatarUrl: 'https://cdn.nipanze.ug/avatar/james.png',
    phone: '+256712345678',
    district: 'Kampala',
    streetAddress: '123 Main St',
    employmentType: EmploymentType.employed,
    employerName: 'Pearl Capital',
    monthlyIncome: 5000000,
    incomeCurrency: 'UGX',
    preferredBank: 'Stanbic',
    institutionType: 'bank',
    isBankAgent: false,
    showProfessionalTag: true,
    country: 'UG',
    subscriptionPlan: SubscriptionPlan.pro,
    kycStatus: KycStatus.approved,
    isAdmin: false,
    isEmailVerified: true,
  );

  group('NipanzeUser', () {
    group('fromMap', () {
      test('parses all fields correctly', () {
        final map = <String, dynamic>{
          'id': 'uuid-1',
          'email': 'james@nipanze.ug',
          'full_name': 'James Okello',
          'avatar_url': 'https://cdn.nipanze.ug/avatar/james.png',
          'phone': '+256712345678',
          'district': 'Kampala',
          'street_address': '123 Main St',
          'employment_type': 'employed',
          'employer_name': 'Pearl Capital',
          'monthly_income': 5000000,
          'income_currency': 'UGX',
          'preferred_bank': 'Stanbic',
          'institution_type': 'bank',
          'is_bank_agent': false,
          'show_professional_tag': true,
          'country': 'UG',
          'subscription_plan': 'pro',
          'kyc_status': 'approved',
          'is_admin': false,
          'is_email_verified': true,
        };

        final user = NipanzeUser.fromMap(map);

        expect(user.id, 'uuid-1');
        expect(user.email, 'james@nipanze.ug');
        expect(user.fullName, 'James Okello');
        expect(user.avatarUrl, 'https://cdn.nipanze.ug/avatar/james.png');
        expect(user.phone, '+256712345678');
        expect(user.district, 'Kampala');
        expect(user.streetAddress, '123 Main St');
        expect(user.employmentType, EmploymentType.employed);
        expect(user.employerName, 'Pearl Capital');
        expect(user.monthlyIncome, 5000000);
        expect(user.incomeCurrency, 'UGX');
        expect(user.preferredBank, 'Stanbic');
        expect(user.institutionType, 'bank');
        expect(user.isBankAgent, false);
        expect(user.showProfessionalTag, true);
        expect(user.country, 'UG');
        expect(user.subscriptionPlan, SubscriptionPlan.pro);
        expect(user.kycStatus, KycStatus.approved);
        expect(user.isAdmin, false);
        expect(user.isEmailVerified, true);
      });

      test('applies defaults for missing/optional fields', () {
        final user = NipanzeUser.fromMap({
          'id': 'uuid-2',
        });

        expect(user.id, 'uuid-2');
        expect(user.email, '');
        expect(user.fullName, isNull);
        expect(user.avatarUrl, isNull);
        expect(user.phone, isNull);
        expect(user.district, isNull);
        expect(user.streetAddress, isNull);
        expect(user.employmentType, isNull);
        expect(user.employerName, isNull);
        expect(user.monthlyIncome, isNull);
        expect(user.incomeCurrency, 'UGX');
        expect(user.preferredBank, isNull);
        expect(user.institutionType, isNull);
        expect(user.isBankAgent, false);
        expect(user.showProfessionalTag, true);
        expect(user.country, 'UG');
        expect(user.subscriptionPlan, SubscriptionPlan.free);
        expect(user.kycStatus, KycStatus.notSubmitted);
        expect(user.isAdmin, false);
        expect(user.isEmailVerified, false);
      });

      test('parses all employment types from DB strings', () {
        const cases = {
          'employed': EmploymentType.employed,
          'government_employee': EmploymentType.governmentEmployee,
          'self_employed': EmploymentType.selfEmployed,
          'small_business_owner': EmploymentType.smallBusinessOwner,
          'business_owner': EmploymentType.businessOwner,
          'student': EmploymentType.student,
          'other': EmploymentType.other,
        };

        for (final entry in cases.entries) {
          final user = NipanzeUser.fromMap({
            'id': 'x',
            'employment_type': entry.key,
          });
          expect(user.employmentType, entry.value,
              reason: 'employment_type="${entry.key}"');
        }
      });

      test('returns null employmentType for unknown string', () {
        final user = NipanzeUser.fromMap({
          'id': 'x',
          'employment_type': 'freelancer',
        });
        expect(user.employmentType, isNull);
      });

      test('parses subscription plan from string', () {
        const plans = {
          'free': SubscriptionPlan.free,
          'lender': SubscriptionPlan.lender,
          'pro': SubscriptionPlan.pro,
        };

        for (final entry in plans.entries) {
          final user = NipanzeUser.fromMap({
            'id': 'x',
            'subscription_plan': entry.key,
          });
          expect(user.subscriptionPlan, entry.value,
              reason: 'subscription_plan="${entry.key}"');
        }
      });

      test('defaults to free plan for unknown string', () {
        final user = NipanzeUser.fromMap({
          'id': 'x',
          'subscription_plan': 'borrower',
        });
        expect(user.subscriptionPlan, SubscriptionPlan.free);
      });

      test('parses KYC status from string', () {
        const statuses = {
          'not_submitted': KycStatus.notSubmitted,
          'pending': KycStatus.pending,
          'approved': KycStatus.approved,
          'rejected': KycStatus.rejected,
          'expired': KycStatus.expired,
        };

        for (final entry in statuses.entries) {
          final user = NipanzeUser.fromMap({
            'id': 'x',
            'kyc_status': entry.key,
          });
          expect(user.kycStatus, entry.value,
              reason: 'kyc_status="${entry.key}"');
        }
      });

      test('defaults to not_submitted for unknown kyc_status', () {
        final user = NipanzeUser.fromMap({
          'id': 'x',
          'kyc_status': 'reviewing',
        });
        expect(user.kycStatus, KycStatus.notSubmitted);
      });

      test('defaults to not_submitted when kyc_status is absent', () {
        final user = NipanzeUser.fromMap({'id': 'x'});
        expect(user.kycStatus, KycStatus.notSubmitted);
      });

      test('parses monthly_income as num and converts to int', () {
        final user = NipanzeUser.fromMap({
          'id': 'x',
          'monthly_income': 3500000.0,
        });
        expect(user.monthlyIncome, 3500000);
      });
    });

    group('initials', () {
      test('returns first letters of first and last name', () {
        expect(fullUser.initials, 'JO');
      });

      test('returns single letter for single-word name', () {
        const user = NipanzeUser(
          id: 'x',
          email: 'test@test.com',
          fullName: 'James',
        );
        expect(user.initials, 'J');
      });

      test('trims whitespace before computing initials', () {
        const user = NipanzeUser(
          id: 'x',
          email: 'test@test.com',
          fullName: '  James  Okello  ',
        );
        expect(user.initials, 'JO');
      });

      test('returns first letter of email when no fullName', () {
        const user = NipanzeUser(
          id: 'x',
          email: 'james@nipanze.ug',
        );
        expect(user.initials, 'J');
      });

      test('returns U when fullName is null and email is empty', () {
        const user = NipanzeUser(
          id: 'x',
          email: '',
        );
        expect(user.initials, 'U');
      });

      test('handles three-part name using first and last', () {
        const user = NipanzeUser(
          id: 'x',
          email: 'a@b.com',
          fullName: 'James Patrick Okello',
        );
        expect(user.initials, 'JO');
      });
    });

    group('permission getters', () {
      test('canBorrow is always true', () {
        for (final plan in SubscriptionPlan.values) {
          final user = NipanzeUser(
            id: 'x',
            email: 'a@b.com',
            subscriptionPlan: plan,
          );
          expect(user.canBorrow, isTrue, reason: 'plan=$plan');
        }
      });

      test('canLend is true for lender and pro plans', () {
        expect(
          const NipanzeUser(id: 'x', email: '', subscriptionPlan: SubscriptionPlan.free)
              .canLend,
          isFalse,
        );
        expect(
          const NipanzeUser(id: 'x', email: '', subscriptionPlan: SubscriptionPlan.lender)
              .canLend,
          isTrue,
        );
        expect(
          const NipanzeUser(id: 'x', email: '', subscriptionPlan: SubscriptionPlan.pro)
              .canLend,
          isTrue,
        );
      });

      test('canSuggestBorrowerTerms is true only for pro plan', () {
        expect(
          const NipanzeUser(id: 'x', email: '', subscriptionPlan: SubscriptionPlan.free)
              .canSuggestBorrowerTerms,
          isFalse,
        );
        expect(
          const NipanzeUser(id: 'x', email: '', subscriptionPlan: SubscriptionPlan.lender)
              .canSuggestBorrowerTerms,
          isFalse,
        );
        expect(
          const NipanzeUser(id: 'x', email: '', subscriptionPlan: SubscriptionPlan.pro)
              .canSuggestBorrowerTerms,
          isTrue,
        );
      });

      test('kycApproved is true only for approved status', () {
        for (final status in KycStatus.values) {
          final user = NipanzeUser(
            id: 'x',
            email: '',
            kycStatus: status,
          );
          expect(
            user.kycApproved,
            status == KycStatus.approved,
            reason: 'status=$status',
          );
        }
      });
    });

    group('hasIncompleteAccountSteps', () {
      test('returns false when all required fields are present and KYC approved',
          () {
        expect(fullUser.hasIncompleteAccountSteps, isFalse);
      });

      test('returns true when fullName is missing', () {
        const user = NipanzeUser(
          id: 'x',
          email: '',
          phone: '+256712345678',
          district: 'Kampala',
          kycStatus: KycStatus.approved,
        );
        expect(user.hasIncompleteAccountSteps, isTrue);
      });

      test('returns true when fullName is whitespace only', () {
        const user = NipanzeUser(
          id: 'x',
          email: '',
          fullName: '   ',
          phone: '+256712345678',
          district: 'Kampala',
          kycStatus: KycStatus.approved,
        );
        expect(user.hasIncompleteAccountSteps, isTrue);
      });

      test('returns true when phone is missing', () {
        const user = NipanzeUser(
          id: 'x',
          email: '',
          fullName: 'James',
          district: 'Kampala',
          kycStatus: KycStatus.approved,
        );
        expect(user.hasIncompleteAccountSteps, isTrue);
      });

      test('returns true when district is missing', () {
        const user = NipanzeUser(
          id: 'x',
          email: '',
          fullName: 'James',
          phone: '+256712345678',
          kycStatus: KycStatus.approved,
        );
        expect(user.hasIncompleteAccountSteps, isTrue);
      });

      test('returns true when KYC is not approved', () {
        const user = NipanzeUser(
          id: 'x',
          email: '',
          fullName: 'James',
          phone: '+256712345678',
          district: 'Kampala',
          kycStatus: KycStatus.pending,
        );
        expect(user.hasIncompleteAccountSteps, isTrue);
      });

      test('returns true when all required fields are missing', () {
        const user = NipanzeUser(id: 'x', email: '');
        expect(user.hasIncompleteAccountSteps, isTrue);
      });
    });

    group('employmentToString', () {
      test('converts all employment types to DB strings', () {
        const expected = {
          EmploymentType.employed: 'employed',
          EmploymentType.governmentEmployee: 'government_employee',
          EmploymentType.selfEmployed: 'self_employed',
          EmploymentType.smallBusinessOwner: 'small_business_owner',
          EmploymentType.businessOwner: 'business_owner',
          EmploymentType.student: 'student',
          EmploymentType.other: 'other',
        };

        for (final entry in expected.entries) {
          expect(NipanzeUser.employmentToString(entry.key), entry.value);
        }
      });

      test('returns null for null input', () {
        expect(NipanzeUser.employmentToString(null), isNull);
      });

      test('roundtrips through fromMap for all employment types', () {
        for (final type in EmploymentType.values) {
          final dbString = NipanzeUser.employmentToString(type);
          final user = NipanzeUser.fromMap({
            'id': 'x',
            'employment_type': dbString,
          });
          expect(user.employmentType, type, reason: 'type=$type');
        }
      });
    });

    group('monthlyIncomeUgx', () {
      test('returns the monthlyIncome value', () {
        expect(fullUser.monthlyIncomeUgx, 5000000);
      });

      test('returns null when monthlyIncome is null', () {
        const user = NipanzeUser(id: 'x', email: '');
        expect(user.monthlyIncomeUgx, isNull);
      });
    });

    group('equality', () {
      test('two users with same props are equal', () {
        const a = NipanzeUser(
          id: 'uuid-1',
          email: 'a@b.com',
          fullName: 'Test',
          subscriptionPlan: SubscriptionPlan.free,
          kycStatus: KycStatus.approved,
        );

        const b = NipanzeUser(
          id: 'uuid-1',
          email: 'a@b.com',
          fullName: 'Test',
          subscriptionPlan: SubscriptionPlan.free,
          kycStatus: KycStatus.approved,
        );

        expect(a, equals(b));
        expect(a.hashCode, b.hashCode);
      });

      test('users with different subscription plans are not equal', () {
        const a = NipanzeUser(
          id: 'uuid-1',
          email: 'a@b.com',
          subscriptionPlan: SubscriptionPlan.free,
        );
        const b = NipanzeUser(
          id: 'uuid-1',
          email: 'a@b.com',
          subscriptionPlan: SubscriptionPlan.pro,
        );

        expect(a, isNot(equals(b)));
      });

      test('users with different IDs are not equal', () {
        const a = NipanzeUser(id: '1', email: 'a@b.com');
        const b = NipanzeUser(id: '2', email: 'a@b.com');
        expect(a, isNot(equals(b)));
      });
    });
  });
}
