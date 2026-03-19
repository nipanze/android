/// Supabase table and view names.
/// Use these constants everywhere — never hard-code strings.
abstract class Tables {
  static const users = 'users';
  static const userProfiles = 'user_profiles';
  static const walletBalances = 'wallet_balances';
  static const kycVerifications = 'kyc_verifications';
  static const riskAssessments = 'risk_assessments';
  static const loanRequests = 'loan_requests';
  static const bids = 'bids';
  static const loanContracts = 'loan_contracts';
  static const contractBids = 'contract_bids';
  static const disbursements = 'disbursements';
  static const loanRepayments = 'loan_repayments';
  static const repaymentTransactions = 'repayment_transactions';
  static const notifications = 'notifications';
  static const auditLogs = 'audit_logs';
  static const userNotes = 'user_notes';
  static const systemSettings = 'system_settings';
  static const refreshTokens = 'refresh_tokens';
  static const passwordResetTokens = 'password_reset_tokens';
  static const emailVerificationTokens = 'email_verification_tokens';
}

/// Supabase view names.
abstract class Views {
  static const loanListings = 'v_loan_listings';
  static const activeLoans = 'v_active_loans';
  static const userPortfolio = 'v_user_portfolio';
  static const lenderInvestments = 'v_lender_investments';
  static const loanPerformance = 'v_loan_performance';
}

/// Supabase RPC function names.
abstract class Rpcs {
  static const acceptBid = 'accept_bid';
  static const mockTopUp = 'mock_top_up';
  static const mockDisburse = 'mock_disburse';
  static const mockRepayment = 'mock_repayment';
  static const calculateRepaymentSchedule = 'sp_calculate_repayment_schedule';
  static const calculateReputationScore = 'sp_calculate_reputation_score';
  static const calculateCreditScore = 'sp_calculate_credit_score';
  static const scoreTier = 'fn_score_to_tier';
  static const generateMonthlyReport = 'sp_generate_monthly_report';
}

/// Supabase Storage bucket names.
abstract class Buckets {
  static const kycDocuments = 'kyc-documents';
  static const contracts = 'contracts';
}

/// Supabase Realtime channel prefixes.
abstract class Channels {
  static const bids = 'bids-';
  static const loanRequests = 'loans-';
  static const notifications = 'notifications-';
  static const wallet = 'wallet-';
  static const contracts = 'contracts-';
}

/// Hive box names (UI cache only — not primary database).
abstract class HiveBoxes {
  static const preferences = 'preferences';
  static const cachedLoans = 'cached_loans';
  static const cachedWallet = 'cached_wallet';
}

/// Hive preference keys.
abstract class PrefKeys {
  static const hasSeenOnboarding = 'hasSeenOnboarding';
  static const themeMode = 'themeMode';
  static const biometricsEnabled = 'biometricsEnabled';
  static const lastSyncTimestamp = 'lastSyncTimestamp';
}

/// System settings keys (matches system_settings.setting_key in DB).
abstract class SettingKeys {
  static const platformFeePercentage = 'platform_fee_percentage';
  static const minLoanAmount = 'min_loan_amount';
  static const maxLoanAmount = 'max_loan_amount';
  static const minLoanDuration = 'min_loan_duration';
  static const maxLoanDuration = 'max_loan_duration';
  static const minInterestRate = 'min_interest_rate';
  static const maxInterestRate = 'max_interest_rate';
  static const listingDurationDays = 'listing_duration_days';
  static const kycRequired = 'kyc_required';
  static const kycValidityMonths = 'kyc_validity_months';
  static const lateFeePercentage = 'late_fee_percentage';
  static const gracePeriodDays = 'grace_period_days';
  static const maxConcurrentLoans = 'max_concurrent_loans';
  static const minLenderInvestment = 'min_lender_investment';
}

/// Notification types (matches notifications.type in DB).
abstract class NotificationTypes {
  static const bidReceived = 'bid_received';
  static const bidAccepted = 'bid_accepted';
  static const bidRejected = 'bid_rejected';
  static const contractCreated = 'contract_created';
  static const contractActive = 'contract_active';
  static const repaymentDue = 'repayment_due';
  static const repaymentReceived = 'repayment_received';
  static const disbursementCompleted = 'disbursement_completed';
  static const kycApproved = 'kyc_approved';
  static const kycRejected = 'kyc_rejected';
}
