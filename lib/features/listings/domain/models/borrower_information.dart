class BorrowerInformation {
  const BorrowerInformation({
    required this.employmentStatus,
    required this.isGovernmentEmployee,
    required this.monthlyIncomeRange,
    required this.incomeCurrency,
    this.employerBusinessName,
    this.otherIncomeSource,
    this.preferredBank,
  });

  factory BorrowerInformation.fromMap(Map<String, dynamic> map) {
    return BorrowerInformation(
      employmentStatus: map['employment_status'] as String,
      employerBusinessName: map['employer_business_name'] as String?,
      isGovernmentEmployee: map['is_government_employee'] as bool,
      monthlyIncomeRange: map['monthly_income_range'] as String,
      incomeCurrency: map['income_currency'] as String,
      otherIncomeSource: map['other_income_source'] as String?,
      preferredBank: map['preferred_bank'] as String?,
    );
  }

  final String employmentStatus;
  final String? employerBusinessName;
  final bool isGovernmentEmployee;
  final String monthlyIncomeRange;
  final String incomeCurrency;
  final String? otherIncomeSource;
  final String? preferredBank;

  Map<String, dynamic> toMap(String userId) => {
        'user_id': userId,
        'employment_status': employmentStatus,
        'employer_business_name': _clean(employerBusinessName),
        'is_government_employee': isGovernmentEmployee,
        'monthly_income_range': monthlyIncomeRange,
        'income_currency': incomeCurrency,
        'other_income_source': _clean(otherIncomeSource),
        'preferred_bank': _clean(preferredBank),
      };

  static String? _clean(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
