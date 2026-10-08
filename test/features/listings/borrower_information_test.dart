import 'package:flutter_test/flutter_test.dart';
import 'package:nipanze/features/listings/domain/models/borrower_information.dart';

void main() {
  group('BorrowerInformation', () {
    test('round-trips the private reusable borrower fields', () {
      const information = BorrowerInformation(
        employmentStatus: 'government_employed',
        employerBusinessName: 'Ministry of XXXXX',
        isGovernmentEmployee: true,
        monthlyIncomeRange: '2m_3m',
        incomeCurrency: 'UGX',
        otherIncomeSource: 'Rental income',
        preferredBank: 'Example Bank',
      );

      final stored = information.toMap('user-1');
      final restored = BorrowerInformation.fromMap(stored);

      expect(stored.keys, {
        'user_id',
        'employment_status',
        'employer_business_name',
        'is_government_employee',
        'monthly_income_range',
        'income_currency',
        'other_income_source',
        'preferred_bank',
      });
      expect(restored.employmentStatus, information.employmentStatus);
      expect(restored.employerBusinessName, information.employerBusinessName);
      expect(restored.isGovernmentEmployee, information.isGovernmentEmployee);
      expect(restored.monthlyIncomeRange, information.monthlyIncomeRange);
      expect(restored.incomeCurrency, information.incomeCurrency);
      expect(restored.otherIncomeSource, information.otherIncomeSource);
      expect(restored.preferredBank, information.preferredBank);
    });

    test('stores empty optional values as null', () {
      const information = BorrowerInformation(
        employmentStatus: 'unemployed',
        isGovernmentEmployee: false,
        monthlyIncomeRange: 'no_regular_income',
        incomeCurrency: 'UGX',
        employerBusinessName: ' ',
        otherIncomeSource: '',
        preferredBank: null,
      );

      final stored = information.toMap('user-1');

      expect(stored['employer_business_name'], isNull);
      expect(stored['other_income_source'], isNull);
      expect(stored['preferred_bank'], isNull);
    });
  });
}
