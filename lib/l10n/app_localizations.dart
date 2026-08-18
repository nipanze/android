import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_rw.dart';
import 'app_localizations_sw.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
    Locale('rw'),
    Locale('sw')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Nipanze'**
  String get appTitle;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Borrow. Lend. Grow.'**
  String get welcomeTitle;

  /// No description provided for @welcomeTagline.
  ///
  /// In en, this message translates to:
  /// **'Checkout local listings'**
  String get welcomeTagline;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A trusted marketplace connecting borrowers with lenders.'**
  String get welcomeSubtitle;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @choosePreferredLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get choosePreferredLanguage;

  /// No description provided for @continueWithPhone.
  ///
  /// In en, this message translates to:
  /// **'Continue with Phone'**
  String get continueWithPhone;

  /// No description provided for @continueWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Continue with Email'**
  String get continueWithEmail;

  /// No description provided for @getStartedTitle.
  ///
  /// In en, this message translates to:
  /// **'Get started with Nipanze'**
  String get getStartedTitle;

  /// No description provided for @getStartedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how you would like to proceed'**
  String get getStartedSubtitle;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @createAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'New to Nipanze? Sign up with phone'**
  String get createAccountSubtitle;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get logIn;

  /// No description provided for @logInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get logInSubtitle;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back 👋'**
  String get welcomeBack;

  /// No description provided for @loginToAccount.
  ///
  /// In en, this message translates to:
  /// **'Login to your account'**
  String get loginToAccount;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @createPassword.
  ///
  /// In en, this message translates to:
  /// **'Create password'**
  String get createPassword;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @enterPhoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get enterPhoneTitle;

  /// No description provided for @enterPhoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send you a verification code'**
  String get enterPhoneSubtitle;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send Verification Code'**
  String get sendCode;

  /// No description provided for @tellUsAboutYou.
  ///
  /// In en, this message translates to:
  /// **'Tell us about you'**
  String get tellUsAboutYou;

  /// No description provided for @completeProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your profile & set a password'**
  String get completeProfileSubtitle;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @termsNotice.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our Terms of Use and Privacy Policy.'**
  String get termsNotice;

  /// No description provided for @phoneSafeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your number is safe with us'**
  String get phoneSafeTitle;

  /// No description provided for @phoneSafeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We never share your number with anyone.'**
  String get phoneSafeSubtitle;

  /// No description provided for @navMarkets.
  ///
  /// In en, this message translates to:
  /// **'Markets'**
  String get navMarkets;

  /// No description provided for @navWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Watchlist'**
  String get navWatchlist;

  /// No description provided for @navRequest.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get navRequest;

  /// No description provided for @navPositions.
  ///
  /// In en, this message translates to:
  /// **'Positions'**
  String get navPositions;

  /// No description provided for @navAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get navAccount;

  /// No description provided for @marketplaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get marketplaceTitle;

  /// No description provided for @listingsLive.
  ///
  /// In en, this message translates to:
  /// **'{count} listings · live'**
  String listingsLive(int count);

  /// No description provided for @filtered.
  ///
  /// In en, this message translates to:
  /// **'Filtered'**
  String get filtered;

  /// No description provided for @applyingFilters.
  ///
  /// In en, this message translates to:
  /// **'Applying filters…'**
  String get applyingFilters;

  /// No description provided for @noListingsFound.
  ///
  /// In en, this message translates to:
  /// **'No listings found'**
  String get noListingsFound;

  /// No description provided for @noListingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check back soon — new listings appear in real time.'**
  String get noListingsSubtitle;

  /// No description provided for @noMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get noMatches;

  /// No description provided for @noMatchesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No active listings match your Pro filters.\nTry adjusting or clearing the filter criteria.'**
  String get noMatchesSubtitle;

  /// No description provided for @adjustFilters.
  ///
  /// In en, this message translates to:
  /// **'Adjust filters'**
  String get adjustFilters;

  /// No description provided for @removeFromWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Remove from watchlist'**
  String get removeFromWatchlist;

  /// No description provided for @saveToWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Save to watchlist'**
  String get saveToWatchlist;

  /// No description provided for @months.
  ///
  /// In en, this message translates to:
  /// **'months'**
  String get months;

  /// No description provided for @daysLeft.
  ///
  /// In en, this message translates to:
  /// **'{count}d left'**
  String daysLeft(int count);

  /// No description provided for @hoursLeft.
  ///
  /// In en, this message translates to:
  /// **'{count}h left'**
  String hoursLeft(int count);

  /// No description provided for @minutesLeft.
  ///
  /// In en, this message translates to:
  /// **'{count}m left'**
  String minutesLeft(int count);

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @watchlistTitle.
  ///
  /// In en, this message translates to:
  /// **'Watchlist'**
  String get watchlistTitle;

  /// No description provided for @watchlistSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Listings you\'re tracking'**
  String get watchlistSubtitle;

  /// No description provided for @watchlistSaved.
  ///
  /// In en, this message translates to:
  /// **'{count} saved'**
  String watchlistSaved(int count);

  /// No description provided for @watchlistInfoSubscribed.
  ///
  /// In en, this message translates to:
  /// **'Free for all users. Get notified when offers change, rates improve, or a listing is closing.'**
  String get watchlistInfoSubscribed;

  /// No description provided for @watchlistInfoFree.
  ///
  /// In en, this message translates to:
  /// **'Free for all users. Get notified when offers change, rates improve, or a listing is closing. Subscribe to make offers.'**
  String get watchlistInfoFree;

  /// No description provided for @watchlistError.
  ///
  /// In en, this message translates to:
  /// **'Error loading watchlist'**
  String get watchlistError;

  /// No description provided for @watchlistEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved listings'**
  String get watchlistEmpty;

  /// No description provided for @watchlistEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse the marketplace and tap \"Save to watchlist\" on any listing.'**
  String get watchlistEmptySubtitle;

  /// No description provided for @browseMarketplace.
  ///
  /// In en, this message translates to:
  /// **'Browse marketplace'**
  String get browseMarketplace;

  /// No description provided for @removedFromWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Removed from watchlist'**
  String get removedFromWatchlist;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @myActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'My Activity'**
  String get myActivityTitle;

  /// No description provided for @myActivitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your listings and offers'**
  String get myActivitySubtitle;

  /// No description provided for @myActivityStats.
  ///
  /// In en, this message translates to:
  /// **'{listings} Listings · {offers} Active Offers'**
  String myActivityStats(int listings, int offers);

  /// No description provided for @tabMyRequests.
  ///
  /// In en, this message translates to:
  /// **'My Requests'**
  String get tabMyRequests;

  /// No description provided for @tabMyOffers.
  ///
  /// In en, this message translates to:
  /// **'My Offers'**
  String get tabMyOffers;

  /// No description provided for @noOffersYet.
  ///
  /// In en, this message translates to:
  /// **'No offers yet'**
  String get noOffersYet;

  /// No description provided for @noOffersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Offers you place on marketplace listings will appear here.'**
  String get noOffersSubtitle;

  /// No description provided for @browseMarketplaceBtn.
  ///
  /// In en, this message translates to:
  /// **'Browse Marketplace'**
  String get browseMarketplaceBtn;

  /// No description provided for @activeOffers.
  ///
  /// In en, this message translates to:
  /// **'Active Offers'**
  String get activeOffers;

  /// No description provided for @matchedAccepted.
  ///
  /// In en, this message translates to:
  /// **'Matched / Accepted'**
  String get matchedAccepted;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @withdrawOffer.
  ///
  /// In en, this message translates to:
  /// **'Withdraw Offer?'**
  String get withdrawOffer;

  /// No description provided for @withdrawConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to withdraw your offer for UGX {amount}?'**
  String withdrawConfirm(int amount);

  /// No description provided for @keepOffer.
  ///
  /// In en, this message translates to:
  /// **'Keep Offer'**
  String get keepOffer;

  /// No description provided for @withdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdraw;

  /// No description provided for @myRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Requests'**
  String get myRequestsTitle;

  /// No description provided for @sectionActive.
  ///
  /// In en, this message translates to:
  /// **'Active · {count}'**
  String sectionActive(int count);

  /// No description provided for @sectionContracted.
  ///
  /// In en, this message translates to:
  /// **'Contracted · {count}'**
  String sectionContracted(int count);

  /// No description provided for @sectionClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed · {count}'**
  String sectionClosed(int count);

  /// No description provided for @noLoanRequests.
  ///
  /// In en, this message translates to:
  /// **'No loan requests yet'**
  String get noLoanRequests;

  /// No description provided for @noLoanRequestsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Post a request and lenders will compete to offer you the best rate.'**
  String get noLoanRequestsSubtitle;

  /// No description provided for @createLoanRequest.
  ///
  /// In en, this message translates to:
  /// **'Create a loan request'**
  String get createLoanRequest;

  /// No description provided for @cancelListing.
  ///
  /// In en, this message translates to:
  /// **'Cancel listing?'**
  String get cancelListing;

  /// No description provided for @cancelListingConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will remove \"{title}\" from the marketplace. Any pending offers will be rejected. This cannot be undone.'**
  String cancelListingConfirm(String title);

  /// No description provided for @keepIt.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get keepIt;

  /// No description provided for @cancelListingBtn.
  ///
  /// In en, this message translates to:
  /// **'Cancel listing'**
  String get cancelListingBtn;

  /// No description provided for @contractNotGenerated.
  ///
  /// In en, this message translates to:
  /// **'Contract not yet generated.'**
  String get contractNotGenerated;

  /// No description provided for @viewOffers.
  ///
  /// In en, this message translates to:
  /// **'View offers'**
  String get viewOffers;

  /// No description provided for @viewContract.
  ///
  /// In en, this message translates to:
  /// **'View contract'**
  String get viewContract;

  /// No description provided for @viewListing.
  ///
  /// In en, this message translates to:
  /// **'View listing'**
  String get viewListing;

  /// No description provided for @offeredAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Offered amount'**
  String get offeredAmountLabel;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @interestLabel.
  ///
  /// In en, this message translates to:
  /// **'Interest'**
  String get interestLabel;

  /// No description provided for @lateFeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Late fee'**
  String get lateFeeLabel;

  /// No description provided for @lateFeePerMissedInstallment.
  ///
  /// In en, this message translates to:
  /// **'{value} per missed installment'**
  String lateFeePerMissedInstallment(String value);

  /// No description provided for @repaymentLabel.
  ///
  /// In en, this message translates to:
  /// **'Repayment'**
  String get repaymentLabel;

  /// No description provided for @totalPayableLabel.
  ///
  /// In en, this message translates to:
  /// **'Total payable'**
  String get totalPayableLabel;

  /// No description provided for @sentDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Sent {date}'**
  String sentDateLabel(String date);

  /// No description provided for @errorLoadingContract.
  ///
  /// In en, this message translates to:
  /// **'Error loading contract: {error}'**
  String errorLoadingContract(String error);

  /// No description provided for @listingOfferCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, one {offer} other {offers}}'**
  String listingOfferCount(int count);

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @community.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get community;

  /// No description provided for @legal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legal;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @signOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out of your account?'**
  String get signOutConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated.'**
  String get profileUpdated;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved.'**
  String get profileSaved;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @changeProfilePicture.
  ///
  /// In en, this message translates to:
  /// **'Change profile picture'**
  String get changeProfilePicture;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumberLabel;

  /// No description provided for @selectRegionLabel.
  ///
  /// In en, this message translates to:
  /// **'Select {label}'**
  String selectRegionLabel(String label);

  /// No description provided for @incomeTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Income type'**
  String get incomeTypeLabel;

  /// No description provided for @selectIncomeType.
  ///
  /// In en, this message translates to:
  /// **'Select income type'**
  String get selectIncomeType;

  /// No description provided for @employerBusinessOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Employer / Business name (optional)'**
  String get employerBusinessOptionalLabel;

  /// No description provided for @monthlyIncomeWithCurrency.
  ///
  /// In en, this message translates to:
  /// **'Monthly income ({currency})'**
  String monthlyIncomeWithCurrency(String currency);

  /// No description provided for @bankProfessionalTagLabel.
  ///
  /// In en, this message translates to:
  /// **'Bank & Professional Tag'**
  String get bankProfessionalTagLabel;

  /// No description provided for @preferredDepositBankLabel.
  ///
  /// In en, this message translates to:
  /// **'Preferred or deposit bank (optional)'**
  String get preferredDepositBankLabel;

  /// No description provided for @preferredDepositBankHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Equity Bank, Bank of Kigali, Stanbic, KCB'**
  String get preferredDepositBankHint;

  /// No description provided for @accountRepresentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Account represents'**
  String get accountRepresentsLabel;

  /// No description provided for @individualPersonalAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Individual / Personal account'**
  String get individualPersonalAccountLabel;

  /// No description provided for @bankLabel.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get bankLabel;

  /// No description provided for @forexExchangeCompanyLabel.
  ///
  /// In en, this message translates to:
  /// **'Forex exchange company'**
  String get forexExchangeCompanyLabel;

  /// No description provided for @saccoLabel.
  ///
  /// In en, this message translates to:
  /// **'SACCO'**
  String get saccoLabel;

  /// No description provided for @companyLabel.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get companyLabel;

  /// No description provided for @bankLoanAgentLabel.
  ///
  /// In en, this message translates to:
  /// **'I am a bank loan agent'**
  String get bankLoanAgentLabel;

  /// No description provided for @bankLoanAgentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Shows a bank-agent tag to Pro users seeking bank loans.'**
  String get bankLoanAgentSubtitle;

  /// No description provided for @showProfessionalTagLabel.
  ///
  /// In en, this message translates to:
  /// **'Show my professional tag'**
  String get showProfessionalTagLabel;

  /// No description provided for @showProfessionalTagSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Turn off to hide bank, forex company, SACCO, or agent labels on offers.'**
  String get showProfessionalTagSubtitle;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @enterFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterFullName;

  /// No description provided for @avatarUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Avatar upload failed: {error}'**
  String avatarUploadFailed(String error);

  /// No description provided for @couldNotSelectImage.
  ///
  /// In en, this message translates to:
  /// **'Could not select image: {error}'**
  String couldNotSelectImage(String error);

  /// No description provided for @identityVerification.
  ///
  /// In en, this message translates to:
  /// **'Identity Verification'**
  String get identityVerification;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// No description provided for @noNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ll be notified here when offers arrive, rates change, or contracts are ready.'**
  String get noNotificationsSubtitle;

  /// No description provided for @todayLabel.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get todayLabel;

  /// No description provided for @yesterdayLabel.
  ///
  /// In en, this message translates to:
  /// **'YESTERDAY'**
  String get yesterdayLabel;

  /// No description provided for @earlierLabel.
  ///
  /// In en, this message translates to:
  /// **'EARLIER'**
  String get earlierLabel;

  /// No description provided for @tapToView.
  ///
  /// In en, this message translates to:
  /// **'Tap to view'**
  String get tapToView;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get justNow;

  /// No description provided for @statListings.
  ///
  /// In en, this message translates to:
  /// **'Listings'**
  String get statListings;

  /// No description provided for @statListingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Posted requests'**
  String get statListingsSubtitle;

  /// No description provided for @statOffers.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get statOffers;

  /// No description provided for @statOffersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Offers made'**
  String get statOffersSubtitle;

  /// No description provided for @statMatches.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get statMatches;

  /// No description provided for @statMatchesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Successful matches'**
  String get statMatchesSubtitle;

  /// No description provided for @trustReputation.
  ///
  /// In en, this message translates to:
  /// **'Trust & Reputation'**
  String get trustReputation;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @upgradeToPro.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get upgradeToPro;

  /// No description provided for @viewPlansUpgrade.
  ///
  /// In en, this message translates to:
  /// **'View plans & upgrade'**
  String get viewPlansUpgrade;

  /// No description provided for @adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Admin dashboard'**
  String get adminDashboard;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since {date}'**
  String memberSince(String date);

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @districtNotSet.
  ///
  /// In en, this message translates to:
  /// **'District not set'**
  String get districtNotSet;

  /// No description provided for @nipanzeDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Nipanze is a non-custodial matchmaking platform. We do not hold, move, or settle funds. All transactions occur direct between participants.'**
  String get nipanzeDisclaimer;

  /// No description provided for @lenderRequired.
  ///
  /// In en, this message translates to:
  /// **'Lender required'**
  String get lenderRequired;

  /// No description provided for @lenderRequiredSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Making offers is part of the Lender plan (also included in Pro). Upgrade to unlock offer placement on any listing.'**
  String get lenderRequiredSubtitle;

  /// No description provided for @lenderTier.
  ///
  /// In en, this message translates to:
  /// **'Lender tier'**
  String get lenderTier;

  /// No description provided for @lenderTierDesc.
  ///
  /// In en, this message translates to:
  /// **'For anyone ready to make structured offers and earn returns on Nipanze.'**
  String get lenderTierDesc;

  /// No description provided for @everythingInFree.
  ///
  /// In en, this message translates to:
  /// **'Everything in Free'**
  String get everythingInFree;

  /// No description provided for @lenderFeature1.
  ///
  /// In en, this message translates to:
  /// **'Make offers with full terms (rate, fee, schedule)'**
  String get lenderFeature1;

  /// No description provided for @lenderFeature2.
  ///
  /// In en, this message translates to:
  /// **'See offer detail where you participate'**
  String get lenderFeature2;

  /// No description provided for @chooseLender.
  ///
  /// In en, this message translates to:
  /// **'Choose Lender'**
  String get chooseLender;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @paymentSecurityDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Nipanze does not hold or move funds. Subscription changes are confirmed through a secure payment flow.'**
  String get paymentSecurityDisclaimer;

  /// No description provided for @proRequired.
  ///
  /// In en, this message translates to:
  /// **'Pro tier required'**
  String get proRequired;

  /// No description provided for @proRequiredSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Advanced features like custom term proposals and advanced filters are reserved for Pro subscribers.'**
  String get proRequiredSubtitle;

  /// No description provided for @proTier.
  ///
  /// In en, this message translates to:
  /// **'Pro tier'**
  String get proTier;

  /// No description provided for @proTierDesc.
  ///
  /// In en, this message translates to:
  /// **'Priority visibility, improved matching and stronger marketplace performance.'**
  String get proTierDesc;

  /// No description provided for @everythingInLender.
  ///
  /// In en, this message translates to:
  /// **'Everything in Lender'**
  String get everythingInLender;

  /// No description provided for @proFeature1.
  ///
  /// In en, this message translates to:
  /// **'Preferred loan terms and Forex rate'**
  String get proFeature1;

  /// No description provided for @proFeature2.
  ///
  /// In en, this message translates to:
  /// **'Priority visibility and improved matching'**
  String get proFeature2;

  /// No description provided for @proFeature3.
  ///
  /// In en, this message translates to:
  /// **'Verified badge and advanced trust insights'**
  String get proFeature3;

  /// No description provided for @choosePro.
  ///
  /// In en, this message translates to:
  /// **'Choose Pro'**
  String get choosePro;

  /// No description provided for @plansAndPricing.
  ///
  /// In en, this message translates to:
  /// **'Plans & pricing'**
  String get plansAndPricing;

  /// No description provided for @chooseAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the access you need'**
  String get chooseAccessTitle;

  /// No description provided for @chooseAccessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One account can post requests and make offers. Prices match your account region ({flag} {country}).'**
  String chooseAccessSubtitle(String flag, String country);

  /// No description provided for @perMonth.
  ///
  /// In en, this message translates to:
  /// **' / month'**
  String get perMonth;

  /// No description provided for @freePlanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse, watch listings, post basic requests, and accept offers.'**
  String get freePlanSubtitle;

  /// No description provided for @freeFeature1.
  ///
  /// In en, this message translates to:
  /// **'Browse the marketplace'**
  String get freeFeature1;

  /// No description provided for @freeFeature2.
  ///
  /// In en, this message translates to:
  /// **'Post up to 2 active loan requests'**
  String get freeFeature2;

  /// No description provided for @freeFeature3.
  ///
  /// In en, this message translates to:
  /// **'Accept offers received'**
  String get freeFeature3;

  /// No description provided for @currentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current plan'**
  String get currentPlan;

  /// No description provided for @useFree.
  ///
  /// In en, this message translates to:
  /// **'Use Free'**
  String get useFree;

  /// No description provided for @choosePlan.
  ///
  /// In en, this message translates to:
  /// **'Choose {plan}'**
  String choosePlan(String plan);

  /// No description provided for @planSelectedMessage.
  ///
  /// In en, this message translates to:
  /// **'{plan} selected. Secure payment activation will be available shortly.'**
  String planSelectedMessage(String plan);

  /// No description provided for @unlockDealTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock deal'**
  String get unlockDealTitle;

  /// No description provided for @unlockDealAndContact.
  ///
  /// In en, this message translates to:
  /// **'Unlock deal & contact'**
  String get unlockDealAndContact;

  /// No description provided for @dealAgreementLocked.
  ///
  /// In en, this message translates to:
  /// **'Deal agreement locked'**
  String get dealAgreementLocked;

  /// No description provided for @dealAgreementLockedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Both borrower and lender have confirmed the deal. You can now unlock contact details to connect directly.'**
  String get dealAgreementLockedSubtitle;

  /// No description provided for @includedInPlan.
  ///
  /// In en, this message translates to:
  /// **'Included in your {plan} plan'**
  String includedInPlan(String plan);

  /// No description provided for @unlimitedUnlocksSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlimited contact unlocks at no extra fee.'**
  String get unlimitedUnlocksSubtitle;

  /// No description provided for @welcomeGiftUnlocks.
  ///
  /// In en, this message translates to:
  /// **'🎁 Welcome gift — {count} free unlock(s) remaining'**
  String welcomeGiftUnlocks(int count);

  /// No description provided for @welcomeGiftSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This deal uses one of your free unlocks. Additional unlocks cost UGX 5,000.'**
  String get welcomeGiftSubtitle;

  /// No description provided for @unlockFeeApplies.
  ///
  /// In en, this message translates to:
  /// **'UGX 5,000 unlock fee applies'**
  String get unlockFeeApplies;

  /// No description provided for @unlockFeeAppliesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your welcome unlock has been used. Upgrade to Lender or Pro for unlimited free unlocks.'**
  String get unlockFeeAppliesSubtitle;

  /// No description provided for @whatHappensNext.
  ///
  /// In en, this message translates to:
  /// **'What happens next'**
  String get whatHappensNext;

  /// No description provided for @step1Title.
  ///
  /// In en, this message translates to:
  /// **'Contact details revealed'**
  String get step1Title;

  /// No description provided for @step1Desc.
  ///
  /// In en, this message translates to:
  /// **'Legal name, phone, and email of both parties will be shared.'**
  String get step1Desc;

  /// No description provided for @step2Title.
  ///
  /// In en, this message translates to:
  /// **'Direct connection'**
  String get step2Title;

  /// No description provided for @step2Desc.
  ///
  /// In en, this message translates to:
  /// **'You can now contact your partner outside the Nipanze platform.'**
  String get step2Desc;

  /// No description provided for @step3Title.
  ///
  /// In en, this message translates to:
  /// **'Complete transaction'**
  String get step3Title;

  /// No description provided for @step3Desc.
  ///
  /// In en, this message translates to:
  /// **'Finalize the loan agreement and exchange funds directly.'**
  String get step3Desc;

  /// No description provided for @disclaimerNonCustodial.
  ///
  /// In en, this message translates to:
  /// **'Nipanze does not hold or move any funds. You and your partner are solely responsible for all financial transactions and dispute resolution.'**
  String get disclaimerNonCustodial;

  /// No description provided for @payToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Pay UGX 5,000 to Unlock'**
  String get payToUnlock;

  /// No description provided for @unlockWithFreeCredit.
  ///
  /// In en, this message translates to:
  /// **'Unlock with Free Credit'**
  String get unlockWithFreeCredit;

  /// No description provided for @unlockContactDetails.
  ///
  /// In en, this message translates to:
  /// **'Unlock contact details'**
  String get unlockContactDetails;

  /// No description provided for @upgradeForUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Upgrade for unlimited unlocks'**
  String get upgradeForUnlimited;

  /// No description provided for @contactDetailsRevealed.
  ///
  /// In en, this message translates to:
  /// **'Contact details revealed'**
  String get contactDetailsRevealed;

  /// No description provided for @connectionSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Connection successful. Here are the contact details:'**
  String get connectionSuccessful;

  /// No description provided for @borrower.
  ///
  /// In en, this message translates to:
  /// **'Borrower'**
  String get borrower;

  /// No description provided for @lender.
  ///
  /// In en, this message translates to:
  /// **'Lender'**
  String get lender;

  /// No description provided for @directContactNotice.
  ///
  /// In en, this message translates to:
  /// **'You can now contact your partner directly to complete the transaction outside of the Nipanze platform.'**
  String get directContactNotice;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @planTitle.
  ///
  /// In en, this message translates to:
  /// **'{plan} plan'**
  String planTitle(String plan);

  /// No description provided for @nonCustodialAccess.
  ///
  /// In en, this message translates to:
  /// **'Non-custodial access'**
  String get nonCustodialAccess;

  /// No description provided for @howTrustWorks.
  ///
  /// In en, this message translates to:
  /// **'How trust works'**
  String get howTrustWorks;

  /// No description provided for @trustExplanation.
  ///
  /// In en, this message translates to:
  /// **'Trust signals reflect only activity completed through Nipanze. They do not assess or imply off-platform repayment behaviour.'**
  String get trustExplanation;

  /// No description provided for @trustScore.
  ///
  /// In en, this message translates to:
  /// **'Trust score'**
  String get trustScore;

  /// No description provided for @completeDealsToBuild.
  ///
  /// In en, this message translates to:
  /// **'Complete deals to build your score'**
  String get completeDealsToBuild;

  /// No description provided for @noReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get noReviewsYet;

  /// No description provided for @successfulDeals.
  ///
  /// In en, this message translates to:
  /// **'{count} successful deals'**
  String successfulDeals(int count);

  /// No description provided for @repeatParticipant.
  ///
  /// In en, this message translates to:
  /// **'Repeat participant'**
  String get repeatParticipant;

  /// No description provided for @notRepeatYet.
  ///
  /// In en, this message translates to:
  /// **'Not a repeat yet'**
  String get notRepeatYet;

  /// No description provided for @phoneVerified.
  ///
  /// In en, this message translates to:
  /// **'Phone verified'**
  String get phoneVerified;

  /// No description provided for @phoneNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Phone not verified'**
  String get phoneNotVerified;

  /// No description provided for @publicTrustSignals.
  ///
  /// In en, this message translates to:
  /// **'Public trust signals are based only on activity completed through Nipanze.'**
  String get publicTrustSignals;

  /// No description provided for @advancedFilters.
  ///
  /// In en, this message translates to:
  /// **'Advanced Filters'**
  String get advancedFilters;

  /// No description provided for @advancedFiltersBadge.
  ///
  /// In en, this message translates to:
  /// **'Pro · Narrow the marketplace feed'**
  String get advancedFiltersBadge;

  /// No description provided for @filterReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get filterReset;

  /// No description provided for @filterClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get filterClear;

  /// No description provided for @filterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply filters'**
  String get filterApply;

  /// No description provided for @filterDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get filterDone;

  /// No description provided for @filterEmploymentType.
  ///
  /// In en, this message translates to:
  /// **'Employment type'**
  String get filterEmploymentType;

  /// No description provided for @filterEmploymentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Filter by the borrower\'s declared employment'**
  String get filterEmploymentSubtitle;

  /// No description provided for @filterIncomeRange.
  ///
  /// In en, this message translates to:
  /// **'Monthly income range'**
  String get filterIncomeRange;

  /// No description provided for @filterIncomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Coarse brackets — exact income is never shown'**
  String get filterIncomeSubtitle;

  /// No description provided for @filterQualitySignals.
  ///
  /// In en, this message translates to:
  /// **'Listing quality signals'**
  String get filterQualitySignals;

  /// No description provided for @filterHasSuggestedTerms.
  ///
  /// In en, this message translates to:
  /// **'Has suggested terms'**
  String get filterHasSuggestedTerms;

  /// No description provided for @filterHasSuggestedTermsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only Pro-posted listings that carry a locked interest rate, late fee, and repayment schedule'**
  String get filterHasSuggestedTermsSubtitle;

  /// No description provided for @filterVerifiedBorrower.
  ///
  /// In en, this message translates to:
  /// **'Verified borrower'**
  String get filterVerifiedBorrower;

  /// No description provided for @filterVerifiedBorrowerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only requests from KYC-approved account holders'**
  String get filterVerifiedBorrowerSubtitle;

  /// No description provided for @filterPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Employer names and exact income are never shown. Income brackets and employment categories are the only signals available, by design.'**
  String get filterPrivacyNote;

  /// No description provided for @empGovEmployee.
  ///
  /// In en, this message translates to:
  /// **'Government employee'**
  String get empGovEmployee;

  /// No description provided for @empEmployedPrivate.
  ///
  /// In en, this message translates to:
  /// **'Employed (private)'**
  String get empEmployedPrivate;

  /// No description provided for @empSelfEmployed.
  ///
  /// In en, this message translates to:
  /// **'Self-employed'**
  String get empSelfEmployed;

  /// No description provided for @empSmallBusinessOwner.
  ///
  /// In en, this message translates to:
  /// **'Small business owner'**
  String get empSmallBusinessOwner;

  /// No description provided for @empBusinessOwner.
  ///
  /// In en, this message translates to:
  /// **'Business owner'**
  String get empBusinessOwner;

  /// No description provided for @empStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get empStudent;

  /// No description provided for @empOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get empOther;

  /// No description provided for @incomeUnder2m.
  ///
  /// In en, this message translates to:
  /// **'Under 2M UGX / month'**
  String get incomeUnder2m;

  /// No description provided for @income2m5m.
  ///
  /// In en, this message translates to:
  /// **'2M – 5M UGX / month'**
  String get income2m5m;

  /// No description provided for @income5m10m.
  ///
  /// In en, this message translates to:
  /// **'5M – 10M UGX / month'**
  String get income5m10m;

  /// No description provided for @incomeOver10m.
  ///
  /// In en, this message translates to:
  /// **'Over 10M UGX / month'**
  String get incomeOver10m;

  /// No description provided for @iHold.
  ///
  /// In en, this message translates to:
  /// **'I hold'**
  String get iHold;

  /// No description provided for @rate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get rate;

  /// No description provided for @iNeed.
  ///
  /// In en, this message translates to:
  /// **'I need'**
  String get iNeed;

  /// No description provided for @marketRate.
  ///
  /// In en, this message translates to:
  /// **'Market rate'**
  String get marketRate;

  /// No description provided for @stepIncomeRepayment.
  ///
  /// In en, this message translates to:
  /// **'Income & repayment'**
  String get stepIncomeRepayment;

  /// No description provided for @stepReviewPublish.
  ///
  /// In en, this message translates to:
  /// **'Review & publish'**
  String get stepReviewPublish;

  /// No description provided for @requestALoan.
  ///
  /// In en, this message translates to:
  /// **'Request a loan'**
  String get requestALoan;

  /// No description provided for @stepCounter.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total} · {subtitle}'**
  String stepCounter(int current, int total, String subtitle);

  /// No description provided for @subtitleLoanDetails.
  ///
  /// In en, this message translates to:
  /// **'loan details'**
  String get subtitleLoanDetails;

  /// No description provided for @subtitleRepaymentContext.
  ///
  /// In en, this message translates to:
  /// **'repayment context'**
  String get subtitleRepaymentContext;

  /// No description provided for @subtitleReview.
  ///
  /// In en, this message translates to:
  /// **'review'**
  String get subtitleReview;

  /// No description provided for @panelTheBasics.
  ///
  /// In en, this message translates to:
  /// **'The basics'**
  String get panelTheBasics;

  /// No description provided for @panelTheNumbers.
  ///
  /// In en, this message translates to:
  /// **'The numbers'**
  String get panelTheNumbers;

  /// No description provided for @panelLocationDetails.
  ///
  /// In en, this message translates to:
  /// **'Location and details'**
  String get panelLocationDetails;

  /// No description provided for @panelRepaymentSource.
  ///
  /// In en, this message translates to:
  /// **'Repayment source'**
  String get panelRepaymentSource;

  /// No description provided for @panelAbilityToRepay.
  ///
  /// In en, this message translates to:
  /// **'Ability to repay'**
  String get panelAbilityToRepay;

  /// No description provided for @panelPreferredTerms.
  ///
  /// In en, this message translates to:
  /// **'Preferred terms'**
  String get panelPreferredTerms;

  /// No description provided for @requestTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Request title'**
  String get requestTitleLabel;

  /// No description provided for @requestTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Delivery van for Kampala route'**
  String get requestTitleHint;

  /// No description provided for @purposeLabel.
  ///
  /// In en, this message translates to:
  /// **'Purpose'**
  String get purposeLabel;

  /// No description provided for @selectPurposeHint.
  ///
  /// In en, this message translates to:
  /// **'Select purpose'**
  String get selectPurposeHint;

  /// No description provided for @describePurposeLabel.
  ///
  /// In en, this message translates to:
  /// **'Describe your purpose'**
  String get describePurposeLabel;

  /// No description provided for @amountLabelWithCurrency.
  ///
  /// In en, this message translates to:
  /// **'Amount ({currency})'**
  String amountLabelWithCurrency(String currency);

  /// No description provided for @amountHintLoan.
  ///
  /// In en, this message translates to:
  /// **'7,000,000'**
  String get amountHintLoan;

  /// No description provided for @durationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get durationLabel;

  /// No description provided for @durationHintMonths.
  ///
  /// In en, this message translates to:
  /// **'6 months'**
  String get durationHintMonths;

  /// No description provided for @descriptionOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptionalLabel;

  /// No description provided for @descriptionOptionalHint.
  ///
  /// In en, this message translates to:
  /// **'Add any context lenders should know'**
  String get descriptionOptionalHint;

  /// No description provided for @incomeSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Income source'**
  String get incomeSourceLabel;

  /// No description provided for @incomeSourceHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Salary, shop income, farming, side work'**
  String get incomeSourceHint;

  /// No description provided for @preferredRepaymentPlanLabel.
  ///
  /// In en, this message translates to:
  /// **'Preferred repayment plan'**
  String get preferredRepaymentPlanLabel;

  /// No description provided for @selectRepaymentPlanHint.
  ///
  /// In en, this message translates to:
  /// **'Select repayment plan'**
  String get selectRepaymentPlanHint;

  /// No description provided for @repaymentAmountPerPeriodLabel.
  ///
  /// In en, this message translates to:
  /// **'Repayment amount per period ({currency})'**
  String repaymentAmountPerPeriodLabel(String currency);

  /// No description provided for @repaymentAmountHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 250,000'**
  String get repaymentAmountHint;

  /// No description provided for @repaymentTimelineLabel.
  ///
  /// In en, this message translates to:
  /// **'Repayment timeline & schedule'**
  String get repaymentTimelineLabel;

  /// No description provided for @repaymentTimelineHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Paid by the 5th of every month by 5:00 PM for 8 months'**
  String get repaymentTimelineHint;

  /// No description provided for @dueDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Due day / frequency'**
  String get dueDayLabel;

  /// No description provided for @dueDayHint.
  ///
  /// In en, this message translates to:
  /// **'Select due day (e.g. 5th of every month)'**
  String get dueDayHint;

  /// No description provided for @dueCutoffTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Due cutoff time (for late fee timing)'**
  String get dueCutoffTimeLabel;

  /// No description provided for @dueCutoffTimeHint.
  ///
  /// In en, this message translates to:
  /// **'Select due time (e.g. 5:00 PM)'**
  String get dueCutoffTimeHint;

  /// No description provided for @timelineHelperText.
  ///
  /// In en, this message translates to:
  /// **'Exact day & cutoff time used for late fee calculations'**
  String get timelineHelperText;

  /// No description provided for @suggestedInterestRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Suggested interest rate (%)'**
  String get suggestedInterestRateLabel;

  /// No description provided for @suggestedLateFeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Suggested late payment fee (%)'**
  String get suggestedLateFeeLabel;

  /// No description provided for @suggestedRepaymentScheduleLabel.
  ///
  /// In en, this message translates to:
  /// **'Suggested repayment schedule'**
  String get suggestedRepaymentScheduleLabel;

  /// No description provided for @suggestedInstallmentAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Suggested installment amount ({currency})'**
  String suggestedInstallmentAmountLabel(String currency);

  /// No description provided for @validationTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a title'**
  String get validationTitleRequired;

  /// No description provided for @validationTitleMinLength.
  ///
  /// In en, this message translates to:
  /// **'Use at least 4 characters'**
  String get validationTitleMinLength;

  /// No description provided for @validationPurposeRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a purpose'**
  String get validationPurposeRequired;

  /// No description provided for @validationPurposeContinue.
  ///
  /// In en, this message translates to:
  /// **'Select a purpose to continue.'**
  String get validationPurposeContinue;

  /// No description provided for @validationAmountRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount'**
  String get validationAmountRequired;

  /// No description provided for @validationValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get validationValidNumber;

  /// No description provided for @validationMinAmount.
  ///
  /// In en, this message translates to:
  /// **'Minimum {currency} {min}'**
  String validationMinAmount(String currency, String min);

  /// No description provided for @validationMaxAmount.
  ///
  /// In en, this message translates to:
  /// **'Maximum {currency} {max}'**
  String validationMaxAmount(String currency, String max);

  /// No description provided for @validationDurationRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter duration'**
  String get validationDurationRequired;

  /// No description provided for @validationDurationRange.
  ///
  /// In en, this message translates to:
  /// **'1 to 60 months'**
  String get validationDurationRange;

  /// No description provided for @validationIncomeSourceRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your repayment source'**
  String get validationIncomeSourceRequired;

  /// No description provided for @validationIncomeSourceDetail.
  ///
  /// In en, this message translates to:
  /// **'Add a little more detail'**
  String get validationIncomeSourceDetail;

  /// No description provided for @validationRepaymentPlanRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a repayment plan'**
  String get validationRepaymentPlanRequired;

  /// No description provided for @validationRepaymentPlanContinue.
  ///
  /// In en, this message translates to:
  /// **'Select a repayment plan to continue.'**
  String get validationRepaymentPlanContinue;

  /// No description provided for @validationRepaymentAmountRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter repayment amount'**
  String get validationRepaymentAmountRequired;

  /// No description provided for @validationRepaymentAmountValid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get validationRepaymentAmountValid;

  /// No description provided for @validationRepaymentTimelineRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter repayment timeline'**
  String get validationRepaymentTimelineRequired;

  /// No description provided for @validationRepaymentTimelineDetail.
  ///
  /// In en, this message translates to:
  /// **'Add a clearer timeline'**
  String get validationRepaymentTimelineDetail;

  /// No description provided for @validationPercentRange.
  ///
  /// In en, this message translates to:
  /// **'Use 0 to 100'**
  String get validationPercentRange;

  /// No description provided for @btnContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get btnContinue;

  /// No description provided for @btnPublishToMarketplace.
  ///
  /// In en, this message translates to:
  /// **'Publish to marketplace'**
  String get btnPublishToMarketplace;

  /// No description provided for @btnBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get btnBack;

  /// No description provided for @reviewYourRequest.
  ///
  /// In en, this message translates to:
  /// **'Review your request'**
  String get reviewYourRequest;

  /// No description provided for @reviewConfirmDetails.
  ///
  /// In en, this message translates to:
  /// **'Confirm the details before publishing to the marketplace.'**
  String get reviewConfirmDetails;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get reviewTitle;

  /// No description provided for @reviewAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get reviewAmount;

  /// No description provided for @reviewDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get reviewDuration;

  /// No description provided for @reviewPurpose.
  ///
  /// In en, this message translates to:
  /// **'Purpose'**
  String get reviewPurpose;

  /// No description provided for @reviewIncomeSource.
  ///
  /// In en, this message translates to:
  /// **'Income source'**
  String get reviewIncomeSource;

  /// No description provided for @reviewPreferredRepaymentPlan.
  ///
  /// In en, this message translates to:
  /// **'Preferred repayment plan'**
  String get reviewPreferredRepaymentPlan;

  /// No description provided for @reviewRepaymentAmount.
  ///
  /// In en, this message translates to:
  /// **'Repayment amount'**
  String get reviewRepaymentAmount;

  /// No description provided for @reviewRepaymentTimeline.
  ///
  /// In en, this message translates to:
  /// **'Repayment timeline'**
  String get reviewRepaymentTimeline;

  /// No description provided for @reviewDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get reviewDescription;

  /// No description provided for @reviewLockedTerms.
  ///
  /// In en, this message translates to:
  /// **'Locked preferred terms'**
  String get reviewLockedTerms;

  /// No description provided for @reviewPerPeriod.
  ///
  /// In en, this message translates to:
  /// **'per period'**
  String get reviewPerPeriod;

  /// No description provided for @reviewContactPrivacyNotice.
  ///
  /// In en, this message translates to:
  /// **'Your contact details stay hidden until an offer is accepted and the unlock flow is completed.'**
  String get reviewContactPrivacyNotice;

  /// No description provided for @requestSubmittedTitle.
  ///
  /// In en, this message translates to:
  /// **'Request submitted'**
  String get requestSubmittedTitle;

  /// No description provided for @requestSubmittedContent.
  ///
  /// In en, this message translates to:
  /// **'Your loan request is now live on the marketplace. Lenders can review it and make offers.'**
  String get requestSubmittedContent;

  /// No description provided for @couldNotPublishRequest.
  ///
  /// In en, this message translates to:
  /// **'Could not publish this request. Try again.'**
  String get couldNotPublishRequest;

  /// No description provided for @kycGateListing.
  ///
  /// In en, this message translates to:
  /// **'Complete KYC verification before posting a listing.'**
  String get kycGateListing;

  /// No description provided for @notAllowedListing.
  ///
  /// In en, this message translates to:
  /// **'Your account is not allowed to post a listing.'**
  String get notAllowedListing;

  /// No description provided for @infoBannerText.
  ///
  /// In en, this message translates to:
  /// **'{currency} {min}-{max} · Up to 60 months · terms lock on publish'**
  String infoBannerText(String currency, String min, String max);

  /// No description provided for @termsLockedNotice.
  ///
  /// In en, this message translates to:
  /// **'Locked when the request is published.'**
  String get termsLockedNotice;

  /// No description provided for @upgradeToProForTerms.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro to suggest interest, late fee, and repayment terms.'**
  String get upgradeToProForTerms;

  /// No description provided for @purposeAgri.
  ///
  /// In en, this message translates to:
  /// **'Agricultural equipment'**
  String get purposeAgri;

  /// No description provided for @purposeBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business expansion'**
  String get purposeBusiness;

  /// No description provided for @purposeEdu.
  ///
  /// In en, this message translates to:
  /// **'Education / School fees'**
  String get purposeEdu;

  /// No description provided for @purposeMedical.
  ///
  /// In en, this message translates to:
  /// **'Emergency medical'**
  String get purposeMedical;

  /// No description provided for @purposeFarming.
  ///
  /// In en, this message translates to:
  /// **'Greenhouse / Farming'**
  String get purposeFarming;

  /// No description provided for @purposeHome.
  ///
  /// In en, this message translates to:
  /// **'Home improvement'**
  String get purposeHome;

  /// No description provided for @purposeStock.
  ///
  /// In en, this message translates to:
  /// **'Inventory / Stock'**
  String get purposeStock;

  /// No description provided for @purposeLand.
  ///
  /// In en, this message translates to:
  /// **'Land purchase'**
  String get purposeLand;

  /// No description provided for @purposeLivestock.
  ///
  /// In en, this message translates to:
  /// **'Livestock'**
  String get purposeLivestock;

  /// No description provided for @purposeEnergy.
  ///
  /// In en, this message translates to:
  /// **'Solar / Energy'**
  String get purposeEnergy;

  /// No description provided for @purposeVehicle.
  ///
  /// In en, this message translates to:
  /// **'Transport / Vehicle'**
  String get purposeVehicle;

  /// No description provided for @purposeWater.
  ///
  /// In en, this message translates to:
  /// **'Water & Sanitation'**
  String get purposeWater;

  /// No description provided for @purposeWedding.
  ///
  /// In en, this message translates to:
  /// **'Wedding / Event'**
  String get purposeWedding;

  /// No description provided for @purposeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get purposeOther;

  /// No description provided for @planMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get planMonthly;

  /// No description provided for @planWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get planWeekly;

  /// No description provided for @planOneTime.
  ///
  /// In en, this message translates to:
  /// **'One-time payment'**
  String get planOneTime;

  /// No description provided for @createForexRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Forex Request'**
  String get createForexRequestTitle;

  /// No description provided for @forexCurrencyHeld.
  ///
  /// In en, this message translates to:
  /// **'Currency you hold'**
  String get forexCurrencyHeld;

  /// No description provided for @forexCurrencyNeeded.
  ///
  /// In en, this message translates to:
  /// **'Currency you need'**
  String get forexCurrencyNeeded;

  /// No description provided for @forexAmountToExchange.
  ///
  /// In en, this message translates to:
  /// **'Amount to exchange'**
  String get forexAmountToExchange;

  /// No description provided for @forexAmountHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 100'**
  String get forexAmountHint;

  /// No description provided for @forexPreferredRate.
  ///
  /// In en, this message translates to:
  /// **'Preferred exchange rate'**
  String get forexPreferredRate;

  /// No description provided for @forexRateHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 3700'**
  String get forexRateHint;

  /// No description provided for @forexSettlementPreference.
  ///
  /// In en, this message translates to:
  /// **'Settlement preference'**
  String get forexSettlementPreference;

  /// No description provided for @selectSettlementHint.
  ///
  /// In en, this message translates to:
  /// **'Select settlement'**
  String get selectSettlementHint;

  /// No description provided for @forexPublishBtn.
  ///
  /// In en, this message translates to:
  /// **'Publish forex request'**
  String get forexPublishBtn;

  /// No description provided for @kycGateForex.
  ///
  /// In en, this message translates to:
  /// **'Complete KYC verification before posting a forex request.'**
  String get kycGateForex;

  /// No description provided for @couldNotPublishForex.
  ///
  /// In en, this message translates to:
  /// **'Could not publish this forex request.'**
  String get couldNotPublishForex;

  /// No description provided for @forexSettlementInPerson.
  ///
  /// In en, this message translates to:
  /// **'In person'**
  String get forexSettlementInPerson;

  /// No description provided for @forexSettlementMobileMoney.
  ///
  /// In en, this message translates to:
  /// **'Mobile money'**
  String get forexSettlementMobileMoney;

  /// No description provided for @forexSettlementBankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank transfer'**
  String get forexSettlementBankTransfer;

  /// No description provided for @forexSettlementOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get forexSettlementOther;

  /// No description provided for @forexRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Forex request'**
  String get forexRequestTitle;

  /// No description provided for @myForexRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'My forex requests'**
  String get myForexRequestsTitle;

  /// No description provided for @noForexRequestsYet.
  ///
  /// In en, this message translates to:
  /// **'No forex requests yet.'**
  String get noForexRequestsYet;

  /// No description provided for @listingDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Listing detail'**
  String get listingDetailTitle;

  /// No description provided for @offersLabel.
  ///
  /// In en, this message translates to:
  /// **'OFFERS'**
  String get offersLabel;

  /// No description provided for @loanRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Loan request'**
  String get loanRequestTitle;

  /// No description provided for @makeAnOffer.
  ///
  /// In en, this message translates to:
  /// **'Make an offer'**
  String get makeAnOffer;

  /// No description provided for @makeAnOfferToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Make an offer to unlock full details'**
  String get makeAnOfferToUnlock;

  /// No description provided for @onlyYourOfferVisible.
  ///
  /// In en, this message translates to:
  /// **'Only your offer is visible here. The full bid book is visible to the borrower.'**
  String get onlyYourOfferVisible;

  /// No description provided for @securedCollateralLabel.
  ///
  /// In en, this message translates to:
  /// **'Secured'**
  String get securedCollateralLabel;

  /// No description provided for @noCollateralLabel.
  ///
  /// In en, this message translates to:
  /// **'No collateral'**
  String get noCollateralLabel;

  /// No description provided for @hasCollateralLabel.
  ///
  /// In en, this message translates to:
  /// **'Has collateral'**
  String get hasCollateralLabel;

  /// No description provided for @collateralLabel.
  ///
  /// In en, this message translates to:
  /// **'Collateral'**
  String get collateralLabel;

  /// No description provided for @collateralPromptText.
  ///
  /// In en, this message translates to:
  /// **'Choose whether this request is backed by an asset.'**
  String get collateralPromptText;

  /// No description provided for @collateralDetailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Collateral details'**
  String get collateralDetailsLabel;

  /// No description provided for @collateralDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Land title, car, electronics, equipment'**
  String get collateralDetailsHint;

  /// No description provided for @collateralAssetRequired.
  ///
  /// In en, this message translates to:
  /// **'Describe the collateral asset'**
  String get collateralAssetRequired;

  /// No description provided for @collateralAssetDetailShort.
  ///
  /// In en, this message translates to:
  /// **'Add a little more detail'**
  String get collateralAssetDetailShort;

  /// No description provided for @collateralValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Est. value ({currency})'**
  String collateralValueLabel(String currency);

  /// No description provided for @estimatedValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Estimated value'**
  String get estimatedValueLabel;

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationLabel;

  /// No description provided for @offerSubmittedReviewNotice.
  ///
  /// In en, this message translates to:
  /// **'Offer submitted. You can review your offer above.'**
  String get offerSubmittedReviewNotice;

  /// No description provided for @offerCountdownLabel.
  ///
  /// In en, this message translates to:
  /// **'{time} left'**
  String offerCountdownLabel(String time);

  /// No description provided for @expiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expiredLabel;

  /// No description provided for @offerSentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Offer sent successfully.'**
  String get offerSentSuccessfully;

  /// No description provided for @interestRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Interest rate (%)'**
  String get interestRateLabel;

  /// No description provided for @latePaymentFeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Late payment fee (%)'**
  String get latePaymentFeeLabel;

  /// No description provided for @repaymentScheduleLabel.
  ///
  /// In en, this message translates to:
  /// **'Repayment schedule'**
  String get repaymentScheduleLabel;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @oneTimePayment.
  ///
  /// In en, this message translates to:
  /// **'One-time payment'**
  String get oneTimePayment;

  /// No description provided for @installmentAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Installment amount ({currency})'**
  String installmentAmountLabel(String currency);

  /// No description provided for @additionalExpectationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Additional expectations'**
  String get additionalExpectationsLabel;

  /// No description provided for @optionalBorrowerNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Optional notes for the borrower'**
  String get optionalBorrowerNotesHint;

  /// No description provided for @sendOffer.
  ///
  /// In en, this message translates to:
  /// **'Send Offer'**
  String get sendOffer;

  /// No description provided for @couldNotSendOffer.
  ///
  /// In en, this message translates to:
  /// **'Could not send offer.'**
  String get couldNotSendOffer;

  /// No description provided for @rateOfferedLabel.
  ///
  /// In en, this message translates to:
  /// **'Rate offered'**
  String get rateOfferedLabel;

  /// No description provided for @amountAvailableLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount available'**
  String get amountAvailableLabel;

  /// No description provided for @forexAmountToServe.
  ///
  /// In en, this message translates to:
  /// **'Amount to be served'**
  String get forexAmountToServe;

  /// No description provided for @forexServesLabel.
  ///
  /// In en, this message translates to:
  /// **'Serves'**
  String get forexServesLabel;

  /// No description provided for @amountToExchangeOut.
  ///
  /// In en, this message translates to:
  /// **'Amount to exchange out'**
  String get amountToExchangeOut;

  /// No description provided for @settlementTermsLabel.
  ///
  /// In en, this message translates to:
  /// **'Settlement terms'**
  String get settlementTermsLabel;

  /// No description provided for @activeListingLabel.
  ///
  /// In en, this message translates to:
  /// **'Active listing'**
  String get activeListingLabel;

  /// No description provided for @fundedLabel.
  ///
  /// In en, this message translates to:
  /// **'Funded'**
  String get fundedLabel;

  /// No description provided for @userVerificationStatus.
  ///
  /// In en, this message translates to:
  /// **'User verification status: {status}'**
  String userVerificationStatus(String status);

  /// No description provided for @interestPercent.
  ///
  /// In en, this message translates to:
  /// **'{value}% interest'**
  String interestPercent(String value);

  /// No description provided for @proposedRepaymentPlanLabel.
  ///
  /// In en, this message translates to:
  /// **'Proposed repayment plan'**
  String get proposedRepaymentPlanLabel;

  /// No description provided for @yourOfferLabel.
  ///
  /// In en, this message translates to:
  /// **'Your offer'**
  String get yourOfferLabel;

  /// No description provided for @lenderNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Lender #{number}'**
  String lenderNumberLabel(int number);

  /// No description provided for @lenderTextLabel.
  ///
  /// In en, this message translates to:
  /// **'Lender #{id}'**
  String lenderTextLabel(String id);

  /// No description provided for @fullOfferLabel.
  ///
  /// In en, this message translates to:
  /// **'Full offer'**
  String get fullOfferLabel;

  /// No description provided for @partialOfferLabel.
  ///
  /// In en, this message translates to:
  /// **'Partial · {coverage}%'**
  String partialOfferLabel(int coverage);

  /// No description provided for @vsAskLabel.
  ///
  /// In en, this message translates to:
  /// **'{value} vs ask'**
  String vsAskLabel(String value);

  /// No description provided for @lenderNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Lender notes'**
  String get lenderNotesLabel;

  /// No description provided for @acceptOfferLabel.
  ///
  /// In en, this message translates to:
  /// **'Accept offer'**
  String get acceptOfferLabel;

  /// No description provided for @fullCoverageOfferLabel.
  ///
  /// In en, this message translates to:
  /// **'Full coverage offer'**
  String get fullCoverageOfferLabel;

  /// No description provided for @partialCoverageLabel.
  ///
  /// In en, this message translates to:
  /// **'Partial coverage · {coverage}%'**
  String partialCoverageLabel(int coverage);

  /// No description provided for @totalPayablePaymentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Total payable ({periods} payments)'**
  String totalPayablePaymentsLabel(int periods);

  /// No description provided for @borrowingCostLabel.
  ///
  /// In en, this message translates to:
  /// **'Borrowing cost: {amount}'**
  String borrowingCostLabel(String amount);

  /// No description provided for @flutterwaveCheckoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Flutterwave Checkout'**
  String get flutterwaveCheckoutTitle;

  /// No description provided for @orderSummary.
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get orderSummary;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @mobileMoney.
  ///
  /// In en, this message translates to:
  /// **'Mobile Money'**
  String get mobileMoney;

  /// No description provided for @creditOrDebitCard.
  ///
  /// In en, this message translates to:
  /// **'Credit / Debit Card'**
  String get creditOrDebitCard;

  /// No description provided for @phoneOrAccount.
  ///
  /// In en, this message translates to:
  /// **'Phone / Account Number'**
  String get phoneOrAccount;

  /// No description provided for @enterMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter Mobile Money phone number'**
  String get enterMobileNumber;

  /// No description provided for @payWithFlutterwave.
  ///
  /// In en, this message translates to:
  /// **'Pay with Flutterwave'**
  String get payWithFlutterwave;

  /// No description provided for @processingPayment.
  ///
  /// In en, this message translates to:
  /// **'Processing Flutterwave Payment…'**
  String get processingPayment;

  /// No description provided for @paymentSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Payment Successful!'**
  String get paymentSuccessful;

  /// No description provided for @subscriptionActivated.
  ///
  /// In en, this message translates to:
  /// **'Your {plan} subscription is now active.'**
  String subscriptionActivated(Object plan);

  /// No description provided for @paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment failed. Please try again.'**
  String get paymentFailed;

  /// No description provided for @paymentStep1.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get paymentStep1;

  /// No description provided for @paymentStep2.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get paymentStep2;

  /// No description provided for @paymentStep3.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get paymentStep3;

  /// No description provided for @paymentProcessingStep1.
  ///
  /// In en, this message translates to:
  /// **'Connecting to Flutterwave…'**
  String get paymentProcessingStep1;

  /// No description provided for @paymentProcessingStep2.
  ///
  /// In en, this message translates to:
  /// **'Verifying payment…'**
  String get paymentProcessingStep2;

  /// No description provided for @paymentProcessingStep3.
  ///
  /// In en, this message translates to:
  /// **'Activating subscription…'**
  String get paymentProcessingStep3;

  /// No description provided for @transactionRef.
  ///
  /// In en, this message translates to:
  /// **'Ref: {ref}'**
  String transactionRef(String ref);

  /// No description provided for @poweredByFlutterwave.
  ///
  /// In en, this message translates to:
  /// **'Powered by Flutterwave'**
  String get poweredByFlutterwave;

  /// No description provided for @enterMobileNumberForProvider.
  ///
  /// In en, this message translates to:
  /// **'{provider} phone number'**
  String enterMobileNumberForProvider(String provider);

  /// No description provided for @mobileMoneyPromptHint.
  ///
  /// In en, this message translates to:
  /// **'You\'ll receive a {provider} prompt on your phone to approve the payment.'**
  String mobileMoneyPromptHint(String provider);

  /// No description provided for @prefilledFromAccount.
  ///
  /// In en, this message translates to:
  /// **'Pre-filled from your account'**
  String get prefilledFromAccount;

  /// No description provided for @editPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editPhoneNumber;

  /// No description provided for @lockPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Lock'**
  String get lockPhoneNumber;

  /// No description provided for @liveCalcTitle.
  ///
  /// In en, this message translates to:
  /// **'Repayment breakdown'**
  String get liveCalcTitle;

  /// No description provided for @liveCalcLoanAmount.
  ///
  /// In en, this message translates to:
  /// **'Loan amount'**
  String get liveCalcLoanAmount;

  /// No description provided for @liveCalcPlan.
  ///
  /// In en, this message translates to:
  /// **'Repayment plan'**
  String get liveCalcPlan;

  /// No description provided for @liveCalcDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get liveCalcDuration;

  /// No description provided for @liveCalcInstallment.
  ///
  /// In en, this message translates to:
  /// **'Per period installment'**
  String get liveCalcInstallment;

  /// No description provided for @liveCalcTotalPayments.
  ///
  /// In en, this message translates to:
  /// **'Total payments'**
  String get liveCalcTotalPayments;

  /// No description provided for @liveCalcTotalPayback.
  ///
  /// In en, this message translates to:
  /// **'Total payback'**
  String get liveCalcTotalPayback;

  /// No description provided for @liveCalcBorrowingCost.
  ///
  /// In en, this message translates to:
  /// **'Borrowing cost'**
  String get liveCalcBorrowingCost;

  /// No description provided for @liveCalcNoData.
  ///
  /// In en, this message translates to:
  /// **'Fill in the fields above to see your repayment breakdown.'**
  String get liveCalcNoData;

  /// No description provided for @freeTermsBanner.
  ///
  /// In en, this message translates to:
  /// **'Leave this blank — lenders will propose their own terms. Upgrade to Pro to suggest rates.'**
  String get freeTermsBanner;

  /// No description provided for @offerReadOnlyNotice.
  ///
  /// In en, this message translates to:
  /// **'Review the lender\'s proposed terms below. Accept or wait for a better offer.'**
  String get offerReadOnlyNotice;

  /// No description provided for @sponsoredLabel.
  ///
  /// In en, this message translates to:
  /// **'Sponsored'**
  String get sponsoredLabel;

  /// No description provided for @borrowerTermsMissing.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get borrowerTermsMissing;

  /// No description provided for @repaymentCalcFormula.
  ///
  /// In en, this message translates to:
  /// **'installment × number of payments = total payback'**
  String get repaymentCalcFormula;

  /// No description provided for @liveCalcWeeklyNote.
  ///
  /// In en, this message translates to:
  /// **'Weekly plan: {months} months × 4 = {count} payments'**
  String liveCalcWeeklyNote(int months, int count);

  /// No description provided for @liveCalcMonthlyNote.
  ///
  /// In en, this message translates to:
  /// **'{count} monthly payments'**
  String liveCalcMonthlyNote(int count);

  /// No description provided for @liveCalcOneTimeNote.
  ///
  /// In en, this message translates to:
  /// **'1 lump-sum payment'**
  String get liveCalcOneTimeNote;

  /// No description provided for @kycGateTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your identity first'**
  String get kycGateTitle;

  /// No description provided for @kycGateBody.
  ///
  /// In en, this message translates to:
  /// **'To post loan or forex requests and connect with lenders, you need to complete identity verification. It only takes a few minutes.'**
  String get kycGateBody;

  /// No description provided for @kycGatePendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification in review'**
  String get kycGatePendingTitle;

  /// No description provided for @kycGatePendingBody.
  ///
  /// In en, this message translates to:
  /// **'Your identity documents are being reviewed. You\'ll be notified as soon as your account is approved.'**
  String get kycGatePendingBody;

  /// No description provided for @kycGateRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification rejected'**
  String get kycGateRejectedTitle;

  /// No description provided for @kycGateRejectedBody.
  ///
  /// In en, this message translates to:
  /// **'Your KYC submission was not approved. Please re-submit with valid documents.'**
  String get kycGateRejectedBody;

  /// No description provided for @kycGateExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification expired'**
  String get kycGateExpiredTitle;

  /// No description provided for @kycGateExpiredBody.
  ///
  /// In en, this message translates to:
  /// **'Your KYC verification has expired. Please re-submit to continue posting requests.'**
  String get kycGateExpiredBody;

  /// No description provided for @kycStep1.
  ///
  /// In en, this message translates to:
  /// **'Submit your national ID or passport'**
  String get kycStep1;

  /// No description provided for @kycStep2.
  ///
  /// In en, this message translates to:
  /// **'Wait for review (usually within 24 hours)'**
  String get kycStep2;

  /// No description provided for @kycStep3.
  ///
  /// In en, this message translates to:
  /// **'Post requests once approved'**
  String get kycStep3;

  /// No description provided for @kycGateCta.
  ///
  /// In en, this message translates to:
  /// **'Start verification'**
  String get kycGateCta;

  /// No description provided for @kycGateResubmitCta.
  ///
  /// In en, this message translates to:
  /// **'Re-submit verification'**
  String get kycGateResubmitCta;

  /// No description provided for @kycPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Identity verification'**
  String get kycPageTitle;

  /// No description provided for @kycStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'KYC Approved'**
  String get kycStatusApproved;

  /// No description provided for @kycStatusApprovedDesc.
  ///
  /// In en, this message translates to:
  /// **'Identity verified. You can now create listings.'**
  String get kycStatusApprovedDesc;

  /// No description provided for @kycStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get kycStatusPending;

  /// No description provided for @kycStatusPendingDesc.
  ///
  /// In en, this message translates to:
  /// **'Documents submitted. Admin review in progress.'**
  String get kycStatusPendingDesc;

  /// No description provided for @kycStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get kycStatusRejected;

  /// No description provided for @kycStatusRejectedDesc.
  ///
  /// In en, this message translates to:
  /// **'Submission rejected. Please re-upload and resubmit.'**
  String get kycStatusRejectedDesc;

  /// No description provided for @kycStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get kycStatusExpired;

  /// No description provided for @kycStatusExpiredDesc.
  ///
  /// In en, this message translates to:
  /// **'Your KYC has expired. Please re-verify.'**
  String get kycStatusExpiredDesc;

  /// No description provided for @kycStatusNotSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Not submitted'**
  String get kycStatusNotSubmitted;

  /// No description provided for @kycStatusNotSubmittedDesc.
  ///
  /// In en, this message translates to:
  /// **'Submit documents to unlock listing creation.'**
  String get kycStatusNotSubmittedDesc;

  /// No description provided for @kycRejectionReason.
  ///
  /// In en, this message translates to:
  /// **'Rejection reason'**
  String get kycRejectionReason;

  /// No description provided for @kycIdentityVerified.
  ///
  /// In en, this message translates to:
  /// **'Identity verified'**
  String get kycIdentityVerified;

  /// No description provided for @kycExpires.
  ///
  /// In en, this message translates to:
  /// **'Expires {date}'**
  String kycExpires(String date);

  /// No description provided for @kycPendingNotice.
  ///
  /// In en, this message translates to:
  /// **'Documents submitted — admin review in progress. This usually takes 1–2 business days.'**
  String get kycPendingNotice;

  /// No description provided for @kycRequiredDocs.
  ///
  /// In en, this message translates to:
  /// **'Required documents'**
  String get kycRequiredDocs;

  /// No description provided for @kycRequiredDocsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload clear, well-lit photos. All documents are stored securely.'**
  String get kycRequiredDocsSubtitle;

  /// No description provided for @kycDocNationalIdFront.
  ///
  /// In en, this message translates to:
  /// **'National ID — front'**
  String get kycDocNationalIdFront;

  /// No description provided for @kycDocNationalIdFrontSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Clear photo of the front of your Ugandan National ID'**
  String get kycDocNationalIdFrontSubtitle;

  /// No description provided for @kycDocNationalIdBack.
  ///
  /// In en, this message translates to:
  /// **'National ID — back'**
  String get kycDocNationalIdBack;

  /// No description provided for @kycDocNationalIdBackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Clear photo of the back of your National ID'**
  String get kycDocNationalIdBackSubtitle;

  /// No description provided for @kycDocSelfie.
  ///
  /// In en, this message translates to:
  /// **'Selfie with ID'**
  String get kycDocSelfie;

  /// No description provided for @kycDocSelfieSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hold your National ID next to your face'**
  String get kycDocSelfieSubtitle;

  /// No description provided for @kycDocUploadedTapReplace.
  ///
  /// In en, this message translates to:
  /// **'Uploaded — tap to replace'**
  String get kycDocUploadedTapReplace;

  /// No description provided for @kycDocUploadedUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Uploaded — under review'**
  String get kycDocUploadedUnderReview;

  /// No description provided for @kycPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Your identity is never shown to other marketplace participants. Documents are reviewed by Nipanze admin only.'**
  String get kycPrivacyNote;

  /// No description provided for @kycSubmitForReview.
  ///
  /// In en, this message translates to:
  /// **'Submit for review'**
  String get kycSubmitForReview;

  /// No description provided for @kycUploadAllDocs.
  ///
  /// In en, this message translates to:
  /// **'Upload all three documents to enable submission.'**
  String get kycUploadAllDocs;

  /// No description provided for @kycChooseSource.
  ///
  /// In en, this message translates to:
  /// **'Choose source'**
  String get kycChooseSource;

  /// No description provided for @kycSourceCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get kycSourceCamera;

  /// No description provided for @kycSourceLibrary.
  ///
  /// In en, this message translates to:
  /// **'Photo library'**
  String get kycSourceLibrary;

  /// No description provided for @kycDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get kycDismiss;

  /// No description provided for @referAndEarn.
  ///
  /// In en, this message translates to:
  /// **'Refer & Earn'**
  String get referAndEarn;

  /// No description provided for @yourReferralCode.
  ///
  /// In en, this message translates to:
  /// **'Your referral code'**
  String get yourReferralCode;

  /// No description provided for @enterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Code'**
  String get enterCode;

  /// No description provided for @shareLink.
  ///
  /// In en, this message translates to:
  /// **'Share Link'**
  String get shareLink;

  /// No description provided for @copyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy Code'**
  String get copyCode;

  /// No description provided for @enterReferralCode.
  ///
  /// In en, this message translates to:
  /// **'Enter referral code'**
  String get enterReferralCode;

  /// No description provided for @referralCodeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'If a friend invited you to Nipanze, enter their referral code below.'**
  String get referralCodeSubtitle;

  /// No description provided for @referralCodeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. JOHN1234'**
  String get referralCodeHint;

  /// No description provided for @referralCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Referral code'**
  String get referralCodeLabel;

  /// No description provided for @applyCode.
  ///
  /// In en, this message translates to:
  /// **'Apply Code'**
  String get applyCode;

  /// No description provided for @totalReferrals.
  ///
  /// In en, this message translates to:
  /// **'Total referrals'**
  String get totalReferrals;

  /// No description provided for @registered.
  ///
  /// In en, this message translates to:
  /// **'Registered'**
  String get registered;

  /// No description provided for @qualified.
  ///
  /// In en, this message translates to:
  /// **'Qualified'**
  String get qualified;

  /// No description provided for @pendingRewards.
  ///
  /// In en, this message translates to:
  /// **'Pending rewards'**
  String get pendingRewards;

  /// No description provided for @availableRewards.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get availableRewards;

  /// No description provided for @totalEarned.
  ///
  /// In en, this message translates to:
  /// **'Total earned'**
  String get totalEarned;

  /// No description provided for @totalPaid.
  ///
  /// In en, this message translates to:
  /// **'Total paid'**
  String get totalPaid;

  /// No description provided for @referralHistory.
  ///
  /// In en, this message translates to:
  /// **'Referral history'**
  String get referralHistory;

  /// No description provided for @noReferralsYet.
  ///
  /// In en, this message translates to:
  /// **'No referrals yet'**
  String get noReferralsYet;

  /// No description provided for @noReferralsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Shared referrals will appear here after signup.'**
  String get noReferralsSubtitle;

  /// No description provided for @referralCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Referral code copied'**
  String get referralCodeCopied;

  /// No description provided for @referralCodeApplied.
  ///
  /// In en, this message translates to:
  /// **'Referral code applied successfully!'**
  String get referralCodeApplied;

  /// No description provided for @privacyAndVisibility.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Visibility'**
  String get privacyAndVisibility;

  /// No description provided for @blockedUsers.
  ///
  /// In en, this message translates to:
  /// **'Blocked Users'**
  String get blockedUsers;

  /// No description provided for @blockUser.
  ///
  /// In en, this message translates to:
  /// **'Block User'**
  String get blockUser;

  /// No description provided for @blockUserConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Block this user?'**
  String get blockUserConfirmTitle;

  /// No description provided for @blockUserConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'They will no longer be able to see or interact with your future Loan or Forex requests.'**
  String get blockUserConfirmBody;

  /// No description provided for @block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// No description provided for @unblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblock;

  /// No description provided for @unblockUserConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Unblock this user?'**
  String get unblockUserConfirmTitle;

  /// No description provided for @unblockUserConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Normal marketplace visibility rules will apply again.'**
  String get unblockUserConfirmBody;

  /// No description provided for @userBlocked.
  ///
  /// In en, this message translates to:
  /// **'User blocked.'**
  String get userBlocked;

  /// No description provided for @userUnblocked.
  ///
  /// In en, this message translates to:
  /// **'User unblocked.'**
  String get userUnblocked;

  /// No description provided for @noBlockedUsers.
  ///
  /// In en, this message translates to:
  /// **'No blocked users'**
  String get noBlockedUsers;

  /// No description provided for @noBlockedUsersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'People you block will appear here.'**
  String get noBlockedUsersSubtitle;

  /// No description provided for @blockedOnDate.
  ///
  /// In en, this message translates to:
  /// **'Blocked {date}'**
  String blockedOnDate(String date);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr', 'rw', 'sw'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'rw':
      return AppLocalizationsRw();
    case 'sw':
      return AppLocalizationsSw();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
