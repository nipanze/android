class TableNames {
  TableNames._();

  static const String profiles = 'profiles';
  static const String subscriptions = 'subscriptions';
  static const String kycVerifications = 'kyc_verifications';
  static const String loanRequests = 'loan_requests';
  static const String loanBids = 'loan_bids';
  static const String watchlist = 'watchlist';
  static const String contracts = 'contracts';
  static const String repaymentSchedules = 'repayment_schedules';
  static const String negotiators = 'negotiators';
  static const String contactReveals = 'contact_reveals';
  static const String notifications = 'notifications';
  static const String auditLogs = 'audit_logs';
  static const String systemSettings = 'system_settings';
}

class ViewNames {
  ViewNames._();

  static const String loanListings = 'v_loan_listings';
  static const String userPortfolio = 'v_user_portfolio';
  static const String lenderBids = 'v_lender_bids';
  static const String loanPerformance = 'v_loan_performance';
}

class RpcNames {
  RpcNames._();

  static const String acceptBid = 'accept_bid';
  static const String assignNegotiator = 'sp_assign_negotiator';
  static const String generateRepaymentSchedule = 'sp_generate_repayment_schedule';
  static const String calculateReputationScore = 'sp_calculate_reputation_score';
}

class StorageKeys {
  StorageKeys._();

  static const String themeMode = 'theme_mode';
  static const String onboardingSeen = 'onboarding_seen';
}

class StorageBuckets {
  StorageBuckets._();

  static const String kycDocuments = 'kyc-documents';
  static const String contracts = 'contracts';
}

class AppStrings {
  AppStrings._();

  static const String appName = 'Nipanze';
  static const String tagline = 'Non-custodial loan marketplace for Uganda';
  static const String currency = 'UGX';

  // Error messages (user-facing only — internal codes never shown)
  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError = 'Check your internet connection and try again.';
  static const String sessionExpired = 'Your session has expired. Please sign in again.';
  static const String kycRequired = 'Complete KYC verification before posting a listing.';
  static const String subscriptionRequired = 'An active subscription is required for this action.';

  static String? get nonCustodialDisclaimer => null;
}
