import 'package:flutter_test/flutter_test.dart';
import 'package:nipanze/features/marketplace/domain/models/agreement.dart';

void main() {
  group('AgreementStatus', () {
    test('fromString maps values and defaults to pending', () {
      expect(AgreementStatus.fromString('borrower_agreed'),
          AgreementStatus.borrowerAgreed);
      expect(AgreementStatus.fromString('lender_agreed'),
          AgreementStatus.lenderAgreed);
      expect(AgreementStatus.fromString('locked'), AgreementStatus.locked);
      expect(AgreementStatus.fromString('pending'), AgreementStatus.pending);
      expect(AgreementStatus.fromString('unknown'), AgreementStatus.pending);
    });

    test('displayName and helpers', () {
      expect(AgreementStatus.locked.displayName, 'Locked');
      expect(AgreementStatus.locked.isLocked, isTrue);
      expect(AgreementStatus.pending.isLocked, isFalse);
      expect(AgreementStatus.pending.bothAgreed, isFalse);
      expect(AgreementStatus.lenderAgreed.bothAgreed, isTrue);
    });
  });

  group('RepaymentFrequency', () {
    test('fromString maps values and defaults to monthly', () {
      expect(RepaymentFrequency.fromString('weekly'),
          RepaymentFrequency.weekly);
      expect(RepaymentFrequency.fromString('one_time'),
          RepaymentFrequency.oneTime);
      expect(RepaymentFrequency.fromString('monthly'),
          RepaymentFrequency.monthly);
      expect(RepaymentFrequency.fromString('unknown'),
          RepaymentFrequency.monthly);
    });

    test('displayName', () {
      expect(RepaymentFrequency.weekly.displayName, 'Weekly');
      expect(RepaymentFrequency.monthly.displayName, 'Monthly');
      expect(RepaymentFrequency.oneTime.displayName, 'One-time');
    });
  });

  group('Agreement', () {
    final baseMap = {
      'id': 'agr-1',
      'offer_id': 'offer-1',
      'request_id': 'req-1',
      'repayment_frequency': 'monthly',
      'repayment_amount': 100000,
      'repayment_period': 12,
      'total_repayment_amount': 1200000,
      'late_payment_penalty_pct': 2.5,
      'agreement_text': 'Agreement text',
      'status': 'locked',
      'agreement_snapshot': {
        'loan_amount': 1000000,
        'interest_rate_pct': 20.0,
      },
      'created_at': '2026-01-01T00:00:00.000',
      'updated_at': '2026-01-02T00:00:00.000',
    };

    test('fromMap parses snapshot-derived fields', () {
      final agreement = Agreement.fromMap(baseMap);

      expect(agreement.id, 'agr-1');
      expect(agreement.offerId, 'offer-1');
      expect(agreement.requestId, 'req-1');
      expect(agreement.repaymentFrequency, RepaymentFrequency.monthly);
      expect(agreement.repaymentAmount, 100000);
      expect(agreement.repaymentPeriod, 12);
      expect(agreement.totalRepaymentAmount, 1200000);
      expect(agreement.latePenaltyPercentage, 2.5);
      expect(agreement.agreementText, 'Agreement text');
      expect(agreement.loanAmount, 1000000);
      expect(agreement.interestRate, 20.0);
      expect(agreement.status, AgreementStatus.locked);
      expect(agreement.isFullyLocked, isTrue);
      expect(agreement.canBeEdited, isFalse);
    });

    test('fromMap defaults for missing values', () {
      final agreement = Agreement.fromMap({
        'id': 'agr-1',
        'offer_id': 'offer-1',
        'request_id': 'req-1',
      });

      expect(agreement.status, AgreementStatus.pending);
      expect(agreement.loanAmount, 0);
      expect(agreement.interestRate, 0.0);
      expect(agreement.agreementText, '');
      expect(agreement.isDraft, isTrue);
    });

    test('toMap round-trips through fromMap', () {
      final agreement = Agreement.fromMap(baseMap);
      final roundTripped = Agreement.fromMap(agreement.toMap());

      expect(roundTripped, agreement);
    });

    test('copyWith updates only provided fields', () {
      final agreement = Agreement.fromMap(baseMap);
      final updated = agreement.copyWith(status: AgreementStatus.pending);

      expect(updated.status, AgreementStatus.pending);
      expect(updated.id, agreement.id);
      expect(updated.loanAmount, agreement.loanAmount);
    });
  });

  group('ContactRevealData', () {
    test('fromJson parses nested borrower/lender objects', () {
      final data = ContactRevealData.fromJson({
        'agreement_id': 'agr-1',
        'borrower': {
          'full_name': 'James Okello',
          'phone': '+256700000001',
          'email': 'james@test.com',
        },
        'lender': {
          'full_name': 'Invest Pearl',
          'phone': '+256700000002',
          'email': 'invest@test.com',
        },
        'revealed_at': '2026-01-01T00:00:00.000',
      });

      expect(data.agreementId, 'agr-1');
      expect(data.borrowerName, 'James Okello');
      expect(data.borrowerPhone, '+256700000001');
      expect(data.borrowerEmail, 'james@test.com');
      expect(data.lenderName, 'Invest Pearl');
      expect(data.lenderEmail, 'invest@test.com');
    });

    test('fromJson defaults missing values', () {
      final data = ContactRevealData.fromJson({});

      expect(data.agreementId, '');
      expect(data.borrowerName, '');
      expect(data.lenderEmail, '');
    });
  });
}
