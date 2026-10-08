import 'package:flutter_test/flutter_test.dart';
import 'package:nipanze/features/listings/domain/models/repayment_calculator.dart';

void main() {
  group('RepaymentCalculator', () {
    test('splits the principal into monthly payments', () {
      expect(
        RepaymentCalculator.principalInstallment(
          principal: 700000,
          durationMonths: 5,
          repaymentPlan: 'monthly',
        ),
        140000,
      );
    });

    test('uses four weekly payments per month', () {
      expect(
        RepaymentCalculator.paymentCount(
          durationMonths: 6,
          repaymentPlan: 'weekly',
        ),
        24,
      );
      expect(
        RepaymentCalculator.principalInstallment(
          principal: 700000,
          durationMonths: 6,
          repaymentPlan: 'weekly',
        ),
        29167,
      );
    });

    test('uses one payment for a one-time repayment plan', () {
      expect(
        RepaymentCalculator.principalInstallment(
          principal: 700000,
          durationMonths: 12,
          repaymentPlan: 'one_time',
        ),
        700000,
      );
    });

    test('returns no suggestion until principal and plan are valid', () {
      expect(
        RepaymentCalculator.principalInstallment(
          principal: 0,
          durationMonths: 6,
          repaymentPlan: 'monthly',
        ),
        isNull,
      );
      expect(
        RepaymentCalculator.principalInstallment(
          principal: 100000,
          durationMonths: 0,
          repaymentPlan: 'monthly',
        ),
        isNull,
      );
    });
  });
}
