// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Nipanze';

  @override
  String get welcomeTitle => 'Borrow. Lend. Grow.';

  @override
  String get welcomeTagline => 'Checkout local listings';

  @override
  String get welcomeSubtitle =>
      'A trusted marketplace connecting borrowers with lenders.';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get choosePreferredLanguage => 'Choose your preferred language';

  @override
  String get continueWithPhone => 'Continue with Phone';

  @override
  String get continueWithEmail => 'Continue with Email';

  @override
  String get getStartedTitle => 'Get started with Nipanze';

  @override
  String get getStartedSubtitle => 'Choose how you would like to proceed';

  @override
  String get createAccount => 'Create Account';

  @override
  String get createAccountSubtitle => 'New to Nipanze? Sign up with phone';

  @override
  String get logIn => 'Log In';

  @override
  String get logInSubtitle => 'Already have an account? Sign in';

  @override
  String get welcomeBack => 'Welcome back 👋';

  @override
  String get loginToAccount => 'Login to your account';

  @override
  String get phone => 'Phone';

  @override
  String get email => 'Email';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get createPassword => 'Create password';

  @override
  String get rememberMe => 'Remember me';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get signUp => 'Sign up';

  @override
  String get enterPhoneTitle => 'Enter your phone number';

  @override
  String get enterPhoneSubtitle => 'We\'ll send you a verification code';

  @override
  String get sendCode => 'Send Verification Code';

  @override
  String get tellUsAboutYou => 'Tell us about you';

  @override
  String get completeProfileSubtitle => 'Create your profile & set a password';

  @override
  String get fullName => 'Full name';

  @override
  String get finish => 'Finish';

  @override
  String get termsNotice =>
      'By continuing, you agree to our Terms of Use and Privacy Policy.';

  @override
  String get phoneSafeTitle => 'Your number is safe with us';

  @override
  String get phoneSafeSubtitle => 'We never share your number with anyone.';

  @override
  String get navMarkets => 'Markets';

  @override
  String get navWatchlist => 'Watchlist';

  @override
  String get navRequest => 'Request';

  @override
  String get navPositions => 'Positions';

  @override
  String get navAccount => 'Account';

  @override
  String get marketplaceTitle => 'Marketplace';

  @override
  String listingsLive(int count) {
    return '$count listings · live';
  }

  @override
  String get filtered => 'Filtered';

  @override
  String get applyingFilters => 'Applying filters…';

  @override
  String get noListingsFound => 'No listings found';

  @override
  String get noListingsSubtitle =>
      'Check back soon — new listings appear in real time.';

  @override
  String get noMatches => 'No matches';

  @override
  String get noMatchesSubtitle =>
      'No active listings match your Pro filters.\nTry adjusting or clearing the filter criteria.';

  @override
  String get adjustFilters => 'Adjust filters';

  @override
  String get removeFromWatchlist => 'Remove from watchlist';

  @override
  String get saveToWatchlist => 'Save to watchlist';

  @override
  String get months => 'months';

  @override
  String daysLeft(int count) {
    return '${count}d left';
  }

  @override
  String hoursLeft(int count) {
    return '${count}h left';
  }

  @override
  String minutesLeft(int count) {
    return '${count}m left';
  }

  @override
  String get expired => 'Expired';

  @override
  String get watchlistTitle => 'Watchlist';

  @override
  String get watchlistSubtitle => 'Listings you\'re tracking';

  @override
  String watchlistSaved(int count) {
    return '$count saved';
  }

  @override
  String get watchlistInfoSubscribed =>
      'Free for all users. Get notified when offers change, rates improve, or a listing is closing.';

  @override
  String get watchlistInfoFree =>
      'Free for all users. Get notified when offers change, rates improve, or a listing is closing. Subscribe to make offers.';

  @override
  String get watchlistError => 'Error loading watchlist';

  @override
  String get watchlistEmpty => 'No saved listings';

  @override
  String get watchlistEmptySubtitle =>
      'Browse the marketplace and tap \"Save to watchlist\" on any listing.';

  @override
  String get browseMarketplace => 'Browse marketplace';

  @override
  String get removedFromWatchlist => 'Removed from watchlist';

  @override
  String get undo => 'Undo';

  @override
  String get tryAgain => 'Try again';

  @override
  String get myActivityTitle => 'My Activity';

  @override
  String get myActivitySubtitle => 'Manage your listings and offers';

  @override
  String myActivityStats(int listings, int offers) {
    return '$listings Listings · $offers Active Offers';
  }

  @override
  String get tabMyRequests => 'My Requests';

  @override
  String get tabMyOffers => 'My Offers';

  @override
  String get noOffersYet => 'No offers yet';

  @override
  String get noOffersSubtitle =>
      'Offers you place on marketplace listings will appear here.';

  @override
  String get browseMarketplaceBtn => 'Browse Marketplace';

  @override
  String get activeOffers => 'Active Offers';

  @override
  String get matchedAccepted => 'Matched / Accepted';

  @override
  String get history => 'History';

  @override
  String get withdrawOffer => 'Withdraw Offer?';

  @override
  String withdrawConfirm(int amount) {
    return 'Are you sure you want to withdraw your offer for UGX $amount?';
  }

  @override
  String get keepOffer => 'Keep Offer';

  @override
  String get withdraw => 'Withdraw';

  @override
  String get myRequestsTitle => 'My Requests';

  @override
  String sectionActive(int count) {
    return 'Active · $count';
  }

  @override
  String sectionContracted(int count) {
    return 'Contracted · $count';
  }

  @override
  String sectionClosed(int count) {
    return 'Closed · $count';
  }

  @override
  String get noLoanRequests => 'No loan requests yet';

  @override
  String get noLoanRequestsSubtitle =>
      'Post a request and lenders will compete to offer you the best rate.';

  @override
  String get createLoanRequest => 'Create a loan request';

  @override
  String get cancelListing => 'Cancel listing?';

  @override
  String cancelListingConfirm(String title) {
    return 'This will remove \"$title\" from the marketplace. Any pending offers will be rejected. This cannot be undone.';
  }

  @override
  String get keepIt => 'Keep it';

  @override
  String get cancelListingBtn => 'Cancel listing';

  @override
  String get contractNotGenerated => 'Contract not yet generated.';

  @override
  String get viewOffers => 'View offers';

  @override
  String get viewContract => 'View contract';

  @override
  String get viewListing => 'View listing';

  @override
  String get offeredAmountLabel => 'Offered amount';

  @override
  String get statusLabel => 'Status';

  @override
  String get interestLabel => 'Interest';

  @override
  String get lateFeeLabel => 'Late fee';

  @override
  String lateFeePerMissedInstallment(String value) {
    return '$value per missed installment';
  }

  @override
  String get repaymentLabel => 'Repayment';

  @override
  String get totalPayableLabel => 'Total payable';

  @override
  String sentDateLabel(String date) {
    return 'Sent $date';
  }

  @override
  String errorLoadingContract(String error) {
    return 'Error loading contract: $error';
  }

  @override
  String listingOfferCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'offers',
      one: 'offer',
    );
    return '$count $_temp0';
  }

  @override
  String get accountTitle => 'Account';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get contactUs => 'Contact Us';

  @override
  String get community => 'Community';

  @override
  String get legal => 'Legal';

  @override
  String get signOut => 'Sign Out';

  @override
  String get signOutConfirm =>
      'Are you sure you want to sign out of your account?';

  @override
  String get cancel => 'Cancel';

  @override
  String get profileUpdated => 'Profile updated.';

  @override
  String get profileSaved => 'Profile saved.';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get changeProfilePicture => 'Change profile picture';

  @override
  String get phoneNumberLabel => 'Phone number';

  @override
  String selectRegionLabel(String label) {
    return 'Select $label';
  }

  @override
  String get incomeTypeLabel => 'Income type';

  @override
  String get selectIncomeType => 'Select income type';

  @override
  String get employerBusinessOptionalLabel =>
      'Employer / Business name (optional)';

  @override
  String monthlyIncomeWithCurrency(String currency) {
    return 'Monthly income ($currency)';
  }

  @override
  String get bankProfessionalTagLabel => 'Bank & Professional Tag';

  @override
  String get preferredDepositBankLabel =>
      'Preferred or deposit bank (optional)';

  @override
  String get preferredDepositBankHint =>
      'e.g. Equity Bank, Bank of Kigali, Stanbic, KCB';

  @override
  String get accountRepresentsLabel => 'Account represents';

  @override
  String get individualPersonalAccountLabel => 'Individual / Personal account';

  @override
  String get bankLabel => 'Bank';

  @override
  String get forexExchangeCompanyLabel => 'Forex exchange company';

  @override
  String get saccoLabel => 'SACCO';

  @override
  String get companyLabel => 'Company';

  @override
  String get bankLoanAgentLabel => 'I am a bank loan agent';

  @override
  String get bankLoanAgentSubtitle =>
      'Shows a bank-agent tag to Pro users seeking bank loans.';

  @override
  String get showProfessionalTagLabel => 'Show my professional tag';

  @override
  String get showProfessionalTagSubtitle =>
      'Turn off to hide bank, forex company, SACCO, or agent labels on offers.';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get enterFullName => 'Enter your full name';

  @override
  String avatarUploadFailed(String error) {
    return 'Avatar upload failed: $error';
  }

  @override
  String couldNotSelectImage(String error) {
    return 'Could not select image: $error';
  }

  @override
  String get identityVerification => 'Identity Verification';

  @override
  String get security => 'Security';

  @override
  String get notifications => 'Notifications';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get noNotificationsYet => 'No notifications yet';

  @override
  String get noNotificationsSubtitle =>
      'You\'ll be notified here when offers arrive, rates change, or contracts are ready.';

  @override
  String get todayLabel => 'TODAY';

  @override
  String get yesterdayLabel => 'YESTERDAY';

  @override
  String get earlierLabel => 'EARLIER';

  @override
  String get tapToView => 'Tap to view';

  @override
  String get justNow => 'just now';

  @override
  String get statListings => 'Listings';

  @override
  String get statListingsSubtitle => 'Posted requests';

  @override
  String get statOffers => 'Offers';

  @override
  String get statOffersSubtitle => 'Offers made';

  @override
  String get statMatches => 'Matches';

  @override
  String get statMatchesSubtitle => 'Successful matches';

  @override
  String get trustReputation => 'Trust & Reputation';

  @override
  String get subscription => 'Subscription';

  @override
  String get upgradeToPro => 'Upgrade to Pro';

  @override
  String get viewPlansUpgrade => 'View plans & upgrade';

  @override
  String get adminDashboard => 'Admin dashboard';

  @override
  String memberSince(String date) {
    return 'Member since $date';
  }

  @override
  String get verified => 'Verified';

  @override
  String get districtNotSet => 'District not set';

  @override
  String get nipanzeDisclaimer =>
      'Nipanze is a non-custodial matchmaking platform. We do not hold, move, or settle funds. All transactions occur direct between participants.';

  @override
  String get lenderRequired => 'Lender required';

  @override
  String get lenderRequiredSubtitle =>
      'Making offers is part of the Lender plan (also included in Pro). Upgrade to unlock offer placement on any listing.';

  @override
  String get lenderTier => 'Lender tier';

  @override
  String get lenderTierDesc =>
      'For anyone ready to make structured offers and earn returns on Nipanze.';

  @override
  String get everythingInFree => 'Everything in Free';

  @override
  String get lenderFeature1 =>
      'Make offers with full terms (rate, fee, schedule)';

  @override
  String get lenderFeature2 => 'See offer detail where you participate';

  @override
  String get chooseLender => 'Choose Lender';

  @override
  String get notNow => 'Not now';

  @override
  String get paymentSecurityDisclaimer =>
      'Nipanze does not hold or move funds. Subscription changes are confirmed through a secure payment flow.';

  @override
  String get proRequired => 'Pro tier required';

  @override
  String get proRequiredSubtitle =>
      'Advanced features like custom term proposals and advanced filters are reserved for Pro subscribers.';

  @override
  String get proTier => 'Pro tier';

  @override
  String get proTierDesc =>
      'Full marketplace access, advanced filters and strong request positioning.';

  @override
  String get everythingInLender => 'Everything in Lender';

  @override
  String get proFeature1 => 'Suggest rates, late fees and repayment terms';

  @override
  String get proFeature2 => 'Advanced filters (income, employment, verified)';

  @override
  String get proFeature3 =>
      'Verified badge, reliability score and priority visibility';

  @override
  String get choosePro => 'Choose Pro';

  @override
  String get plansAndPricing => 'Plans & pricing';

  @override
  String get chooseAccessTitle => 'Choose the access you need';

  @override
  String chooseAccessSubtitle(String flag, String country) {
    return 'One account can post requests and make offers. Prices match your account region ($flag $country).';
  }

  @override
  String get perMonth => ' / month';

  @override
  String get freePlanSubtitle =>
      'Browse, watch listings, post basic requests, and accept offers.';

  @override
  String get freeFeature1 => 'Browse the marketplace';

  @override
  String get freeFeature2 => 'Post basic loan requests';

  @override
  String get freeFeature3 => 'Accept offers received';

  @override
  String get currentPlan => 'Current plan';

  @override
  String get useFree => 'Use Free';

  @override
  String choosePlan(String plan) {
    return 'Choose $plan';
  }

  @override
  String planSelectedMessage(String plan) {
    return '$plan selected. Secure payment activation will be available shortly.';
  }

  @override
  String get unlockDealTitle => 'Unlock deal';

  @override
  String get unlockDealAndContact => 'Unlock deal & contact';

  @override
  String get dealAgreementLocked => 'Deal agreement locked';

  @override
  String get dealAgreementLockedSubtitle =>
      'Both borrower and lender have confirmed the deal. You can now unlock contact details to connect directly.';

  @override
  String includedInPlan(String plan) {
    return 'Included in your $plan plan';
  }

  @override
  String get unlimitedUnlocksSubtitle =>
      'Unlimited contact unlocks at no extra fee.';

  @override
  String welcomeGiftUnlocks(int count) {
    return '🎁 Welcome gift — $count free unlock(s) remaining';
  }

  @override
  String get welcomeGiftSubtitle =>
      'This deal uses one of your free unlocks. Additional unlocks cost UGX 5,000.';

  @override
  String get unlockFeeApplies => 'UGX 5,000 unlock fee applies';

  @override
  String get unlockFeeAppliesSubtitle =>
      'Your welcome unlock has been used. Upgrade to Lender or Pro for unlimited free unlocks.';

  @override
  String get whatHappensNext => 'What happens next';

  @override
  String get step1Title => 'Contact details revealed';

  @override
  String get step1Desc =>
      'Legal name, phone, and email of both parties will be shared.';

  @override
  String get step2Title => 'Direct connection';

  @override
  String get step2Desc =>
      'You can now contact your partner outside the Nipanze platform.';

  @override
  String get step3Title => 'Complete transaction';

  @override
  String get step3Desc =>
      'Finalize the loan agreement and exchange funds directly.';

  @override
  String get disclaimerNonCustodial =>
      'Nipanze does not hold or move any funds. You and your partner are solely responsible for all financial transactions and dispute resolution.';

  @override
  String get payToUnlock => 'Pay UGX 5,000 to Unlock';

  @override
  String get unlockWithFreeCredit => 'Unlock with Free Credit';

  @override
  String get unlockContactDetails => 'Unlock contact details';

  @override
  String get upgradeForUnlimited => 'Upgrade for unlimited unlocks';

  @override
  String get contactDetailsRevealed => 'Contact details revealed';

  @override
  String get connectionSuccessful =>
      'Connection successful. Here are the contact details:';

  @override
  String get borrower => 'Borrower';

  @override
  String get lender => 'Lender';

  @override
  String get directContactNotice =>
      'You can now contact your partner directly to complete the transaction outside of the Nipanze platform.';

  @override
  String get done => 'Done';

  @override
  String planTitle(String plan) {
    return '$plan plan';
  }

  @override
  String get nonCustodialAccess => 'Non-custodial access';

  @override
  String get howTrustWorks => 'How trust works';

  @override
  String get trustExplanation =>
      'Trust signals reflect only activity completed through Nipanze. They do not assess or imply off-platform repayment behaviour.';

  @override
  String get trustScore => 'Trust score';

  @override
  String get completeDealsToBuild => 'Complete deals to build your score';

  @override
  String get noReviewsYet => 'No reviews yet';

  @override
  String successfulDeals(int count) {
    return '$count successful deals';
  }

  @override
  String get repeatParticipant => 'Repeat participant';

  @override
  String get notRepeatYet => 'Not a repeat yet';

  @override
  String get phoneVerified => 'Phone verified';

  @override
  String get phoneNotVerified => 'Phone not verified';

  @override
  String get publicTrustSignals =>
      'Public trust signals are based only on activity completed through Nipanze.';

  @override
  String get advancedFilters => 'Advanced Filters';

  @override
  String get advancedFiltersBadge => 'Pro · Narrow the marketplace feed';

  @override
  String get filterReset => 'Reset';

  @override
  String get filterClear => 'Clear';

  @override
  String get filterApply => 'Apply filters';

  @override
  String get filterDone => 'Done';

  @override
  String get filterEmploymentType => 'Employment type';

  @override
  String get filterEmploymentSubtitle =>
      'Filter by the borrower\'s declared employment';

  @override
  String get filterIncomeRange => 'Monthly income range';

  @override
  String get filterIncomeSubtitle =>
      'Coarse brackets — exact income is never shown';

  @override
  String get filterQualitySignals => 'Listing quality signals';

  @override
  String get filterHasSuggestedTerms => 'Has suggested terms';

  @override
  String get filterHasSuggestedTermsSubtitle =>
      'Only Pro-posted listings that carry a locked interest rate, late fee, and repayment schedule';

  @override
  String get filterVerifiedBorrower => 'Verified borrower';

  @override
  String get filterVerifiedBorrowerSubtitle =>
      'Only requests from KYC-approved account holders';

  @override
  String get filterPrivacyNote =>
      'Employer names and exact income are never shown. Income brackets and employment categories are the only signals available, by design.';

  @override
  String get empGovEmployee => 'Government employee';

  @override
  String get empEmployedPrivate => 'Employed (private)';

  @override
  String get empSelfEmployed => 'Self-employed';

  @override
  String get empSmallBusinessOwner => 'Small business owner';

  @override
  String get empBusinessOwner => 'Business owner';

  @override
  String get empStudent => 'Student';

  @override
  String get empOther => 'Other';

  @override
  String get incomeUnder2m => 'Under 2M UGX / month';

  @override
  String get income2m5m => '2M – 5M UGX / month';

  @override
  String get income5m10m => '5M – 10M UGX / month';

  @override
  String get incomeOver10m => 'Over 10M UGX / month';

  @override
  String get iHold => 'I hold';

  @override
  String get rate => 'Rate';

  @override
  String get iNeed => 'I need';

  @override
  String get marketRate => 'Market rate';

  @override
  String get stepIncomeRepayment => 'Income & repayment';

  @override
  String get stepReviewPublish => 'Review & publish';

  @override
  String get requestALoan => 'Request a loan';

  @override
  String stepCounter(int current, int total, String subtitle) {
    return 'Step $current of $total · $subtitle';
  }

  @override
  String get subtitleLoanDetails => 'loan details';

  @override
  String get subtitleRepaymentContext => 'repayment context';

  @override
  String get subtitleReview => 'review';

  @override
  String get panelTheBasics => 'The basics';

  @override
  String get panelTheNumbers => 'The numbers';

  @override
  String get panelLocationDetails => 'Location and details';

  @override
  String get panelRepaymentSource => 'Repayment source';

  @override
  String get panelAbilityToRepay => 'Ability to repay';

  @override
  String get panelPreferredTerms => 'Preferred terms';

  @override
  String get requestTitleLabel => 'Request title';

  @override
  String get requestTitleHint => 'e.g. Delivery van for Kampala route';

  @override
  String get purposeLabel => 'Purpose';

  @override
  String get selectPurposeHint => 'Select purpose';

  @override
  String get describePurposeLabel => 'Describe your purpose';

  @override
  String amountLabelWithCurrency(String currency) {
    return 'Amount ($currency)';
  }

  @override
  String get amountHintLoan => '7,000,000';

  @override
  String get durationLabel => 'Duration';

  @override
  String get durationHintMonths => '6 months';

  @override
  String get descriptionOptionalLabel => 'Description (optional)';

  @override
  String get descriptionOptionalHint => 'Add any context lenders should know';

  @override
  String get incomeSourceLabel => 'Income source';

  @override
  String get incomeSourceHint => 'e.g. Salary, shop income, farming, side work';

  @override
  String get preferredRepaymentPlanLabel => 'Preferred repayment plan';

  @override
  String get selectRepaymentPlanHint => 'Select repayment plan';

  @override
  String repaymentAmountPerPeriodLabel(String currency) {
    return 'Repayment amount per period ($currency)';
  }

  @override
  String get repaymentAmountHint => 'e.g. 250,000';

  @override
  String get repaymentTimelineLabel => 'Repayment timeline & schedule';

  @override
  String get repaymentTimelineHint =>
      'e.g. Paid by the 5th of every month by 5:00 PM for 8 months';

  @override
  String get dueDayLabel => 'Due day / frequency';

  @override
  String get dueDayHint => 'Select due day (e.g. 5th of every month)';

  @override
  String get dueCutoffTimeLabel => 'Due cutoff time (for late fee timing)';

  @override
  String get dueCutoffTimeHint => 'Select due time (e.g. 5:00 PM)';

  @override
  String get timelineHelperText =>
      'Exact day & cutoff time used for late fee calculations';

  @override
  String get suggestedInterestRateLabel => 'Suggested interest rate (%)';

  @override
  String get suggestedLateFeeLabel => 'Suggested late payment fee (%)';

  @override
  String get suggestedRepaymentScheduleLabel => 'Suggested repayment schedule';

  @override
  String suggestedInstallmentAmountLabel(String currency) {
    return 'Suggested installment amount ($currency)';
  }

  @override
  String get validationTitleRequired => 'Enter a title';

  @override
  String get validationTitleMinLength => 'Use at least 4 characters';

  @override
  String get validationPurposeRequired => 'Select a purpose';

  @override
  String get validationPurposeContinue => 'Select a purpose to continue.';

  @override
  String get validationAmountRequired => 'Enter an amount';

  @override
  String get validationValidNumber => 'Enter a valid number';

  @override
  String validationMinAmount(String currency, String min) {
    return 'Minimum $currency $min';
  }

  @override
  String validationMaxAmount(String currency, String max) {
    return 'Maximum $currency $max';
  }

  @override
  String get validationDurationRequired => 'Enter duration';

  @override
  String get validationDurationRange => '1 to 60 months';

  @override
  String get validationIncomeSourceRequired => 'Enter your repayment source';

  @override
  String get validationIncomeSourceDetail => 'Add a little more detail';

  @override
  String get validationRepaymentPlanRequired => 'Select a repayment plan';

  @override
  String get validationRepaymentPlanContinue =>
      'Select a repayment plan to continue.';

  @override
  String get validationRepaymentAmountRequired => 'Enter repayment amount';

  @override
  String get validationRepaymentAmountValid => 'Enter a valid amount';

  @override
  String get validationRepaymentTimelineRequired => 'Enter repayment timeline';

  @override
  String get validationRepaymentTimelineDetail => 'Add a clearer timeline';

  @override
  String get validationPercentRange => 'Use 0 to 100';

  @override
  String get btnContinue => 'Continue';

  @override
  String get btnPublishToMarketplace => 'Publish to marketplace';

  @override
  String get btnBack => 'Back';

  @override
  String get reviewYourRequest => 'Review your request';

  @override
  String get reviewConfirmDetails =>
      'Confirm the details before publishing to the marketplace.';

  @override
  String get reviewTitle => 'Title';

  @override
  String get reviewAmount => 'Amount';

  @override
  String get reviewDuration => 'Duration';

  @override
  String get reviewPurpose => 'Purpose';

  @override
  String get reviewIncomeSource => 'Income source';

  @override
  String get reviewPreferredRepaymentPlan => 'Preferred repayment plan';

  @override
  String get reviewRepaymentAmount => 'Repayment amount';

  @override
  String get reviewRepaymentTimeline => 'Repayment timeline';

  @override
  String get reviewDescription => 'Description';

  @override
  String get reviewLockedTerms => 'Locked preferred terms';

  @override
  String get reviewPerPeriod => 'per period';

  @override
  String get reviewContactPrivacyNotice =>
      'Your contact details stay hidden until an offer is accepted and the unlock flow is completed.';

  @override
  String get requestSubmittedTitle => 'Request submitted';

  @override
  String get requestSubmittedContent =>
      'Your loan request is now live on the marketplace. Lenders can review it and make offers.';

  @override
  String get couldNotPublishRequest =>
      'Could not publish this request. Try again.';

  @override
  String get kycGateListing =>
      'Complete KYC verification before posting a listing.';

  @override
  String get notAllowedListing =>
      'Your account is not allowed to post a listing.';

  @override
  String infoBannerText(String currency, String min, String max) {
    return '$currency $min-$max · Up to 60 months · terms lock on publish';
  }

  @override
  String get termsLockedNotice => 'Locked when the request is published.';

  @override
  String get upgradeToProForTerms =>
      'Upgrade to Pro to suggest interest, late fee, and repayment terms.';

  @override
  String get purposeAgri => 'Agricultural equipment';

  @override
  String get purposeBusiness => 'Business expansion';

  @override
  String get purposeEdu => 'Education / School fees';

  @override
  String get purposeMedical => 'Emergency medical';

  @override
  String get purposeFarming => 'Greenhouse / Farming';

  @override
  String get purposeHome => 'Home improvement';

  @override
  String get purposeStock => 'Inventory / Stock';

  @override
  String get purposeLand => 'Land purchase';

  @override
  String get purposeLivestock => 'Livestock';

  @override
  String get purposeEnergy => 'Solar / Energy';

  @override
  String get purposeVehicle => 'Transport / Vehicle';

  @override
  String get purposeWater => 'Water & Sanitation';

  @override
  String get purposeWedding => 'Wedding / Event';

  @override
  String get purposeOther => 'Other';

  @override
  String get planMonthly => 'Monthly';

  @override
  String get planWeekly => 'Weekly';

  @override
  String get planOneTime => 'One-time payment';

  @override
  String get createForexRequestTitle => 'Create Forex Request';

  @override
  String get forexCurrencyHeld => 'Currency you hold';

  @override
  String get forexCurrencyNeeded => 'Currency you need';

  @override
  String get forexAmountToExchange => 'Amount to exchange';

  @override
  String get forexAmountHint => 'e.g. 100';

  @override
  String get forexPreferredRate => 'Preferred exchange rate';

  @override
  String get forexRateHint => 'e.g. 3700';

  @override
  String get forexSettlementPreference => 'Settlement preference';

  @override
  String get selectSettlementHint => 'Select settlement';

  @override
  String get forexPublishBtn => 'Publish forex request';

  @override
  String get kycGateForex =>
      'Complete KYC verification before posting a forex request.';

  @override
  String get couldNotPublishForex => 'Could not publish this forex request.';

  @override
  String get forexSettlementInPerson => 'In person';

  @override
  String get forexSettlementMobileMoney => 'Mobile money';

  @override
  String get forexSettlementBankTransfer => 'Bank transfer';

  @override
  String get forexSettlementOther => 'Other';

  @override
  String get forexRequestTitle => 'Forex request';

  @override
  String get myForexRequestsTitle => 'My forex requests';

  @override
  String get noForexRequestsYet => 'No forex requests yet.';

  @override
  String get listingDetailTitle => 'Listing detail';

  @override
  String get offersLabel => 'OFFERS';

  @override
  String get loanRequestTitle => 'Loan request';

  @override
  String get makeAnOffer => 'Make an offer';

  @override
  String get makeAnOfferToUnlock => 'Make an offer to unlock full details';

  @override
  String get onlyYourOfferVisible =>
      'Only your offer is visible here. The full bid book is visible to the borrower.';

  @override
  String get securedCollateralLabel => 'Secured';

  @override
  String get noCollateralLabel => 'No collateral';

  @override
  String get collateralLabel => 'Collateral';

  @override
  String get estimatedValueLabel => 'Estimated value';

  @override
  String get locationLabel => 'Location';

  @override
  String get offerSubmittedReviewNotice =>
      'Offer submitted. You can review your offer above.';

  @override
  String offerCountdownLabel(String time) {
    return '$time left';
  }

  @override
  String get expiredLabel => 'Expired';

  @override
  String get offerSentSuccessfully => 'Offer sent successfully.';

  @override
  String get interestRateLabel => 'Interest rate (%)';

  @override
  String get latePaymentFeeLabel => 'Late payment fee (%)';

  @override
  String get repaymentScheduleLabel => 'Repayment schedule';

  @override
  String get monthly => 'Monthly';

  @override
  String get weekly => 'Weekly';

  @override
  String get oneTimePayment => 'One-time payment';

  @override
  String installmentAmountLabel(String currency) {
    return 'Installment amount ($currency)';
  }

  @override
  String get additionalExpectationsLabel => 'Additional expectations';

  @override
  String get optionalBorrowerNotesHint => 'Optional notes for the borrower';

  @override
  String get sendOffer => 'Send Offer';

  @override
  String get couldNotSendOffer => 'Could not send offer.';

  @override
  String get rateOfferedLabel => 'Rate offered';

  @override
  String get amountAvailableLabel => 'Amount available';

  @override
  String get forexAmountToServe => 'Amount to be served';

  @override
  String get forexServesLabel => 'Serves';

  @override
  String get amountToExchangeOut => 'Amount to exchange out';

  @override
  String get settlementTermsLabel => 'Settlement terms';

  @override
  String get activeListingLabel => 'Active listing';

  @override
  String get fundedLabel => 'Funded';

  @override
  String userVerificationStatus(String status) {
    return 'User verification status: $status';
  }

  @override
  String interestPercent(String value) {
    return '$value% interest';
  }

  @override
  String get proposedRepaymentPlanLabel => 'Proposed repayment plan';

  @override
  String get yourOfferLabel => 'Your offer';

  @override
  String lenderNumberLabel(int number) {
    return 'Lender #$number';
  }

  @override
  String lenderTextLabel(String id) {
    return 'Lender #$id';
  }

  @override
  String get fullOfferLabel => 'Full offer';

  @override
  String partialOfferLabel(int coverage) {
    return 'Partial · $coverage%';
  }

  @override
  String vsAskLabel(String value) {
    return '$value vs ask';
  }

  @override
  String get lenderNotesLabel => 'Lender notes';

  @override
  String get acceptOfferLabel => 'Accept offer';

  @override
  String get fullCoverageOfferLabel => 'Full coverage offer';

  @override
  String partialCoverageLabel(int coverage) {
    return 'Partial coverage · $coverage%';
  }

  @override
  String totalPayablePaymentsLabel(int periods) {
    return 'Total payable ($periods payments)';
  }

  @override
  String borrowingCostLabel(String amount) {
    return 'Borrowing cost: $amount';
  }

  @override
  String get flutterwaveCheckoutTitle => 'Flutterwave Checkout';

  @override
  String get orderSummary => 'Order Summary';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get mobileMoney => 'Mobile Money';

  @override
  String get creditOrDebitCard => 'Credit / Debit Card';

  @override
  String get phoneOrAccount => 'Phone / Account Number';

  @override
  String get enterMobileNumber => 'Enter Mobile Money phone number';

  @override
  String get payWithFlutterwave => 'Pay with Flutterwave';

  @override
  String get processingPayment => 'Processing Flutterwave Payment…';

  @override
  String get paymentSuccessful => 'Payment Successful!';

  @override
  String subscriptionActivated(Object plan) {
    return 'Your $plan subscription is now active.';
  }

  @override
  String get paymentFailed => 'Payment failed. Please try again.';

  @override
  String get paymentStep1 => 'Details';

  @override
  String get paymentStep2 => 'Processing';

  @override
  String get paymentStep3 => 'Done';

  @override
  String get paymentProcessingStep1 => 'Connecting to Flutterwave…';

  @override
  String get paymentProcessingStep2 => 'Verifying payment…';

  @override
  String get paymentProcessingStep3 => 'Activating subscription…';

  @override
  String transactionRef(String ref) {
    return 'Ref: $ref';
  }

  @override
  String get poweredByFlutterwave => 'Powered by Flutterwave';

  @override
  String enterMobileNumberForProvider(String provider) {
    return '$provider phone number';
  }

  @override
  String mobileMoneyPromptHint(String provider) {
    return 'You\'ll receive a $provider prompt on your phone to approve the payment.';
  }

  @override
  String get prefilledFromAccount => 'Pre-filled from your account';

  @override
  String get editPhoneNumber => 'Edit';

  @override
  String get lockPhoneNumber => 'Lock';

  @override
  String get liveCalcTitle => 'Repayment breakdown';

  @override
  String get liveCalcLoanAmount => 'Loan amount';

  @override
  String get liveCalcPlan => 'Repayment plan';

  @override
  String get liveCalcDuration => 'Duration';

  @override
  String get liveCalcInstallment => 'Per period installment';

  @override
  String get liveCalcTotalPayments => 'Total payments';

  @override
  String get liveCalcTotalPayback => 'Total payback';

  @override
  String get liveCalcBorrowingCost => 'Borrowing cost';

  @override
  String get liveCalcNoData =>
      'Fill in the fields above to see your repayment breakdown.';

  @override
  String get freeTermsBanner =>
      'Leave this blank — lenders will propose their own terms. Upgrade to Pro to suggest rates.';

  @override
  String get offerReadOnlyNotice =>
      'Review the lender\'s proposed terms below. Accept or wait for a better offer.';

  @override
  String get sponsoredLabel => 'Sponsored';

  @override
  String get borrowerTermsMissing => '—';

  @override
  String get repaymentCalcFormula =>
      'installment × number of payments = total payback';

  @override
  String liveCalcWeeklyNote(int months, int count) {
    return 'Weekly plan: $months months × 4 = $count payments';
  }

  @override
  String liveCalcMonthlyNote(int count) {
    return '$count monthly payments';
  }

  @override
  String get liveCalcOneTimeNote => '1 lump-sum payment';
}
