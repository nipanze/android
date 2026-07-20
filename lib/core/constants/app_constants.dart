class TableNames {
  TableNames._();

  static const String profiles = 'profiles';
  static const String subscriptions = 'subscriptions';
  static const String kycVerifications = 'kyc_verifications';
  static const String loanRequests = 'loan_requests';
  static const String loanOffers = 'loan_offers';
  static const String agreements = 'agreements';
  static const String watchlist = 'watchlist';
  static const String contactReveals = 'contact_reveals';
  static const String notifications = 'notifications';
  static const String auditLogs = 'audit_logs';
  static const String systemSettings = 'system_settings';
  static const String refreshTokens = 'refresh_tokens';
  static const String referrals = 'referrals';
}

class ViewNames {
  ViewNames._();

  static const String loanListings = 'v_loan_listings';
  static const String userMarketplaceActivity = 'v_user_marketplace_activity';
  static const String lenderOffers = 'v_lender_offers';
  static const String marketplaceActivity = 'v_marketplace_activity';
  static const String trustProfilePublic = 'v_trust_profile_public';
  static const String trustProfilePro = 'v_trust_profile_pro';
  // Pro Advanced Filters (schema v4.2)
  static const String marketplaceProFilters = 'v_marketplace_pro_filters';
}

class RpcNames {
  RpcNames._();

  static const String acceptOffer = 'accept_offer';
  static const String getPublicListingOffers = 'get_public_listing_offers';
  static const String unlockContact = 'unlock_contact';
  static const String revealContact = 'reveal_contact';
  // Pro Advanced Filters (schema v4.2)
  static const String getMarketplaceProFiltered = 'get_marketplace_pro_filtered';
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
  static const String networkError =
      'Check your internet connection and try again.';
  static const String sessionExpired =
      'Your session has expired. Please sign in again.';
  static const String kycRequired =
      'Complete KYC verification before posting a listing.';
  static const String subscriptionRequired =
      'An active subscription is required for this action.';

  static String? get nonCustodialDisclaimer => null;
}
