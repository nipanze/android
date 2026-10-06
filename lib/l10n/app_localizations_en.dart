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
      'Your trusted marketplace with authentic providers.';

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
  String get navPositions => 'Activity';

  @override
  String get navAccount => 'Account';

  @override
  String get marketplaceTitle => 'Nipanze';

  @override
  String listingsLive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count active listings',
      one: '$count active listing',
    );
    return '$_temp0';
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
  String get marketplaceForYou => 'For You';

  @override
  String get marketplaceAll => 'All';

  @override
  String get marketplaceLoan => 'Loan';

  @override
  String get marketplaceLoans => 'Loans';

  @override
  String get marketplaceForex => 'Forex';

  @override
  String get marketplaceNeeds => 'Needs';

  @override
  String get marketplaceNeeded => 'Needed';

  @override
  String get declareCapabilityToBidTitle => 'Service Capability Required';

  @override
  String get declareCapabilityToBidMessage =>
      'To submit an offer on this request, you must first declare that you offer services in this category.';

  @override
  String get declareServiceNow => 'Add Service & Continue';

  @override
  String get postServiceAction => 'Offer a Service';

  @override
  String get postServiceSubtitle =>
      'List your services and get matched with client requests';

  @override
  String get viewDetails => 'View details';

  @override
  String get proAdvancedFilters => 'Pro advanced filters';

  @override
  String get today => 'Today';

  @override
  String get weekAgo => '1 week ago';

  @override
  String daysAgo(int count) {
    return '$count days ago';
  }

  @override
  String weeksAgo(int count) {
    return '$count weeks ago';
  }

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
  String get tabDeals => 'Deals';

  @override
  String get noDealsYet => 'No deals yet';

  @override
  String get noDealsSubtitle =>
      'When an offer is accepted by you or a partner, your active deals and contracts will appear here.';

  @override
  String get noOffersYet => 'No offers yet';

  @override
  String get noOffersSubtitle =>
      'Offers you place on listings will appear here.';

  @override
  String get browseMarketplaceBtn => 'Browse';

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
      'Post a request and Providers will compete to offer you the best rate.';

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
  String get viewContract => 'View Deal';

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
  String get phoneNumberLabel => 'Phone Number';

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
  String get choosePhoto => 'Choose photo';

  @override
  String get selectPhotoSource => 'Select where to pick your profile photo';

  @override
  String get takePhoto => 'Take a photo';

  @override
  String get useCamera => 'Use your camera';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get pickExistingPhoto => 'Pick an existing photo';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get removePhotoSubtitle => 'Delete current profile picture';

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
  String get lenderRequired => 'Provider access required';

  @override
  String get lenderRequiredSubtitle =>
      'Making offers is part of the Provider plan (also included in Pro). Upgrade to unlock offer placement across Loans, Forex and Needs.';

  @override
  String get lenderTier => 'Provider plan';

  @override
  String get lenderTierDesc =>
      'For anyone ready to make structured offers and participate on the supply side of Nipanze.';

  @override
  String get everythingInFree => 'Everything in Free';

  @override
  String get lenderFeature1 =>
      'Make offers with full terms (rate, fee, schedule)';

  @override
  String get lenderFeature2 => 'See offer detail where you participate';

  @override
  String get chooseLender => 'Choose Provider';

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
      'Priority visibility, improved matching and stronger marketplace performance.';

  @override
  String get everythingInLender => 'Everything in Provider';

  @override
  String get proFeature1 => 'Preferred loan terms and Forex rate';

  @override
  String get proFeature2 => 'Priority visibility and improved matching';

  @override
  String get proFeature3 => 'Verified badge and advanced trust insights';

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
  String get freeFeature2 => 'Post up to 2 active loan requests';

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
      'Both Requester and Provider have confirmed the deal. You can now unlock contact details to connect directly.';

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
      'Your welcome unlock has been used. Upgrade to Provider or Pro for unlimited free unlocks.';

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
  String get lender => 'Provider';

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
  String get descriptionOptionalHint => 'Add any context providers should know';

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
      'Your loan request is now live on the marketplace. Providers can review it and make offers.';

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
  String get hasCollateralLabel => 'Has collateral';

  @override
  String get collateralLabel => 'Collateral';

  @override
  String get collateralPromptText =>
      'Choose whether this request is backed by an asset.';

  @override
  String get collateralDetailsLabel => 'Collateral details';

  @override
  String get collateralDetailsHint =>
      'e.g. Land title, car, electronics, equipment';

  @override
  String get collateralAssetRequired => 'Describe the collateral asset';

  @override
  String get collateralAssetDetailShort => 'Add a little more detail';

  @override
  String collateralValueLabel(String currency) {
    return 'Est. value ($currency)';
  }

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
    return 'Provider #$number';
  }

  @override
  String lenderTextLabel(String id) {
    return 'Provider #$id';
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
  String get lenderNotesLabel => 'Provider notes';

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
  String get totalAmountPayableLabel => 'Total amount payable';

  @override
  String get totalInterestLabel => 'Total interest';

  @override
  String get liveCalcNoData =>
      'Fill in the fields above to see your repayment breakdown.';

  @override
  String get freeTermsBanner =>
      'Leave this blank — providers will propose their own terms. Upgrade to Pro to suggest rates.';

  @override
  String get offerReadOnlyNotice =>
      'Review the provider\'s proposed terms below. Accept or wait for a better offer.';

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

  @override
  String get kycGateTitle => 'Verify your identity first';

  @override
  String get kycGateBody =>
      'To post Loan, Forex or Needs requests and connect with Providers, you need to complete identity verification. It only takes a few minutes.';

  @override
  String get kycGatePendingTitle => 'Verification in review';

  @override
  String get kycGatePendingBody =>
      'Your identity documents are being reviewed. You\'ll be notified as soon as your account is approved.';

  @override
  String get kycGateRejectedTitle => 'Verification rejected';

  @override
  String get kycGateRejectedBody =>
      'Your KYC submission was not approved. Please re-submit with valid documents.';

  @override
  String get kycGateExpiredTitle => 'Verification expired';

  @override
  String get kycGateExpiredBody =>
      'Your KYC verification has expired. Please re-submit to continue posting requests.';

  @override
  String get kycStep1 => 'Submit your national ID or passport';

  @override
  String get kycStep2 => 'Wait for review (usually within 24 hours)';

  @override
  String get kycStep3 => 'Post requests once approved';

  @override
  String get kycGateCta => 'Start verification';

  @override
  String get kycGateResubmitCta => 'Re-submit verification';

  @override
  String get kycPageTitle => 'Identity verification';

  @override
  String get kycStatusApproved => 'KYC Approved';

  @override
  String get kycStatusApprovedDesc =>
      'Identity verified. You can now create listings.';

  @override
  String get kycStatusPending => 'Under review';

  @override
  String get kycStatusPendingDesc =>
      'Documents submitted. Admin review in progress.';

  @override
  String get kycStatusRejected => 'Rejected';

  @override
  String get kycStatusRejectedDesc =>
      'Submission rejected. Please re-upload and resubmit.';

  @override
  String get kycStatusExpired => 'Expired';

  @override
  String get kycStatusExpiredDesc => 'Your KYC has expired. Please re-verify.';

  @override
  String get providerVerificationRequiredTitle =>
      'Provider verification required';

  @override
  String get providerVerificationRequiredDesc =>
      'Complete provider verification before offering services in this category.';

  @override
  String get identityVerificationRequiredTitle =>
      'Identity verification required';

  @override
  String get identityVerificationRequiredDesc =>
      'Verify your identity before you can post or offer on Nipanze.';

  @override
  String get startProviderVerificationBtn => 'Start Provider Verification';

  @override
  String get verifyIdentityBtn => 'Verify Identity';

  @override
  String get maybeLaterBtn => 'Maybe Later';

  @override
  String get kycStatusNotSubmitted => 'Not submitted';

  @override
  String get kycStatusNotSubmittedDesc =>
      'Submit documents to unlock listing creation.';

  @override
  String get kycRejectionReason => 'Rejection reason';

  @override
  String get kycIdentityVerified => 'Identity verified';

  @override
  String kycExpires(String date) {
    return 'Expires $date';
  }

  @override
  String get kycPendingNotice =>
      'Documents submitted — admin review in progress. This usually takes 1–2 business days.';

  @override
  String get kycRequiredDocs => 'Required documents';

  @override
  String get kycRequiredDocsSubtitle =>
      'Upload clear, well-lit photos. All documents are stored securely.';

  @override
  String get kycDocNationalIdFront => 'National ID — front';

  @override
  String get kycDocNationalIdFrontSubtitle =>
      'Clear photo of the front of your Ugandan National ID';

  @override
  String get kycDocNationalIdBack => 'National ID — back';

  @override
  String get kycDocNationalIdBackSubtitle =>
      'Clear photo of the back of your National ID';

  @override
  String get kycDocSelfie => 'Selfie with ID';

  @override
  String get kycDocSelfieSubtitle => 'Hold your National ID next to your face';

  @override
  String get kycDocUploadedTapReplace => 'Uploaded — tap to replace';

  @override
  String get kycDocUploadedUnderReview => 'Uploaded — under review';

  @override
  String get kycPrivacyNote =>
      'Your identity is never shown to other marketplace participants. Documents are reviewed by Nipanze admin only.';

  @override
  String get kycSubmitForReview => 'Submit for review';

  @override
  String get kycUploadAllDocs =>
      'Upload profile picture and all required documents to enable submission.';

  @override
  String get kycChooseSource => 'Choose source';

  @override
  String get kycSourceCamera => 'Camera';

  @override
  String get kycSourceLibrary => 'Photo library';

  @override
  String get kycDismiss => 'Dismiss';

  @override
  String get referAndEarn => 'Refer & Earn';

  @override
  String get yourReferralCode => 'Your referral code';

  @override
  String get enterCode => 'Enter Code';

  @override
  String get shareLink => 'Share Link';

  @override
  String get copyCode => 'Copy Code';

  @override
  String get enterReferralCode => 'Enter referral code';

  @override
  String get referralCodeSubtitle =>
      'If a friend invited you to Nipanze, enter their referral code below.';

  @override
  String get referralCodeHint => 'e.g. JOHN1234';

  @override
  String get referralCodeLabel => 'Referral code';

  @override
  String get applyCode => 'Apply Code';

  @override
  String get totalReferrals => 'Total referrals';

  @override
  String get registered => 'Registered';

  @override
  String get qualified => 'Qualified';

  @override
  String get pendingRewards => 'Pending rewards';

  @override
  String get availableRewards => 'Available';

  @override
  String get totalEarned => 'Total earned';

  @override
  String get totalPaid => 'Total paid';

  @override
  String get referralHistory => 'Referral history';

  @override
  String get noReferralsYet => 'No referrals yet';

  @override
  String get noReferralsSubtitle =>
      'Shared referrals will appear here after signup.';

  @override
  String get referralCodeCopied => 'Referral code copied';

  @override
  String get referralCodeApplied => 'Referral code applied successfully!';

  @override
  String get privacyAndVisibility => 'Privacy & Visibility';

  @override
  String get blockedUsers => 'Blocked Users';

  @override
  String get blockUser => 'Block User';

  @override
  String get blockUserConfirmTitle => 'Block this user?';

  @override
  String get blockUserConfirmBody =>
      'They will no longer be able to see or interact with your future Loan or Forex requests.';

  @override
  String get block => 'Block';

  @override
  String get unblock => 'Unblock';

  @override
  String get unblockUserConfirmTitle => 'Unblock this user?';

  @override
  String get unblockUserConfirmBody =>
      'Normal marketplace visibility rules will apply again.';

  @override
  String get userBlocked => 'User blocked.';

  @override
  String get userUnblocked => 'User unblocked.';

  @override
  String get noBlockedUsers => 'No blocked users';

  @override
  String get noBlockedUsersSubtitle => 'People you block will appear here.';

  @override
  String blockedOnDate(String date) {
    return 'Blocked $date';
  }

  @override
  String get invitePeopleAndTrackRewards => 'Invite people and track rewards';

  @override
  String get codeGenerating => 'Your code is being generated…';

  @override
  String get inviteEarnDescription =>
      'Invite people to Nipanze and earn rewards when they complete the required qualifying actions.';

  @override
  String get stepShare => 'Share';

  @override
  String get stepSignUp => 'Sign Up';

  @override
  String get stepVerify => 'Verify';

  @override
  String get stepQualify => 'Qualify';

  @override
  String get stepEarn => 'Earn';

  @override
  String get registeredReferrals => 'Registered referrals';

  @override
  String get verifiedReferrals => 'Verified referrals';

  @override
  String get qualifiedReferrals => 'Qualified referrals';

  @override
  String get notYetAvailable => 'Not yet available';

  @override
  String get readyToClaim => 'Ready to claim';

  @override
  String get lifetimeRewards => 'Lifetime rewards';

  @override
  String get alreadyPaid => 'Already paid';

  @override
  String get qualifiedTooltip =>
      'A qualified referral is someone you invited who completed the actions required for a referral reward.';

  @override
  String get subscriptionCurrency => 'Subscription Currency';

  @override
  String subscriptionCurrencyDesc(
      String currency, String country, String dialCode) {
    return 'Your subscription currency is set to $currency ($country) based on your registered phone number region ($dialCode).';
  }

  @override
  String get subscriptionCurrencyLocked =>
      'Subscription currency is locked to your phone number region for payment compatibility and cannot be changed manually.';

  @override
  String get understood => 'Understood';

  @override
  String get principalLossWarningTitle => 'Principal Loss Warning';

  @override
  String get belowTargetReturnTitle => 'Below Target Return Warning';

  @override
  String get sendAnyway => 'Send Offer Anyway';

  @override
  String get safetyToolkit => 'Safety Toolkit';

  @override
  String get safetyTips => 'Safety tips';

  @override
  String get reportListingOrUser => 'Report listing or user';

  @override
  String get supportAndHelp => 'Support & help';

  @override
  String get appLock => 'App Lock';

  @override
  String get appLockDescription =>
      'Require biometrics or device PIN after cold start or 30 seconds in the background.';

  @override
  String get unlockNipanze => 'Unlock Nipanze';

  @override
  String get referralChecking => 'Checking referral code...';

  @override
  String get referralAccepted => 'Referral code accepted.';

  @override
  String get profilePicture => 'Profile Picture';

  @override
  String get profilePictureKycNote =>
      'Required for identity verification. Upload a clear photo of yourself.';

  @override
  String get affordabilityWarningTitle => 'Repayment may be too low';

  @override
  String affordabilityWarningBody(
      String currency, String total, String shortfall) {
    return 'Your total repayment of $currency $total is $currency $shortfall below the requested amount. Providers require a return — consider increasing your installment.';
  }

  @override
  String get affordabilityDialogTitle => 'Publish anyway?';

  @override
  String get affordabilityDialogBody =>
      'Your repayment terms appear lower than what most providers will accept. You can still publish, but you may not receive offers. Consider increasing your installment amount.';

  @override
  String paymentScheduleTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'instalments',
      one: 'instalment',
    );
    return 'PAYMENT SCHEDULE ($count $_temp0)';
  }

  @override
  String plusMoreCount(int count) {
    return '+$count more';
  }

  @override
  String get quickTermGuideLabel => 'QUICK TERM GUIDE';

  @override
  String get termGuideLow => '💡 Low Interest';

  @override
  String get termGuideFair => '🤝 Fair Terms';

  @override
  String get termGuideNegotiable => '📊 Negotiable';

  @override
  String get offerMeansForYou => 'What this offer means for you';

  @override
  String get totalRepayableLabel => 'Total repayable';

  @override
  String get effectiveInterestLabel => 'Effective interest';

  @override
  String get loanAmountLabel => 'Loan amount';

  @override
  String get highEffectiveRateWarning =>
      'This offer has a relatively high effective rate. Consider negotiating or waiting for a lower offer.';

  @override
  String get allowInstitutionMatchingLabel => 'Allow institution matching';

  @override
  String get allowInstitutionMatchingSubtitle =>
      'Let verified agents from your bank or institution discover your loan requests for tailored offers.';

  @override
  String get filterInstitutionMatches => 'Institution matches';

  @override
  String get filterInstitutionMatchesSubtitle =>
      'Only opted-in loan requests matching your institution.';

  @override
  String get filterInstitutionMatchesIneligible =>
      'Set your institution in Profile → Bank & Professional to enable this filter.';

  @override
  String get filterSmartMatchingSection => 'Smart matching';

  @override
  String get institutionTypeBank => 'Bank';

  @override
  String get institutionTypeSacco => 'SACCO';

  @override
  String get institutionTypeMfi => 'Microfinance (MFI)';

  @override
  String get institutionTypeCreditCompany => 'Credit Company';

  @override
  String get institutionTypeForex => 'Forex exchange';

  @override
  String get institutionTypeCompany => 'Company';

  @override
  String get contactDetailsTitle => 'Contact Details';

  @override
  String get dealAgreementCreated => 'Deal Agreement Created';

  @override
  String get dealAgreementCreatedSubtitle =>
      'You can now contact the other party to move forward with your deal.';

  @override
  String get contactTheOtherParty => 'Contact the Other Party';

  @override
  String get detailsOnlyVisibleToYou =>
      'These details are only visible to you.';

  @override
  String get contactInfoLocked => 'Contact Info Locked';

  @override
  String get contactInfoLockedSubtitle =>
      'Unlock contact details for the opposite party to directly call, email, or WhatsApp.';

  @override
  String get oneTimeUnlockFee => 'One-time unlock fee';

  @override
  String get revealsContactInfoNotice =>
      'Reveals contact info for this deal only.';

  @override
  String get oppositePartyContact => 'Opposite Party Contact';

  @override
  String successfulDealsCount(int count) {
    return '$count Matches';
  }

  @override
  String reviewsCount(int count) {
    return '$count reviews';
  }

  @override
  String get emailAddressLabel => 'Email Address';

  @override
  String get whatsappLabel => 'WhatsApp';

  @override
  String get callAction => 'Call';

  @override
  String get emailAction => 'Email';

  @override
  String get chatAction => 'Chat';

  @override
  String get safetyFirstTitle => 'Safety First';

  @override
  String get safetyFirstDesc =>
      'Communicate responsibly. Nipanze is non-custodial and does not mediate or guarantee any transaction.';

  @override
  String get goToMyDeals => 'Go to My Deals';

  @override
  String get backToActivity => 'Back to activity';

  @override
  String get previewDeal => 'Preview Deal';

  @override
  String get reachOutToLenderDirectly => 'Reach out to the provider directly';

  @override
  String get reachOutToBorrowerDirectly => 'Reach out to the borrower directly';

  @override
  String get nipanzeDisclaimerCardText =>
      'Nipanze doesn’t hold funds or mediate the deal.\nConfirm details before you send anything.';

  @override
  String get phoneCopiedToClipboard => 'Phone number copied to clipboard';

  @override
  String get emailCopiedToClipboard => 'Email address copied to clipboard';

  @override
  String get whatsappCopiedToClipboard => 'WhatsApp number copied to clipboard';

  @override
  String get notProvided => 'Not provided';

  @override
  String get viewOppositePartyContact => 'View Opposite Party Contact';

  @override
  String get tapToViewContactDetails =>
      'Tap to view contact details for the opposite party.\nFinal terms are solely between borrower and provider.';

  @override
  String get needsRequestTitle => 'Needs request';

  @override
  String get createNeedsRequestTitle => 'Post a Needs request';

  @override
  String get needsTitleLabel => 'Need title';

  @override
  String get needsTitleHint => 'e.g. Solar kit for my shop';

  @override
  String get needsCategoryLabel => 'Category';

  @override
  String get needsSpecificationLabel => 'Specification';

  @override
  String get needsSpecificationHint =>
      'Describe what you need, quantity, quality, and any delivery expectations.';

  @override
  String get needsSpecificationRequired => 'Describe what you need';

  @override
  String get needsSpecificationMinLength => 'Use at least 12 characters';

  @override
  String needsBudgetLabel(String currency) {
    return 'Budget ($currency)';
  }

  @override
  String get needsBudgetHint => 'e.g. 500000';

  @override
  String get needsBudgetHelper => 'Enter 0 if you want providers to quote.';

  @override
  String get needsLocationRequired => 'Select a location';

  @override
  String get needsCustomLocationLabel => 'Enter custom location';

  @override
  String get needsCustomLocationHint =>
      'e.g. Jinja, Fort Portal, or local area';

  @override
  String get needsUrgencyLabel => 'Urgency';

  @override
  String get needsPublishBtn => 'Publish Needs request';

  @override
  String get needsPreviewBtn => 'Preview request';

  @override
  String get needsPreviewTitle => 'Review your request';

  @override
  String get needsPreviewEdit => 'Edit';

  @override
  String get needsRequestSubmittedContent =>
      'Your Needs request is now live on the marketplace. Providers can review it and respond.';

  @override
  String needsBudgetPreview(String currency, String amount) {
    return 'Budget: $currency $amount';
  }

  @override
  String get needsCategoryBusinessEquipment => 'Business equipment';

  @override
  String get needsCategoryInventory => 'Inventory';

  @override
  String get needsCategoryAgriculture => 'Agriculture';

  @override
  String get needsCategoryEducation => 'Education';

  @override
  String get needsCategoryHealth => 'Health';

  @override
  String get needsCategoryHomeEnergy => 'Home & energy';

  @override
  String get needsCategoryCommunity => 'Community';

  @override
  String get needsCategoryTechnology => 'Technology';

  @override
  String get needsCategoryTransport => 'Transport';

  @override
  String get needsUrgencyUrgent => 'Urgent';

  @override
  String get needsUrgencyWithin30Days => 'Within 30 days';

  @override
  String get needsUrgencyThisMonth => 'This month';

  @override
  String get needsUrgencyFlexible => 'Flexible';

  @override
  String get needsCategoryTravelInternational => 'Travel & International';

  @override
  String get needsCategoryMachineryEquipment => 'Machinery & Equipment';

  @override
  String get needsCategoryProfessionalServices => 'Professional Services';

  @override
  String get needsCategoryTransportLogistics => 'Transport & Logistics';

  @override
  String get needsCategorySpecializedProducts =>
      'Specialized Products & Procurement';

  @override
  String get needsMakeOffer => 'Make an Offer';

  @override
  String get needsProviderOffers => 'Provider Offers';

  @override
  String get needsAcceptOffer => 'Accept Offer';

  @override
  String get providerServicesTitle => 'Provider Services';

  @override
  String get providerServicesSubtitle =>
      'Tell people what you can help them with.';

  @override
  String servicesCount(int count) {
    return '$count services';
  }

  @override
  String get zeroServicesAdded => '0 services added';

  @override
  String get addServices => 'Add services';

  @override
  String get addService => 'Add Service';

  @override
  String get providerVerified => 'Provider Verified';

  @override
  String get selfDeclared => 'Self-declared';

  @override
  String get yourServices => 'Your Services';

  @override
  String get yourServicesSubtitle => 'Manage the services you offer to others';

  @override
  String get noServicesYet => 'No Services Added Yet';

  @override
  String get noServicesYetSubtitle =>
      'Add what you can offer to receive matching opportunities and make offers on Needs.';

  @override
  String get chooseCategory => 'Choose Category';

  @override
  String get chooseCapabilities => 'Choose Capabilities';

  @override
  String get marketingAndPromotion => 'Marketing & Promotion';

  @override
  String get socialMediaMarketing => 'Social Media Marketing';

  @override
  String get tiktokPromotion => 'TikTok Promotion';

  @override
  String get instagramPromotion => 'Instagram Promotion';

  @override
  String get youtubePromotion => 'YouTube Promotion';

  @override
  String get facebookPromotion => 'Facebook Promotion';

  @override
  String get influencerMarketing => 'Influencer Marketing';

  @override
  String get contentCreation => 'Content Creation';

  @override
  String get productReviews => 'Product Reviews';

  @override
  String get eventPromotion => 'Event Promotion';

  @override
  String get whatsAppCommunityPromotion => 'WhatsApp / Community Promotion';

  @override
  String get affiliateMarketing => 'Affiliate Marketing';

  @override
  String get advertisingCampaigns => 'Advertising Campaigns';

  @override
  String get brandPromotion => 'Brand Promotion';

  @override
  String get otherMarketingServices => 'Other Marketing Services';

  @override
  String get iHaveAnAudience => 'I Have an Audience';

  @override
  String get whereIsYourAudience => 'Where is your audience?';

  @override
  String get selectAudiencePlatforms => 'Select all that apply';

  @override
  String get audiencePlatformTikTok => 'TikTok';

  @override
  String get audiencePlatformInstagram => 'Instagram';

  @override
  String get audiencePlatformYouTube => 'YouTube';

  @override
  String get audiencePlatformFacebook => 'Facebook';

  @override
  String get audiencePlatformWhatsApp => 'WhatsApp';

  @override
  String get audiencePlatformOther => 'Other';

  @override
  String get tellBusinessesAboutYourAudience =>
      'Tell businesses about your audience';

  @override
  String get audienceFollowersMembersCount => 'Followers / members count';

  @override
  String get audienceMainLocation => 'Main audience location';

  @override
  String get audienceMainInterest => 'Main audience interest / category';

  @override
  String get declaredAudience => 'Declared audience';

  @override
  String get addSelected => 'Add Selected';

  @override
  String get removeService => 'Remove Service';

  @override
  String get removeServiceConfirm =>
      'Are you sure you want to remove this service from your profile?';

  @override
  String get providerOpportunitiesTitle =>
      'People are looking for what you provide';

  @override
  String get viewOpportunities => 'View opportunities';

  @override
  String get addYourServices => 'Add your services';

  @override
  String get canYouHelp => 'Can you help people with something?';

  @override
  String get youDontProvideThisService =>
      'You don\'t provide this service yet.';

  @override
  String addCapabilityAction(String capability) {
    return 'Add $capability';
  }

  @override
  String opportunitiesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count opportunities',
      one: '1 opportunity',
    );
    return '$_temp0';
  }

  @override
  String get navHome => 'Home';

  @override
  String get navPost => 'Post';

  @override
  String get navActivity => 'Activity';

  @override
  String get postChoiceTitle => 'What do you want to post?';

  @override
  String get postLoanAction => 'Loan Request';

  @override
  String get postForexAction => 'Forex Request';

  @override
  String get postNeedAction => 'Need Request';

  @override
  String get forYouTitle => 'For You';

  @override
  String get peopleLookingForServices =>
      'People are looking for what you provide';

  @override
  String get addYourServicesPrompt => 'Can you help people with something?';

  @override
  String get whatCanYouHelpWith => 'What can you help people with?';

  @override
  String get whatCanYouHelpWithSubtitle =>
      'Tell us what you offer and we\'ll match you with people looking for it.';

  @override
  String get addYourServicesCta => 'Add your services';

  @override
  String get newCategoriesAvailable => 'New categories are available';

  @override
  String newCategoriesAvailableSubtitle(Object categories) {
    return 'We\'ve added $categories. You might have something to offer there.';
  }

  @override
  String get exploreNewCategoriesCta => 'Explore new categories';

  @override
  String matchingNeedsSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# new requests match your services.',
      one: '# new request matches your services.',
    );
    return '$_temp0';
  }

  @override
  String get seeOpportunitiesCta => 'See opportunities';
}
