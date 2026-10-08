class RepaymentCalculator {
  const RepaymentCalculator._();

  static int paymentCount({
    required int durationMonths,
    required String repaymentPlan,
  }) {
    if (durationMonths <= 0) return 0;
    return switch (repaymentPlan) {
      'weekly' => durationMonths * 4,
      'one_time' => 1,
      'monthly' => durationMonths,
      _ => 0,
    };
  }

  static int? principalInstallment({
    required int principal,
    required int durationMonths,
    required String? repaymentPlan,
  }) {
    if (principal <= 0 || repaymentPlan == null) return null;
    final count = paymentCount(
      durationMonths: durationMonths,
      repaymentPlan: repaymentPlan,
    );
    if (count == 0) return null;
    return (principal + count - 1) ~/ count;
  }
}
