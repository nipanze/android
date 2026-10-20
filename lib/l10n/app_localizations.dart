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
  /// **'Your trusted marketplace with authentic providers.'**
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
  /// **'Activity'**
  String get navPositions;

  /// No description provided for @navAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get navAccount;

  /// No description provided for @marketplaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Nipanze'**
  String get marketplaceTitle;

  /// No description provided for @listingsLive.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} active listing} other{{count} active listings}}'**
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

  /// No description provided for @listingExpiryTitle.
  ///
  /// In en, this message translates to:
  /// **'Listing expiry'**
  String get listingExpiryTitle;

  /// No description provided for @listingExpiryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show time remaining'**
  String get listingExpiryTooltip;

  /// No description provided for @listingRemainingDaysHours.
  ///
  /// In en, this message translates to:
  /// **'{days} days, {hours} hours remaining'**
  String listingRemainingDaysHours(int days, int hours);

  /// No description provided for @listingRemainingHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours, {minutes} minutes remaining'**
  String listingRemainingHoursMinutes(int hours, int minutes);

  /// No description provided for @listingRemainingMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes remaining'**
  String listingRemainingMinutes(int minutes);

  /// No description provided for @listingRemainingSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds} seconds remaining'**
  String listingRemainingSeconds(int seconds);

  /// No description provided for @openToOffers.
  ///
  /// In en, this message translates to:
  /// **'Open to offers'**
  String get openToOffers;

  /// No description provided for @marketplaceForYou.
  ///
  /// In en, this message translates to:
  /// **'For You'**
  String get marketplaceForYou;

  /// No description provided for @marketplaceAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get marketplaceAll;

  /// No description provided for @marketplaceLoan.
  ///
  /// In en, this message translates to:
  /// **'Loan'**
  String get marketplaceLoan;

  /// No description provided for @marketplaceLoans.
  ///
  /// In en, this message translates to:
  /// **'Loans'**
  String get marketplaceLoans;

  /// No description provided for @marketplaceForex.
  ///
  /// In en, this message translates to:
  /// **'Forex'**
  String get marketplaceForex;

  /// No description provided for @marketplaceNeeds.
  ///
  /// In en, this message translates to:
  /// **'Needs'**
  String get marketplaceNeeds;

  /// No description provided for @marketplaceNeeded.
  ///
  /// In en, this message translates to:
  /// **'Needed'**
  String get marketplaceNeeded;

  /// No description provided for @declareCapabilityToBidTitle.
  ///
  /// In en, this message translates to:
  /// **'Service Capability Required'**
  String get declareCapabilityToBidTitle;

  /// No description provided for @declareCapabilityToBidMessage.
  ///
  /// In en, this message translates to:
  /// **'To submit an offer on this request, you must first declare that you offer services in this category.'**
  String get declareCapabilityToBidMessage;

  /// No description provided for @declareServiceNow.
  ///
  /// In en, this message translates to:
  /// **'Add Service & Continue'**
  String get declareServiceNow;

  /// No description provided for @postServiceAction.
  ///
  /// In en, this message translates to:
  /// **'Offer a Service'**
  String get postServiceAction;

  /// No description provided for @postServiceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'List your services and get matched with client requests'**
  String get postServiceSubtitle;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get viewDetails;

  /// No description provided for @proAdvancedFilters.
  ///
  /// In en, this message translates to:
  /// **'Pro advanced filters'**
  String get proAdvancedFilters;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @weekAgo.
  ///
  /// In en, this message translates to:
  /// **'1 week ago'**
  String get weekAgo;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgo(int count);

  /// No description provided for @weeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} weeks ago'**
  String weeksAgo(int count);

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

  /// No description provided for @tabDeals.
  ///
  /// In en, this message translates to:
  /// **'Deals'**
  String get tabDeals;

  /// No description provided for @noDealsYet.
  ///
  /// In en, this message translates to:
  /// **'No deals yet'**
  String get noDealsYet;

  /// No description provided for @noDealsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When an offer is accepted by you or a partner, your active deals and contracts will appear here.'**
  String get noDealsSubtitle;

  /// No description provided for @noOffersYet.
  ///
  /// In en, this message translates to:
  /// **'No offers yet'**
  String get noOffersYet;

  /// No description provided for @noOffersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Offers you place on listings will appear here.'**
  String get noOffersSubtitle;

  /// No description provided for @browseMarketplaceBtn.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
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

  /// No description provided for @noRequests.
  ///
  /// In en, this message translates to:
  /// **'No requests yet'**
  String get noRequests;

  /// No description provided for @noRequestsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Post a request and receive offers from Providers who can help.'**
  String get noRequestsSubtitle;

  /// No description provided for @createRequest.
  ///
  /// In en, this message translates to:
  /// **'Create a request'**
  String get createRequest;

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
  /// **'View Deal'**
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
  /// **'Phone Number'**
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

  /// No description provided for @choosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose photo'**
  String get choosePhoto;

  /// No description provided for @selectPhotoSource.
  ///
  /// In en, this message translates to:
  /// **'Select where to pick your profile photo'**
  String get selectPhotoSource;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takePhoto;

  /// No description provided for @useCamera.
  ///
  /// In en, this message translates to:
  /// **'Use your camera'**
  String get useCamera;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @pickExistingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Pick an existing photo'**
  String get pickExistingPhoto;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhoto;

  /// No description provided for @removePhotoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Delete current profile picture'**
  String get removePhotoSubtitle;

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
  /// **'Provider access required'**
  String get lenderRequired;

  /// No description provided for @lenderRequiredSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Making offers is part of the Provider plan (also included in Pro). Upgrade to unlock offer placement across Loans, Forex and Needs.'**
  String get lenderRequiredSubtitle;

  /// No description provided for @lenderTier.
  ///
  /// In en, this message translates to:
  /// **'Provider plan'**
  String get lenderTier;

  /// No description provided for @lenderTierDesc.
  ///
  /// In en, this message translates to:
  /// **'For anyone ready to make structured offers and participate on the supply side of Nipanze.'**
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
  /// **'Choose Provider'**
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
  /// **'Everything in Provider'**
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
  /// **'month'**
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
  /// **'Both Requester and Provider have confirmed the deal. You can now unlock contact details to connect directly.'**
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
  /// **'Your welcome unlock has been used. Upgrade to Provider or Pro for unlimited free unlocks.'**
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
  /// **'Provider'**
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
  /// **'Add any context providers should know'**
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
  /// **'Your loan request is now live on the marketplace. Providers can review it and make offers.'**
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
  /// **'Loan Request'**
  String get listingDetailTitle;

  /// No description provided for @needDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Need details'**
  String get needDetailTitle;

  /// No description provided for @termLabel.
  ///
  /// In en, this message translates to:
  /// **'Term'**
  String get termLabel;

  /// No description provided for @loanTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Loan type'**
  String get loanTypeLabel;

  /// No description provided for @aboutRequest.
  ///
  /// In en, this message translates to:
  /// **'About the request'**
  String get aboutRequest;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// No description provided for @verifiedRequester.
  ///
  /// In en, this message translates to:
  /// **'Verified requester'**
  String get verifiedRequester;

  /// No description provided for @timelineLabel.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timelineLabel;

  /// No description provided for @trustLabel.
  ///
  /// In en, this message translates to:
  /// **'Trust'**
  String get trustLabel;

  /// No description provided for @categoryDetailsLabel.
  ///
  /// In en, this message translates to:
  /// **'CATEGORY DETAILS'**
  String get categoryDetailsLabel;

  /// No description provided for @aboutNeedLabel.
  ///
  /// In en, this message translates to:
  /// **'ABOUT THE NEED'**
  String get aboutNeedLabel;

  /// No description provided for @forexHoldLabel.
  ///
  /// In en, this message translates to:
  /// **'I hold'**
  String get forexHoldLabel;

  /// No description provided for @forexNeedLabel.
  ///
  /// In en, this message translates to:
  /// **'I need'**
  String get forexNeedLabel;

  /// No description provided for @nearbyLabel.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get nearbyLabel;

  /// No description provided for @flexibleLabel.
  ///
  /// In en, this message translates to:
  /// **'Flexible'**
  String get flexibleLabel;

  /// No description provided for @offersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} offers'**
  String offersCount(int count);

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
  /// **'Provider #{number}'**
  String lenderNumberLabel(int number);

  /// No description provided for @lenderTextLabel.
  ///
  /// In en, this message translates to:
  /// **'Provider #{id}'**
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
  /// **'Provider notes'**
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

  /// No description provided for @totalAmountPayableLabel.
  ///
  /// In en, this message translates to:
  /// **'Total amount payable'**
  String get totalAmountPayableLabel;

  /// No description provided for @totalInterestLabel.
  ///
  /// In en, this message translates to:
  /// **'Total interest'**
  String get totalInterestLabel;

  /// No description provided for @liveCalcNoData.
  ///
  /// In en, this message translates to:
  /// **'Fill in the fields above to see your repayment breakdown.'**
  String get liveCalcNoData;

  /// No description provided for @freeTermsBanner.
  ///
  /// In en, this message translates to:
  /// **'Leave this blank — providers will propose their own terms. Upgrade to Pro to suggest rates.'**
  String get freeTermsBanner;

  /// No description provided for @offerReadOnlyNotice.
  ///
  /// In en, this message translates to:
  /// **'Review the provider\'s proposed terms below. Accept or wait for a better offer.'**
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
  /// **'To post Loan, Forex or Needs requests and connect with Providers, you need to complete identity verification. It only takes a few minutes.'**
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

  /// No description provided for @providerVerificationRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Additional verification required'**
  String get providerVerificationRequiredTitle;

  /// No description provided for @providerVerificationRequiredDesc.
  ///
  /// In en, this message translates to:
  /// **'This category requires provider verification before you can offer this service.'**
  String get providerVerificationRequiredDesc;

  /// No description provided for @identityVerificationRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Identity verification required'**
  String get identityVerificationRequiredTitle;

  /// No description provided for @identityVerificationRequiredDesc.
  ///
  /// In en, this message translates to:
  /// **'Verify your identity before you can post or offer on Nipanze.'**
  String get identityVerificationRequiredDesc;

  /// No description provided for @startProviderVerificationBtn.
  ///
  /// In en, this message translates to:
  /// **'Start Provider Verification'**
  String get startProviderVerificationBtn;

  /// No description provided for @verifyIdentityBtn.
  ///
  /// In en, this message translates to:
  /// **'Verify Identity'**
  String get verifyIdentityBtn;

  /// No description provided for @maybeLaterBtn.
  ///
  /// In en, this message translates to:
  /// **'Maybe Later'**
  String get maybeLaterBtn;

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
  /// **'Upload profile picture and all required documents to enable submission.'**
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

  /// No description provided for @invitePeopleAndTrackRewards.
  ///
  /// In en, this message translates to:
  /// **'Invite people and track rewards'**
  String get invitePeopleAndTrackRewards;

  /// No description provided for @codeGenerating.
  ///
  /// In en, this message translates to:
  /// **'Your code is being generated…'**
  String get codeGenerating;

  /// No description provided for @inviteEarnDescription.
  ///
  /// In en, this message translates to:
  /// **'Invite people to Nipanze and earn rewards when they complete the required qualifying actions.'**
  String get inviteEarnDescription;

  /// No description provided for @stepShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get stepShare;

  /// No description provided for @stepSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get stepSignUp;

  /// No description provided for @stepVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get stepVerify;

  /// No description provided for @stepQualify.
  ///
  /// In en, this message translates to:
  /// **'Qualify'**
  String get stepQualify;

  /// No description provided for @stepEarn.
  ///
  /// In en, this message translates to:
  /// **'Earn'**
  String get stepEarn;

  /// No description provided for @registeredReferrals.
  ///
  /// In en, this message translates to:
  /// **'Registered referrals'**
  String get registeredReferrals;

  /// No description provided for @verifiedReferrals.
  ///
  /// In en, this message translates to:
  /// **'Verified referrals'**
  String get verifiedReferrals;

  /// No description provided for @qualifiedReferrals.
  ///
  /// In en, this message translates to:
  /// **'Qualified referrals'**
  String get qualifiedReferrals;

  /// No description provided for @notYetAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not yet available'**
  String get notYetAvailable;

  /// No description provided for @readyToClaim.
  ///
  /// In en, this message translates to:
  /// **'Ready to claim'**
  String get readyToClaim;

  /// No description provided for @lifetimeRewards.
  ///
  /// In en, this message translates to:
  /// **'Lifetime rewards'**
  String get lifetimeRewards;

  /// No description provided for @alreadyPaid.
  ///
  /// In en, this message translates to:
  /// **'Already paid'**
  String get alreadyPaid;

  /// No description provided for @qualifiedTooltip.
  ///
  /// In en, this message translates to:
  /// **'A qualified referral is someone you invited who completed the actions required for a referral reward.'**
  String get qualifiedTooltip;

  /// No description provided for @subscriptionCurrency.
  ///
  /// In en, this message translates to:
  /// **'Subscription Currency'**
  String get subscriptionCurrency;

  /// No description provided for @subscriptionCurrencyDesc.
  ///
  /// In en, this message translates to:
  /// **'Your subscription currency is set to {currency} ({country}) based on your registered phone number region ({dialCode}).'**
  String subscriptionCurrencyDesc(
      String currency, String country, String dialCode);

  /// No description provided for @subscriptionCurrencyLocked.
  ///
  /// In en, this message translates to:
  /// **'Subscription currency is locked to your phone number region for payment compatibility and cannot be changed manually.'**
  String get subscriptionCurrencyLocked;

  /// No description provided for @understood.
  ///
  /// In en, this message translates to:
  /// **'Understood'**
  String get understood;

  /// No description provided for @principalLossWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Principal Loss Warning'**
  String get principalLossWarningTitle;

  /// No description provided for @belowTargetReturnTitle.
  ///
  /// In en, this message translates to:
  /// **'Below Target Return Warning'**
  String get belowTargetReturnTitle;

  /// No description provided for @sendAnyway.
  ///
  /// In en, this message translates to:
  /// **'Send Offer Anyway'**
  String get sendAnyway;

  /// No description provided for @safetyToolkit.
  ///
  /// In en, this message translates to:
  /// **'Safety Toolkit'**
  String get safetyToolkit;

  /// No description provided for @safetyTips.
  ///
  /// In en, this message translates to:
  /// **'Safety tips'**
  String get safetyTips;

  /// No description provided for @reportListingOrUser.
  ///
  /// In en, this message translates to:
  /// **'Report listing or user'**
  String get reportListingOrUser;

  /// No description provided for @supportAndHelp.
  ///
  /// In en, this message translates to:
  /// **'Support & help'**
  String get supportAndHelp;

  /// No description provided for @appLock.
  ///
  /// In en, this message translates to:
  /// **'App Lock'**
  String get appLock;

  /// No description provided for @appLockDescription.
  ///
  /// In en, this message translates to:
  /// **'Require biometrics or device PIN after cold start or 30 seconds in the background.'**
  String get appLockDescription;

  /// No description provided for @unlockNipanze.
  ///
  /// In en, this message translates to:
  /// **'Unlock Nipanze'**
  String get unlockNipanze;

  /// No description provided for @referralChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking referral code...'**
  String get referralChecking;

  /// No description provided for @referralAccepted.
  ///
  /// In en, this message translates to:
  /// **'Referral code accepted.'**
  String get referralAccepted;

  /// No description provided for @profilePicture.
  ///
  /// In en, this message translates to:
  /// **'Profile Picture'**
  String get profilePicture;

  /// No description provided for @profilePictureKycNote.
  ///
  /// In en, this message translates to:
  /// **'Required for identity verification. Upload a clear photo of yourself.'**
  String get profilePictureKycNote;

  /// No description provided for @affordabilityWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Repayment may be too low'**
  String get affordabilityWarningTitle;

  /// No description provided for @affordabilityWarningBody.
  ///
  /// In en, this message translates to:
  /// **'Your total repayment of {currency} {total} is {currency} {shortfall} below the requested amount. Providers require a return — consider increasing your installment.'**
  String affordabilityWarningBody(
      String currency, String total, String shortfall);

  /// No description provided for @affordabilityDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Publish anyway?'**
  String get affordabilityDialogTitle;

  /// No description provided for @affordabilityDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Your repayment terms appear lower than what most providers will accept. You can still publish, but you may not receive offers. Consider increasing your installment amount.'**
  String get affordabilityDialogBody;

  /// No description provided for @paymentScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'PAYMENT SCHEDULE ({count} {count, plural, one {instalment} other {instalments}})'**
  String paymentScheduleTitle(int count);

  /// No description provided for @plusMoreCount.
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String plusMoreCount(int count);

  /// No description provided for @quickTermGuideLabel.
  ///
  /// In en, this message translates to:
  /// **'QUICK TERM GUIDE'**
  String get quickTermGuideLabel;

  /// No description provided for @termGuideLow.
  ///
  /// In en, this message translates to:
  /// **'💡 Low Interest'**
  String get termGuideLow;

  /// No description provided for @termGuideFair.
  ///
  /// In en, this message translates to:
  /// **'🤝 Fair Terms'**
  String get termGuideFair;

  /// No description provided for @termGuideNegotiable.
  ///
  /// In en, this message translates to:
  /// **'📊 Negotiable'**
  String get termGuideNegotiable;

  /// No description provided for @offerMeansForYou.
  ///
  /// In en, this message translates to:
  /// **'What this offer means for you'**
  String get offerMeansForYou;

  /// No description provided for @totalRepayableLabel.
  ///
  /// In en, this message translates to:
  /// **'Total repayable'**
  String get totalRepayableLabel;

  /// No description provided for @effectiveInterestLabel.
  ///
  /// In en, this message translates to:
  /// **'Effective interest'**
  String get effectiveInterestLabel;

  /// No description provided for @loanAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Loan amount'**
  String get loanAmountLabel;

  /// No description provided for @highEffectiveRateWarning.
  ///
  /// In en, this message translates to:
  /// **'This offer has a relatively high effective rate. Consider negotiating or waiting for a lower offer.'**
  String get highEffectiveRateWarning;

  /// No description provided for @allowInstitutionMatchingLabel.
  ///
  /// In en, this message translates to:
  /// **'Allow institution matching'**
  String get allowInstitutionMatchingLabel;

  /// No description provided for @allowInstitutionMatchingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let verified agents from your bank or institution discover your loan requests for tailored offers.'**
  String get allowInstitutionMatchingSubtitle;

  /// No description provided for @filterInstitutionMatches.
  ///
  /// In en, this message translates to:
  /// **'Institution matches'**
  String get filterInstitutionMatches;

  /// No description provided for @filterInstitutionMatchesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only opted-in loan requests matching your institution.'**
  String get filterInstitutionMatchesSubtitle;

  /// No description provided for @filterInstitutionMatchesIneligible.
  ///
  /// In en, this message translates to:
  /// **'Set your institution in Profile → Bank & Professional to enable this filter.'**
  String get filterInstitutionMatchesIneligible;

  /// No description provided for @filterSmartMatchingSection.
  ///
  /// In en, this message translates to:
  /// **'Smart matching'**
  String get filterSmartMatchingSection;

  /// No description provided for @institutionTypeBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get institutionTypeBank;

  /// No description provided for @institutionTypeSacco.
  ///
  /// In en, this message translates to:
  /// **'SACCO'**
  String get institutionTypeSacco;

  /// No description provided for @institutionTypeMfi.
  ///
  /// In en, this message translates to:
  /// **'Microfinance (MFI)'**
  String get institutionTypeMfi;

  /// No description provided for @institutionTypeCreditCompany.
  ///
  /// In en, this message translates to:
  /// **'Credit Company'**
  String get institutionTypeCreditCompany;

  /// No description provided for @institutionTypeForex.
  ///
  /// In en, this message translates to:
  /// **'Forex exchange'**
  String get institutionTypeForex;

  /// No description provided for @institutionTypeCompany.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get institutionTypeCompany;

  /// No description provided for @contactDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact Details'**
  String get contactDetailsTitle;

  /// No description provided for @dealAgreementCreated.
  ///
  /// In en, this message translates to:
  /// **'Deal Agreement Created'**
  String get dealAgreementCreated;

  /// No description provided for @dealAgreementCreatedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can now contact the other party to move forward with your deal.'**
  String get dealAgreementCreatedSubtitle;

  /// No description provided for @contactTheOtherParty.
  ///
  /// In en, this message translates to:
  /// **'Contact the Other Party'**
  String get contactTheOtherParty;

  /// No description provided for @detailsOnlyVisibleToYou.
  ///
  /// In en, this message translates to:
  /// **'These details are only visible to you.'**
  String get detailsOnlyVisibleToYou;

  /// No description provided for @contactInfoLocked.
  ///
  /// In en, this message translates to:
  /// **'Contact Info Locked'**
  String get contactInfoLocked;

  /// No description provided for @contactInfoLockedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock contact details for the opposite party to directly call, email, or WhatsApp.'**
  String get contactInfoLockedSubtitle;

  /// No description provided for @oneTimeUnlockFee.
  ///
  /// In en, this message translates to:
  /// **'One-time unlock fee'**
  String get oneTimeUnlockFee;

  /// No description provided for @revealsContactInfoNotice.
  ///
  /// In en, this message translates to:
  /// **'Reveals contact info for this deal only.'**
  String get revealsContactInfoNotice;

  /// No description provided for @oppositePartyContact.
  ///
  /// In en, this message translates to:
  /// **'Opposite Party Contact'**
  String get oppositePartyContact;

  /// No description provided for @successfulDealsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Matches'**
  String successfulDealsCount(int count);

  /// No description provided for @reviewsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} reviews'**
  String reviewsCount(int count);

  /// No description provided for @emailAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddressLabel;

  /// No description provided for @whatsappLabel.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsappLabel;

  /// No description provided for @callAction.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get callAction;

  /// No description provided for @emailAction.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailAction;

  /// No description provided for @chatAction.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatAction;

  /// No description provided for @safetyFirstTitle.
  ///
  /// In en, this message translates to:
  /// **'Safety First'**
  String get safetyFirstTitle;

  /// No description provided for @safetyFirstDesc.
  ///
  /// In en, this message translates to:
  /// **'Communicate responsibly. Nipanze is non-custodial and does not mediate or guarantee any transaction.'**
  String get safetyFirstDesc;

  /// No description provided for @goToMyDeals.
  ///
  /// In en, this message translates to:
  /// **'Go to My Deals'**
  String get goToMyDeals;

  /// No description provided for @backToActivity.
  ///
  /// In en, this message translates to:
  /// **'Back to activity'**
  String get backToActivity;

  /// No description provided for @previewDeal.
  ///
  /// In en, this message translates to:
  /// **'Preview Deal'**
  String get previewDeal;

  /// No description provided for @reachOutToLenderDirectly.
  ///
  /// In en, this message translates to:
  /// **'Reach out to the provider directly'**
  String get reachOutToLenderDirectly;

  /// No description provided for @reachOutToBorrowerDirectly.
  ///
  /// In en, this message translates to:
  /// **'Reach out to the borrower directly'**
  String get reachOutToBorrowerDirectly;

  /// No description provided for @nipanzeDisclaimerCardText.
  ///
  /// In en, this message translates to:
  /// **'Nipanze doesn’t hold funds or mediate the deal.\nConfirm details before you send anything.'**
  String get nipanzeDisclaimerCardText;

  /// No description provided for @phoneCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Phone number copied to clipboard'**
  String get phoneCopiedToClipboard;

  /// No description provided for @emailCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Email address copied to clipboard'**
  String get emailCopiedToClipboard;

  /// No description provided for @whatsappCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp number copied to clipboard'**
  String get whatsappCopiedToClipboard;

  /// No description provided for @notProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get notProvided;

  /// No description provided for @viewOppositePartyContact.
  ///
  /// In en, this message translates to:
  /// **'View Opposite Party Contact'**
  String get viewOppositePartyContact;

  /// No description provided for @tapToViewContactDetails.
  ///
  /// In en, this message translates to:
  /// **'Tap to view contact details for the opposite party.\nFinal terms are solely between borrower and provider.'**
  String get tapToViewContactDetails;

  /// No description provided for @needsRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Needs request'**
  String get needsRequestTitle;

  /// No description provided for @createNeedsRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Post a Needs request'**
  String get createNeedsRequestTitle;

  /// No description provided for @needsTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Need title'**
  String get needsTitleLabel;

  /// No description provided for @needsTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Solar kit for my shop'**
  String get needsTitleHint;

  /// No description provided for @needsCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get needsCategoryLabel;

  /// No description provided for @needsSpecificationLabel.
  ///
  /// In en, this message translates to:
  /// **'Specification'**
  String get needsSpecificationLabel;

  /// No description provided for @needsSpecificationHint.
  ///
  /// In en, this message translates to:
  /// **'Describe what you need, quantity, quality, and any delivery expectations.'**
  String get needsSpecificationHint;

  /// No description provided for @needsSpecificationRequired.
  ///
  /// In en, this message translates to:
  /// **'Describe what you need'**
  String get needsSpecificationRequired;

  /// No description provided for @needsSpecificationMinLength.
  ///
  /// In en, this message translates to:
  /// **'Use at least 12 characters'**
  String get needsSpecificationMinLength;

  /// No description provided for @needsBudgetLabel.
  ///
  /// In en, this message translates to:
  /// **'Budget ({currency})'**
  String needsBudgetLabel(String currency);

  /// No description provided for @needsBudgetHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 500000'**
  String get needsBudgetHint;

  /// No description provided for @needsBudgetHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter 0 if you want providers to quote.'**
  String get needsBudgetHelper;

  /// No description provided for @needsLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a location'**
  String get needsLocationRequired;

  /// No description provided for @needsCustomLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Enter custom location'**
  String get needsCustomLocationLabel;

  /// No description provided for @needsCustomLocationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Jinja, Fort Portal, or local area'**
  String get needsCustomLocationHint;

  /// No description provided for @needsUrgencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Urgency'**
  String get needsUrgencyLabel;

  /// No description provided for @needsPublishBtn.
  ///
  /// In en, this message translates to:
  /// **'Publish Needs request'**
  String get needsPublishBtn;

  /// No description provided for @needsPreviewBtn.
  ///
  /// In en, this message translates to:
  /// **'Preview request'**
  String get needsPreviewBtn;

  /// No description provided for @needsPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review your request'**
  String get needsPreviewTitle;

  /// No description provided for @needsPreviewEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get needsPreviewEdit;

  /// No description provided for @needsRequestSubmittedContent.
  ///
  /// In en, this message translates to:
  /// **'Your Needs request is now live on the marketplace. Providers can review it and respond.'**
  String get needsRequestSubmittedContent;

  /// No description provided for @needsBudgetPreview.
  ///
  /// In en, this message translates to:
  /// **'Budget: {currency} {amount}'**
  String needsBudgetPreview(String currency, String amount);

  /// No description provided for @needsCategoryBusinessEquipment.
  ///
  /// In en, this message translates to:
  /// **'Business equipment'**
  String get needsCategoryBusinessEquipment;

  /// No description provided for @needsCategoryInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get needsCategoryInventory;

  /// No description provided for @needsCategoryAgriculture.
  ///
  /// In en, this message translates to:
  /// **'Agriculture'**
  String get needsCategoryAgriculture;

  /// No description provided for @needsCategoryEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get needsCategoryEducation;

  /// No description provided for @needsCategoryHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get needsCategoryHealth;

  /// No description provided for @needsCategoryHomeEnergy.
  ///
  /// In en, this message translates to:
  /// **'Home & energy'**
  String get needsCategoryHomeEnergy;

  /// No description provided for @needsCategoryCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get needsCategoryCommunity;

  /// No description provided for @needsCategoryTechnology.
  ///
  /// In en, this message translates to:
  /// **'Technology'**
  String get needsCategoryTechnology;

  /// No description provided for @needsCategoryTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get needsCategoryTransport;

  /// No description provided for @needsUrgencyUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get needsUrgencyUrgent;

  /// No description provided for @needsUrgencyWithin30Days.
  ///
  /// In en, this message translates to:
  /// **'Within 30 days'**
  String get needsUrgencyWithin30Days;

  /// No description provided for @needsUrgencyThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get needsUrgencyThisMonth;

  /// No description provided for @needsUrgencyFlexible.
  ///
  /// In en, this message translates to:
  /// **'Flexible'**
  String get needsUrgencyFlexible;

  /// No description provided for @needsCategoryTravelInternational.
  ///
  /// In en, this message translates to:
  /// **'Travel & International'**
  String get needsCategoryTravelInternational;

  /// No description provided for @needsCategoryMachineryEquipment.
  ///
  /// In en, this message translates to:
  /// **'Machinery & Equipment'**
  String get needsCategoryMachineryEquipment;

  /// No description provided for @needsCategoryProfessionalServices.
  ///
  /// In en, this message translates to:
  /// **'Professional Services'**
  String get needsCategoryProfessionalServices;

  /// No description provided for @needsCategoryTransportLogistics.
  ///
  /// In en, this message translates to:
  /// **'Transport & Logistics'**
  String get needsCategoryTransportLogistics;

  /// No description provided for @needsCategorySpecializedProducts.
  ///
  /// In en, this message translates to:
  /// **'Specialized Products & Procurement'**
  String get needsCategorySpecializedProducts;

  /// No description provided for @needsMakeOffer.
  ///
  /// In en, this message translates to:
  /// **'Make an Offer'**
  String get needsMakeOffer;

  /// No description provided for @needsProviderOffers.
  ///
  /// In en, this message translates to:
  /// **'Provider Offers'**
  String get needsProviderOffers;

  /// No description provided for @needsAcceptOffer.
  ///
  /// In en, this message translates to:
  /// **'Accept Offer'**
  String get needsAcceptOffer;

  /// No description provided for @providerServicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Provider Services'**
  String get providerServicesTitle;

  /// No description provided for @providerServicesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell people what you can help them with.'**
  String get providerServicesSubtitle;

  /// No description provided for @financialServicesCategory.
  ///
  /// In en, this message translates to:
  /// **'Financial Services'**
  String get financialServicesCategory;

  /// No description provided for @financialServicesDesc.
  ///
  /// In en, this message translates to:
  /// **'Loan services, forex exchange, bank agents, SACCO, microfinance, and financial advisory.'**
  String get financialServicesDesc;

  /// No description provided for @bankLoanAgentCapability.
  ///
  /// In en, this message translates to:
  /// **'Bank Loan Agent'**
  String get bankLoanAgentCapability;

  /// No description provided for @moneyLenderPrivateLenderCapability.
  ///
  /// In en, this message translates to:
  /// **'Money Lender / Private Lender'**
  String get moneyLenderPrivateLenderCapability;

  /// No description provided for @financialAdvisoryCapability.
  ///
  /// In en, this message translates to:
  /// **'Financial Advisory'**
  String get financialAdvisoryCapability;

  /// No description provided for @forexCurrencyExchangeCapability.
  ///
  /// In en, this message translates to:
  /// **'Forex / Currency Exchange'**
  String get forexCurrencyExchangeCapability;

  /// No description provided for @loanServicesCapability.
  ///
  /// In en, this message translates to:
  /// **'Loan Services'**
  String get loanServicesCapability;

  /// No description provided for @saccoMicrofinanceCapability.
  ///
  /// In en, this message translates to:
  /// **'SACCO / Microfinance Services'**
  String get saccoMicrofinanceCapability;

  /// No description provided for @otherFinancialServicesCapability.
  ///
  /// In en, this message translates to:
  /// **'Other Financial Services'**
  String get otherFinancialServicesCapability;

  /// No description provided for @organisationOptional.
  ///
  /// In en, this message translates to:
  /// **'Your Organisation (optional)'**
  String get organisationOptional;

  /// No description provided for @organisationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your institution, business or organisation and your role so requesters know who you represent.'**
  String get organisationSubtitle;

  /// No description provided for @organisationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Equity Bank, Hans Finance, ABC Forex'**
  String get organisationHint;

  /// No description provided for @organisationLabel.
  ///
  /// In en, this message translates to:
  /// **'Institution / Bank / Organisation'**
  String get organisationLabel;

  /// No description provided for @roleOptional.
  ///
  /// In en, this message translates to:
  /// **'Your Role (optional)'**
  String get roleOptional;

  /// No description provided for @roleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Independent Loan Provider, Bank Agent'**
  String get roleHint;

  /// No description provided for @showProfessionalTagProvider.
  ///
  /// In en, this message translates to:
  /// **'Show professional tag'**
  String get showProfessionalTagProvider;

  /// No description provided for @showProfessionalTagProviderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Display your services, institution and role label on offers.'**
  String get showProfessionalTagProviderSubtitle;

  /// No description provided for @allowInstitutionMatchingProvider.
  ///
  /// In en, this message translates to:
  /// **'Allow smart matching'**
  String get allowInstitutionMatchingProvider;

  /// No description provided for @allowInstitutionMatchingProviderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let relevant requests find your offers.'**
  String get allowInstitutionMatchingProviderSubtitle;

  /// No description provided for @allowSmartMatchingProvider.
  ///
  /// In en, this message translates to:
  /// **'Allow smart matching'**
  String get allowSmartMatchingProvider;

  /// No description provided for @allowSmartMatchingProviderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let relevant requests find your offers.'**
  String get allowSmartMatchingProviderSubtitle;

  /// Number of capabilities the user has selected
  ///
  /// In en, this message translates to:
  /// **'{count} services'**
  String servicesCount(int count);

  /// No description provided for @zeroServicesAdded.
  ///
  /// In en, this message translates to:
  /// **'0 services added'**
  String get zeroServicesAdded;

  /// No description provided for @addServices.
  ///
  /// In en, this message translates to:
  /// **'Add services'**
  String get addServices;

  /// No description provided for @addService.
  ///
  /// In en, this message translates to:
  /// **'Add Service'**
  String get addService;

  /// No description provided for @providerVerified.
  ///
  /// In en, this message translates to:
  /// **'Provider Verified'**
  String get providerVerified;

  /// No description provided for @selfDeclared.
  ///
  /// In en, this message translates to:
  /// **'Self-declared'**
  String get selfDeclared;

  /// No description provided for @yourServices.
  ///
  /// In en, this message translates to:
  /// **'Your Services'**
  String get yourServices;

  /// No description provided for @yourServicesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage the services you offer to others'**
  String get yourServicesSubtitle;

  /// No description provided for @noServicesYet.
  ///
  /// In en, this message translates to:
  /// **'No Services Added Yet'**
  String get noServicesYet;

  /// No description provided for @noServicesYetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add what you can offer to receive matching opportunities and make offers on Needs.'**
  String get noServicesYetSubtitle;

  /// No description provided for @chooseCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose Category'**
  String get chooseCategory;

  /// No description provided for @chooseCapabilities.
  ///
  /// In en, this message translates to:
  /// **'Choose Capabilities'**
  String get chooseCapabilities;

  /// No description provided for @marketingAndPromotion.
  ///
  /// In en, this message translates to:
  /// **'Marketing & Promotion'**
  String get marketingAndPromotion;

  /// No description provided for @socialMediaMarketing.
  ///
  /// In en, this message translates to:
  /// **'Social Media Marketing'**
  String get socialMediaMarketing;

  /// No description provided for @tiktokPromotion.
  ///
  /// In en, this message translates to:
  /// **'TikTok Promotion'**
  String get tiktokPromotion;

  /// No description provided for @instagramPromotion.
  ///
  /// In en, this message translates to:
  /// **'Instagram Promotion'**
  String get instagramPromotion;

  /// No description provided for @youtubePromotion.
  ///
  /// In en, this message translates to:
  /// **'YouTube Promotion'**
  String get youtubePromotion;

  /// No description provided for @facebookPromotion.
  ///
  /// In en, this message translates to:
  /// **'Facebook Promotion'**
  String get facebookPromotion;

  /// No description provided for @influencerMarketing.
  ///
  /// In en, this message translates to:
  /// **'Influencer Marketing'**
  String get influencerMarketing;

  /// No description provided for @contentCreation.
  ///
  /// In en, this message translates to:
  /// **'Content Creation'**
  String get contentCreation;

  /// No description provided for @productReviews.
  ///
  /// In en, this message translates to:
  /// **'Product Reviews'**
  String get productReviews;

  /// No description provided for @eventPromotion.
  ///
  /// In en, this message translates to:
  /// **'Event Promotion'**
  String get eventPromotion;

  /// No description provided for @whatsAppCommunityPromotion.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp / Community Promotion'**
  String get whatsAppCommunityPromotion;

  /// No description provided for @affiliateMarketing.
  ///
  /// In en, this message translates to:
  /// **'Affiliate Marketing'**
  String get affiliateMarketing;

  /// No description provided for @advertisingCampaigns.
  ///
  /// In en, this message translates to:
  /// **'Advertising Campaigns'**
  String get advertisingCampaigns;

  /// No description provided for @brandPromotion.
  ///
  /// In en, this message translates to:
  /// **'Brand Promotion'**
  String get brandPromotion;

  /// No description provided for @otherMarketingServices.
  ///
  /// In en, this message translates to:
  /// **'Other Marketing Services'**
  String get otherMarketingServices;

  /// No description provided for @iHaveAnAudience.
  ///
  /// In en, this message translates to:
  /// **'I Have an Audience'**
  String get iHaveAnAudience;

  /// No description provided for @whereIsYourAudience.
  ///
  /// In en, this message translates to:
  /// **'Where is your audience?'**
  String get whereIsYourAudience;

  /// No description provided for @selectAudiencePlatforms.
  ///
  /// In en, this message translates to:
  /// **'Select all that apply'**
  String get selectAudiencePlatforms;

  /// No description provided for @audiencePlatformTikTok.
  ///
  /// In en, this message translates to:
  /// **'TikTok'**
  String get audiencePlatformTikTok;

  /// No description provided for @audiencePlatformInstagram.
  ///
  /// In en, this message translates to:
  /// **'Instagram'**
  String get audiencePlatformInstagram;

  /// No description provided for @audiencePlatformYouTube.
  ///
  /// In en, this message translates to:
  /// **'YouTube'**
  String get audiencePlatformYouTube;

  /// No description provided for @audiencePlatformFacebook.
  ///
  /// In en, this message translates to:
  /// **'Facebook'**
  String get audiencePlatformFacebook;

  /// No description provided for @audiencePlatformWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get audiencePlatformWhatsApp;

  /// No description provided for @audiencePlatformOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get audiencePlatformOther;

  /// No description provided for @tellBusinessesAboutYourAudience.
  ///
  /// In en, this message translates to:
  /// **'Tell businesses about your audience'**
  String get tellBusinessesAboutYourAudience;

  /// No description provided for @audienceFollowersMembersCount.
  ///
  /// In en, this message translates to:
  /// **'Followers / members count'**
  String get audienceFollowersMembersCount;

  /// No description provided for @audienceMainLocation.
  ///
  /// In en, this message translates to:
  /// **'Main audience location'**
  String get audienceMainLocation;

  /// No description provided for @audienceMainInterest.
  ///
  /// In en, this message translates to:
  /// **'Main audience interest / category'**
  String get audienceMainInterest;

  /// No description provided for @declaredAudience.
  ///
  /// In en, this message translates to:
  /// **'Declared audience'**
  String get declaredAudience;

  /// No description provided for @addSelected.
  ///
  /// In en, this message translates to:
  /// **'Add Selected'**
  String get addSelected;

  /// No description provided for @removeService.
  ///
  /// In en, this message translates to:
  /// **'Remove Service'**
  String get removeService;

  /// No description provided for @removeServiceConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this service from your profile?'**
  String get removeServiceConfirm;

  /// No description provided for @providerOpportunitiesTitle.
  ///
  /// In en, this message translates to:
  /// **'People are looking for what you provide'**
  String get providerOpportunitiesTitle;

  /// No description provided for @workProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Work Profile'**
  String get workProfileTitle;

  /// No description provided for @workProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Describe jobs you want separately from services you offer.'**
  String get workProfileSubtitle;

  /// No description provided for @workProfilesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Work profiles are not enabled yet.'**
  String get workProfilesDisabled;

  /// No description provided for @addWorkProfile.
  ///
  /// In en, this message translates to:
  /// **'Add work profile'**
  String get addWorkProfile;

  /// No description provided for @noWorkProfilesYet.
  ///
  /// In en, this message translates to:
  /// **'No work profile yet. Add one if you want people to understand the work you are qualified to do.'**
  String get noWorkProfilesYet;

  /// No description provided for @jobOpportunitiesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Job matching is not available yet. Your profile is saved for future matching and does not create a verified badge.'**
  String get jobOpportunitiesUnavailable;

  /// No description provided for @jobRole.
  ///
  /// In en, this message translates to:
  /// **'Job role'**
  String get jobRole;

  /// No description provided for @workTypes.
  ///
  /// In en, this message translates to:
  /// **'Work types'**
  String get workTypes;

  /// No description provided for @qualifications.
  ///
  /// In en, this message translates to:
  /// **'Qualifications'**
  String get qualifications;

  /// No description provided for @experience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get experience;

  /// No description provided for @availability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availability;

  /// No description provided for @fullTime.
  ///
  /// In en, this message translates to:
  /// **'Full-time'**
  String get fullTime;

  /// No description provided for @partTime.
  ///
  /// In en, this message translates to:
  /// **'Part-time'**
  String get partTime;

  /// No description provided for @contract.
  ///
  /// In en, this message translates to:
  /// **'Contract'**
  String get contract;

  /// No description provided for @weekends.
  ///
  /// In en, this message translates to:
  /// **'Weekends'**
  String get weekends;

  /// No description provided for @preferredLocation.
  ///
  /// In en, this message translates to:
  /// **'Preferred location'**
  String get preferredLocation;

  /// No description provided for @flexible.
  ///
  /// In en, this message translates to:
  /// **'Flexible'**
  String get flexible;

  /// No description provided for @onsite.
  ///
  /// In en, this message translates to:
  /// **'On site'**
  String get onsite;

  /// No description provided for @remote.
  ///
  /// In en, this message translates to:
  /// **'Remote'**
  String get remote;

  /// No description provided for @hybrid.
  ///
  /// In en, this message translates to:
  /// **'Hybrid'**
  String get hybrid;

  /// No description provided for @expectedPay.
  ///
  /// In en, this message translates to:
  /// **'Expected pay'**
  String get expectedPay;

  /// No description provided for @payOpen.
  ///
  /// In en, this message translates to:
  /// **'Pay open'**
  String get payOpen;

  /// No description provided for @per.
  ///
  /// In en, this message translates to:
  /// **'Per'**
  String get per;

  /// No description provided for @perHour.
  ///
  /// In en, this message translates to:
  /// **'hour'**
  String get perHour;

  /// No description provided for @perDay.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get perDay;

  /// No description provided for @perWeek.
  ///
  /// In en, this message translates to:
  /// **'week'**
  String get perWeek;

  /// No description provided for @perProject.
  ///
  /// In en, this message translates to:
  /// **'project'**
  String get perProject;

  /// No description provided for @languages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get languages;

  /// No description provided for @profileSummary.
  ///
  /// In en, this message translates to:
  /// **'Profile summary'**
  String get profileSummary;

  /// No description provided for @saveWorkProfile.
  ///
  /// In en, this message translates to:
  /// **'Save work profile'**
  String get saveWorkProfile;

  /// No description provided for @deactivateWorkProfile.
  ///
  /// In en, this message translates to:
  /// **'Deactivate work profile'**
  String get deactivateWorkProfile;

  /// No description provided for @deactivateWorkProfileConfirm.
  ///
  /// In en, this message translates to:
  /// **'This hides the work profile but does not remove your service capabilities.'**
  String get deactivateWorkProfileConfirm;

  /// No description provided for @deactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get deactivate;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @viewOpportunities.
  ///
  /// In en, this message translates to:
  /// **'View opportunities'**
  String get viewOpportunities;

  /// No description provided for @addYourServices.
  ///
  /// In en, this message translates to:
  /// **'Add your services'**
  String get addYourServices;

  /// No description provided for @canYouHelp.
  ///
  /// In en, this message translates to:
  /// **'Can you help people with something?'**
  String get canYouHelp;

  /// No description provided for @youDontProvideThisService.
  ///
  /// In en, this message translates to:
  /// **'You don\'t provide this service yet.'**
  String get youDontProvideThisService;

  /// No description provided for @addCapabilityAction.
  ///
  /// In en, this message translates to:
  /// **'Add {capability}'**
  String addCapabilityAction(String capability);

  /// No description provided for @opportunitiesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 opportunity} other{{count} opportunities}}'**
  String opportunitiesCount(int count);

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navPost.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get navPost;

  /// No description provided for @navActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get navActivity;

  /// No description provided for @postChoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'What do you want to post?'**
  String get postChoiceTitle;

  /// No description provided for @postLoanAction.
  ///
  /// In en, this message translates to:
  /// **'Loan'**
  String get postLoanAction;

  /// No description provided for @postLoanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a loan request'**
  String get postLoanSubtitle;

  /// No description provided for @postForexAction.
  ///
  /// In en, this message translates to:
  /// **'Forex'**
  String get postForexAction;

  /// No description provided for @postForexSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a currency exchange request'**
  String get postForexSubtitle;

  /// No description provided for @postNeedAction.
  ///
  /// In en, this message translates to:
  /// **'Need'**
  String get postNeedAction;

  /// No description provided for @postNeedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a Need'**
  String get postNeedSubtitle;

  /// No description provided for @forYouTitle.
  ///
  /// In en, this message translates to:
  /// **'For You'**
  String get forYouTitle;

  /// No description provided for @peopleLookingForServices.
  ///
  /// In en, this message translates to:
  /// **'People are looking for what you provide'**
  String get peopleLookingForServices;

  /// No description provided for @addYourServicesPrompt.
  ///
  /// In en, this message translates to:
  /// **'Can you help people with something?'**
  String get addYourServicesPrompt;

  /// No description provided for @whatCanYouHelpWith.
  ///
  /// In en, this message translates to:
  /// **'What can you help people with?'**
  String get whatCanYouHelpWith;

  /// No description provided for @whatCanYouHelpWithSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us what you offer and we\'ll match you with people looking for it.'**
  String get whatCanYouHelpWithSubtitle;

  /// No description provided for @addYourServicesCta.
  ///
  /// In en, this message translates to:
  /// **'Add your services'**
  String get addYourServicesCta;

  /// No description provided for @newCategoriesAvailable.
  ///
  /// In en, this message translates to:
  /// **'New categories are available'**
  String get newCategoriesAvailable;

  /// No description provided for @newCategoriesAvailableSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ve added {categories}. You might have something to offer there.'**
  String newCategoriesAvailableSubtitle(Object categories);

  /// No description provided for @exploreNewCategoriesCta.
  ///
  /// In en, this message translates to:
  /// **'Explore new categories'**
  String get exploreNewCategoriesCta;

  /// No description provided for @matchingNeedsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{# new request matches your services.} other{# new requests match your services.}}'**
  String matchingNeedsSubtitle(int count);

  /// No description provided for @seeOpportunitiesCta.
  ///
  /// In en, this message translates to:
  /// **'See opportunities'**
  String get seeOpportunitiesCta;

  /// No description provided for @discoveryQuestionTitle.
  ///
  /// In en, this message translates to:
  /// **'A quick question'**
  String get discoveryQuestionTitle;

  /// No description provided for @discoveryBusinessTitle.
  ///
  /// In en, this message translates to:
  /// **'Planning something ahead?'**
  String get discoveryBusinessTitle;

  /// No description provided for @discoveryBusinessQuestion.
  ///
  /// In en, this message translates to:
  /// **'Do you need equipment, logistics, procurement, or business services soon?'**
  String get discoveryBusinessQuestion;

  /// No description provided for @discoveryTravelQuestion.
  ///
  /// In en, this message translates to:
  /// **'Are you planning travel in the next few months?'**
  String get discoveryTravelQuestion;

  /// No description provided for @discoveryEducationQuestion.
  ///
  /// In en, this message translates to:
  /// **'Would internship or professional development opportunities be useful to you?'**
  String get discoveryEducationQuestion;

  /// No description provided for @discoveryFinancialQuestion.
  ///
  /// In en, this message translates to:
  /// **'Are you interested in loans, financing, or Forex opportunities?'**
  String get discoveryFinancialQuestion;

  /// No description provided for @discoveryEquipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get discoveryEquipment;

  /// No description provided for @discoveryLogistics.
  ///
  /// In en, this message translates to:
  /// **'Logistics'**
  String get discoveryLogistics;

  /// No description provided for @discoveryServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get discoveryServices;

  /// No description provided for @discoveryProcurement.
  ///
  /// In en, this message translates to:
  /// **'Procurement'**
  String get discoveryProcurement;

  /// No description provided for @discoveryYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get discoveryYes;

  /// No description provided for @discoveryLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get discoveryLater;

  /// No description provided for @discoveryNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get discoveryNotNow;

  /// No description provided for @discoveryNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get discoveryNo;

  /// No description provided for @discoveryLoans.
  ///
  /// In en, this message translates to:
  /// **'Loans'**
  String get discoveryLoans;

  /// No description provided for @discoveryForex.
  ///
  /// In en, this message translates to:
  /// **'Forex'**
  String get discoveryForex;

  /// No description provided for @discoveryBoth.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get discoveryBoth;

  /// No description provided for @discoveryTravelCta.
  ///
  /// In en, this message translates to:
  /// **'Explore travel help'**
  String get discoveryTravelCta;

  /// No description provided for @discoveryEducationCta.
  ///
  /// In en, this message translates to:
  /// **'Explore education'**
  String get discoveryEducationCta;

  /// No description provided for @discoveryBusinessCta.
  ///
  /// In en, this message translates to:
  /// **'Explore opportunities'**
  String get discoveryBusinessCta;

  /// No description provided for @discoveryFinancialCta.
  ///
  /// In en, this message translates to:
  /// **'Open marketplace'**
  String get discoveryFinancialCta;

  /// No description provided for @discoveryOptionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Discovery options'**
  String get discoveryOptionsTooltip;

  /// No description provided for @discoveryHideQuestion.
  ///
  /// In en, this message translates to:
  /// **'Hide this question'**
  String get discoveryHideQuestion;

  /// No description provided for @discoveryFewerQuestions.
  ///
  /// In en, this message translates to:
  /// **'Show fewer like this'**
  String get discoveryFewerQuestions;

  /// No description provided for @discoverySkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get discoverySkip;

  /// No description provided for @discoveryExploreOpportunities.
  ///
  /// In en, this message translates to:
  /// **'Explore opportunities'**
  String get discoveryExploreOpportunities;

  /// No description provided for @savedPlansTitle.
  ///
  /// In en, this message translates to:
  /// **'Plans & interests'**
  String get savedPlansTitle;

  /// No description provided for @savedPlansEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No saved plans yet'**
  String get savedPlansEmptyTitle;

  /// No description provided for @savedPlansEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Private plans and interests you save from discovery questions will appear here.'**
  String get savedPlansEmptySubtitle;

  /// No description provided for @savedPlanActions.
  ///
  /// In en, this message translates to:
  /// **'Plan actions'**
  String get savedPlanActions;

  /// No description provided for @savedPlanEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get savedPlanEdit;

  /// No description provided for @savedPlanDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get savedPlanDelete;

  /// No description provided for @savedPlanReminderSet.
  ///
  /// In en, this message translates to:
  /// **'Reminder set'**
  String get savedPlanReminderSet;

  /// No description provided for @savedPlanUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String savedPlanUpdated(String date);

  /// No description provided for @savedPlanTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get savedPlanTravel;

  /// No description provided for @savedPlanEducationCareer.
  ///
  /// In en, this message translates to:
  /// **'Education & career'**
  String get savedPlanEducationCareer;

  /// No description provided for @savedPlanBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get savedPlanBusiness;

  /// No description provided for @savedPlanFinancial.
  ///
  /// In en, this message translates to:
  /// **'Financial'**
  String get savedPlanFinancial;

  /// No description provided for @savedPlanGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get savedPlanGeneral;

  /// No description provided for @savedPlanNoDetails.
  ///
  /// In en, this message translates to:
  /// **'No details added yet'**
  String get savedPlanNoDetails;

  /// No description provided for @savedPlanDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete plan?'**
  String get savedPlanDeleteTitle;

  /// No description provided for @savedPlanDeleteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'This removes the private saved plan from your account.'**
  String get savedPlanDeleteConfirmation;

  /// No description provided for @savedPlanCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get savedPlanCancel;

  /// No description provided for @savedPlanEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit plan'**
  String get savedPlanEditTitle;

  /// No description provided for @savedPlanName.
  ///
  /// In en, this message translates to:
  /// **'Plan name'**
  String get savedPlanName;

  /// No description provided for @savedPlanDestination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get savedPlanDestination;

  /// No description provided for @savedPlanPreferredLocation.
  ///
  /// In en, this message translates to:
  /// **'Preferred location'**
  String get savedPlanPreferredLocation;

  /// No description provided for @savedPlanTimeframe.
  ///
  /// In en, this message translates to:
  /// **'Approximate timeframe'**
  String get savedPlanTimeframe;

  /// No description provided for @savedPlanAddDate.
  ///
  /// In en, this message translates to:
  /// **'Add expected date'**
  String get savedPlanAddDate;

  /// No description provided for @savedPlanReminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get savedPlanReminder;

  /// No description provided for @savedPlanNoReminder.
  ///
  /// In en, this message translates to:
  /// **'No reminder'**
  String get savedPlanNoReminder;

  /// No description provided for @savedPlanOneWeekBefore.
  ///
  /// In en, this message translates to:
  /// **'One week before'**
  String get savedPlanOneWeekBefore;

  /// No description provided for @savedPlanOneMonthBefore.
  ///
  /// In en, this message translates to:
  /// **'One month before'**
  String get savedPlanOneMonthBefore;

  /// No description provided for @savedPlanSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get savedPlanSave;

  /// No description provided for @savedPlanStartingLocation.
  ///
  /// In en, this message translates to:
  /// **'Starting location'**
  String get savedPlanStartingLocation;

  /// No description provided for @savedPlanAssistanceNeeded.
  ///
  /// In en, this message translates to:
  /// **'Assistance needed'**
  String get savedPlanAssistanceNeeded;

  /// No description provided for @savedPlanWhatWouldHelp.
  ///
  /// In en, this message translates to:
  /// **'What would be useful?'**
  String get savedPlanWhatWouldHelp;

  /// Compact post duration badge label
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Active for 1 day.} other{Active for {days} days.}}'**
  String postDurationActiveDays(int days);

  /// Full post duration statement
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Your request will be active for 1 day.} other{Your request will be active for {days} days.}}'**
  String postDurationFullNotice(int days);

  /// Supporting note that requests automatically expire
  ///
  /// In en, this message translates to:
  /// **'Your request will automatically expire after this period.'**
  String get postDurationNotice;

  /// No description provided for @nationalityUgandan.
  ///
  /// In en, this message translates to:
  /// **'Ugandan'**
  String get nationalityUgandan;

  /// No description provided for @nationalityKenyan.
  ///
  /// In en, this message translates to:
  /// **'Kenyan'**
  String get nationalityKenyan;

  /// No description provided for @nationalityTanzanian.
  ///
  /// In en, this message translates to:
  /// **'Tanzanian'**
  String get nationalityTanzanian;

  /// No description provided for @nationalityRwandan.
  ///
  /// In en, this message translates to:
  /// **'Rwandan'**
  String get nationalityRwandan;

  /// No description provided for @nationalityNigerian.
  ///
  /// In en, this message translates to:
  /// **'Nigerian'**
  String get nationalityNigerian;

  /// No description provided for @nationalitySouthAfrican.
  ///
  /// In en, this message translates to:
  /// **'South African'**
  String get nationalitySouthAfrican;

  /// No description provided for @nationalityEgyptian.
  ///
  /// In en, this message translates to:
  /// **'Egyptian'**
  String get nationalityEgyptian;

  /// No description provided for @nationalityCongoleseDrc.
  ///
  /// In en, this message translates to:
  /// **'Congolese (DRC)'**
  String get nationalityCongoleseDrc;

  /// No description provided for @nationalityBurundian.
  ///
  /// In en, this message translates to:
  /// **'Burundian'**
  String get nationalityBurundian;

  /// No description provided for @nationalitySouthSudanese.
  ///
  /// In en, this message translates to:
  /// **'South Sudanese'**
  String get nationalitySouthSudanese;

  /// No description provided for @nationalitySomali.
  ///
  /// In en, this message translates to:
  /// **'Somali'**
  String get nationalitySomali;

  /// No description provided for @iWantJobs.
  ///
  /// In en, this message translates to:
  /// **'I want jobs'**
  String get iWantJobs;

  /// No description provided for @iWantJobsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure a work-seeking profile for this category'**
  String get iWantJobsSubtitle;

  /// No description provided for @searchCategories.
  ///
  /// In en, this message translates to:
  /// **'Search categories'**
  String get searchCategories;

  /// No description provided for @searchCatalog.
  ///
  /// In en, this message translates to:
  /// **'Search categories, services and roles'**
  String get searchCatalog;

  /// No description provided for @catalogNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No match'**
  String get catalogNoMatch;

  /// No description provided for @requestService.
  ///
  /// In en, this message translates to:
  /// **'Request a service'**
  String get requestService;

  /// No description provided for @catalogRequestSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Service request submitted'**
  String get catalogRequestSubmitted;

  /// No description provided for @reportContent.
  ///
  /// In en, this message translates to:
  /// **'Report content'**
  String get reportContent;

  /// No description provided for @contentReportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report submitted'**
  String get contentReportSubmitted;

  /// No description provided for @providerSafetyMedical.
  ///
  /// In en, this message translates to:
  /// **'Nipanze does not provide medical advice or guarantee care. Procedures require a licensed provider, consent, and an emergency referral facility.'**
  String get providerSafetyMedical;

  /// No description provided for @providerSafetyInvestment.
  ///
  /// In en, this message translates to:
  /// **'Nipanze does not hold funds, give investment advice, or guarantee returns.'**
  String get providerSafetyInvestment;

  /// No description provided for @providerSafetyTraditional.
  ///
  /// In en, this message translates to:
  /// **'Do not claim to cure illness or guarantee outcomes. Traditional healing is subject to local rules.'**
  String get providerSafetyTraditional;

  /// No description provided for @providerSafetyWellness.
  ///
  /// In en, this message translates to:
  /// **'Massage and spa listings are for therapeutic and wellness services only. Sexual services are prohibited.'**
  String get providerSafetyWellness;

  /// No description provided for @providerSafetyAcademic.
  ///
  /// In en, this message translates to:
  /// **'Get guidance and feedback. Submitting someone else\'s work as your own can get you expelled.'**
  String get providerSafetyAcademic;

  /// No description provided for @providerSafetyDomestic.
  ///
  /// In en, this message translates to:
  /// **'Never include an exact home address in a public profile or listing.'**
  String get providerSafetyDomestic;

  /// No description provided for @noMatchingJobOpportunities.
  ///
  /// In en, this message translates to:
  /// **'No matching job opportunities available yet. Opportunities will appear here as requests are posted.'**
  String get noMatchingJobOpportunities;

  /// No description provided for @selectAtLeastOneRole.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one job role'**
  String get selectAtLeastOneRole;

  /// Count of declared qualifications
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 qualification declared} other{{count} qualifications declared}}'**
  String qualificationsDeclared(int count);

  /// Count of job roles
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 role} other{{count} roles}}'**
  String rolesCount(int count);

  /// No description provided for @providerTypeChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get providerTypeChange;

  /// No description provided for @providerIdentityRequiredInfo.
  ///
  /// In en, this message translates to:
  /// **'Enter the display details and confirm representation authority to continue.'**
  String get providerIdentityRequiredInfo;

  /// No description provided for @providerIdentitySwitchSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your provider identity was switched.'**
  String get providerIdentitySwitchSuccess;

  /// No description provided for @providerIdentityCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get providerIdentityCurrent;

  /// No description provided for @providerIdentityDisplayHeading.
  ///
  /// In en, this message translates to:
  /// **'How should you be shown?'**
  String get providerIdentityDisplayHeading;

  /// No description provided for @providerIdentityDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get providerIdentityDisplayName;

  /// No description provided for @providerIdentityCompanyName.
  ///
  /// In en, this message translates to:
  /// **'Company or business name'**
  String get providerIdentityCompanyName;

  /// No description provided for @providerIdentityCompanyOnly.
  ///
  /// In en, this message translates to:
  /// **'Company name'**
  String get providerIdentityCompanyOnly;

  /// No description provided for @providerIdentityCompanyRepresentative.
  ///
  /// In en, this message translates to:
  /// **'Company with representative'**
  String get providerIdentityCompanyRepresentative;

  /// No description provided for @providerIdentityRepresentativeName.
  ///
  /// In en, this message translates to:
  /// **'Representative name'**
  String get providerIdentityRepresentativeName;

  /// No description provided for @providerIdentityAuthority.
  ///
  /// In en, this message translates to:
  /// **'I am authorized to represent this business'**
  String get providerIdentityAuthority;

  /// No description provided for @providerIdentityRepresentedBy.
  ///
  /// In en, this message translates to:
  /// **'Represented by {name}'**
  String providerIdentityRepresentedBy(String name);

  /// No description provided for @providerIdentitySwitchTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch to {identity}?'**
  String providerIdentitySwitchTitle(String identity);

  /// No description provided for @providerIdentitySwitchBody.
  ///
  /// In en, this message translates to:
  /// **'This changes only this category. Your other categories stay as they are.'**
  String get providerIdentitySwitchBody;

  /// No description provided for @providerIdentityDataKept.
  ///
  /// In en, this message translates to:
  /// **'Your service information is kept. Nothing is deleted.'**
  String get providerIdentityDataKept;

  /// No description provided for @providerIdentityOldServicesInactive.
  ///
  /// In en, this message translates to:
  /// **'Your {identity} services here become inactive and can be restored.'**
  String providerIdentityOldServicesInactive(String identity);

  /// No description provided for @providerIdentityNewOffers.
  ///
  /// In en, this message translates to:
  /// **'New offers will use your {identity} identity.'**
  String providerIdentityNewOffers(String identity);

  /// No description provided for @providerIdentityVerificationReset.
  ///
  /// In en, this message translates to:
  /// **'Verification requirements may change. Verification does not carry over.'**
  String get providerIdentityVerificationReset;

  /// No description provided for @providerIdentityHistoryKept.
  ///
  /// In en, this message translates to:
  /// **'Accepted deals, reviews, history, and personal job roles stay as they are.'**
  String get providerIdentityHistoryKept;

  /// No description provided for @providerIdentityPendingOffers.
  ///
  /// In en, this message translates to:
  /// **'You have {count} pending offers. They stay as sent; you can withdraw them yourself.'**
  String providerIdentityPendingOffers(int count);

  /// No description provided for @providerIdentityReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review your switch'**
  String get providerIdentityReviewTitle;

  /// No description provided for @providerIdentityCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get providerIdentityCategory;

  /// No description provided for @providerIdentityNewIdentity.
  ///
  /// In en, this message translates to:
  /// **'New identity'**
  String get providerIdentityNewIdentity;

  /// No description provided for @providerIdentityPublicName.
  ///
  /// In en, this message translates to:
  /// **'Public name'**
  String get providerIdentityPublicName;

  /// No description provided for @providerIdentityReused.
  ///
  /// In en, this message translates to:
  /// **'Reused from your current setup'**
  String get providerIdentityReused;

  /// No description provided for @providerIdentityNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get providerIdentityNeedsAttention;

  /// No description provided for @providerIdentityCompanyVerificationStatus.
  ///
  /// In en, this message translates to:
  /// **'Company verification is separate and does not carry over.'**
  String get providerIdentityCompanyVerificationStatus;

  /// No description provided for @providerIdentityNoActiveWarning.
  ///
  /// In en, this message translates to:
  /// **'No services will be active in this category after the switch.'**
  String get providerIdentityNoActiveWarning;

  /// No description provided for @providerIdentityConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm switch'**
  String get providerIdentityConfirm;

  /// No description provided for @providerTypeWhatWeOffer.
  ///
  /// In en, this message translates to:
  /// **'What we offer'**
  String get providerTypeWhatWeOffer;

  /// No description provided for @providerTypeWhatRoles.
  ///
  /// In en, this message translates to:
  /// **'What roles do you do?'**
  String get providerTypeWhatRoles;

  /// No description provided for @providerTypeStepOneOfThree.
  ///
  /// In en, this message translates to:
  /// **'STEP 1 OF 3'**
  String get providerTypeStepOneOfThree;

  /// No description provided for @providerTypePickRoles.
  ///
  /// In en, this message translates to:
  /// **'Pick every role that fits you. You can add more later.'**
  String get providerTypePickRoles;

  /// No description provided for @providerTypeNextKind.
  ///
  /// In en, this message translates to:
  /// **'Next: choose your kind'**
  String get providerTypeNextKind;

  /// No description provided for @providerTypeSaveServicesCount.
  ///
  /// In en, this message translates to:
  /// **'Save services {count}'**
  String providerTypeSaveServicesCount(Object count);

  /// No description provided for @providerTypeSelectService.
  ///
  /// In en, this message translates to:
  /// **'Select at least one service'**
  String get providerTypeSelectService;

  /// No description provided for @providerTypeHiddenCompanyOnly.
  ///
  /// In en, this message translates to:
  /// **'Hidden: offered as Company only'**
  String get providerTypeHiddenCompanyOnly;

  /// No description provided for @providerTypeOfferingAs.
  ///
  /// In en, this message translates to:
  /// **'Offering as'**
  String get providerTypeOfferingAs;

  /// No description provided for @providerTypeOffering.
  ///
  /// In en, this message translates to:
  /// **'Offering in this category'**
  String get providerTypeOffering;

  /// No description provided for @providerTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Who is offering?'**
  String get providerTypeTitle;

  /// No description provided for @providerTypeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This tells people whether they would deal with you or with your business. You can set it differently for each category.'**
  String get providerTypeSubtitle;

  /// No description provided for @providerTypeIndividual.
  ///
  /// In en, this message translates to:
  /// **'Individual'**
  String get providerTypeIndividual;

  /// No description provided for @providerTypeIndividualDesc.
  ///
  /// In en, this message translates to:
  /// **'I offer my personal skills directly to clients, as a freelancer or worker.'**
  String get providerTypeIndividualDesc;

  /// No description provided for @providerTypeCompany.
  ///
  /// In en, this message translates to:
  /// **'Company / Organization'**
  String get providerTypeCompany;

  /// No description provided for @providerTypeCompanyDesc.
  ///
  /// In en, this message translates to:
  /// **'A registered business, agency, team or institution.'**
  String get providerTypeCompanyDesc;

  /// No description provided for @providerTypeNotVerification.
  ///
  /// In en, this message translates to:
  /// **'Selecting this does not verify you. Verification is separate and only asked where a service requires it.'**
  String get providerTypeNotVerification;

  /// No description provided for @providerTypeChooseOne.
  ///
  /// In en, this message translates to:
  /// **'Choose one option to continue'**
  String get providerTypeChooseOne;

  /// No description provided for @providerTypeJobsPersonalNote.
  ///
  /// In en, this message translates to:
  /// **'Job profiles are personal and are saved under your own name.'**
  String get providerTypeJobsPersonalNote;

  /// No description provided for @providerTypeStepOneOfTwo.
  ///
  /// In en, this message translates to:
  /// **'STEP 1 OF 2'**
  String get providerTypeStepOneOfTwo;

  /// No description provided for @providerTypeCompanyServicesHint.
  ///
  /// In en, this message translates to:
  /// **'Tick everything your company provides.'**
  String get providerTypeCompanyServicesHint;

  /// No description provided for @providerTypeCompanyRolesHint.
  ///
  /// In en, this message translates to:
  /// **'Optional roles'**
  String get providerTypeCompanyRolesHint;

  /// No description provided for @providerTypeCompanyRolesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tick the roles you work in. These job profiles are personal and saved under your own name. Add machines and qualifications later.'**
  String get providerTypeCompanyRolesSubtitle;

  /// No description provided for @providerTypeCompanySelectionCount.
  ///
  /// In en, this message translates to:
  /// **'{services, plural, =0{No services} =1{1 service} other{{services} services}} · {roles, plural, =0{No roles} =1{1 role} other{{roles} roles}} selected'**
  String providerTypeCompanySelectionCount(int services, int roles);

  /// No description provided for @companyStepTwoOfTwo.
  ///
  /// In en, this message translates to:
  /// **'STEP 2 OF 2'**
  String get companyStepTwoOfTwo;

  /// No description provided for @companyDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your company'**
  String get companyDetailsTitle;

  /// No description provided for @companyDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Everything here is optional. These details are private to you and Nipanze administrators.'**
  String get companyDetailsSubtitle;

  /// No description provided for @companyName.
  ///
  /// In en, this message translates to:
  /// **'Company or business name'**
  String get companyName;

  /// No description provided for @companyRegistrationNumber.
  ///
  /// In en, this message translates to:
  /// **'Registration number'**
  String get companyRegistrationNumber;

  /// No description provided for @companyRegistrationPrivate.
  ///
  /// In en, this message translates to:
  /// **'Visible only to you and Nipanze administrators.'**
  String get companyRegistrationPrivate;

  /// No description provided for @companyTeamSize.
  ///
  /// In en, this message translates to:
  /// **'Team size'**
  String get companyTeamSize;

  /// No description provided for @companyYearsInBusiness.
  ///
  /// In en, this message translates to:
  /// **'Years in business'**
  String get companyYearsInBusiness;

  /// No description provided for @companyServiceAreas.
  ///
  /// In en, this message translates to:
  /// **'Where do you work?'**
  String get companyServiceAreas;

  /// No description provided for @companyServiceAreasHint.
  ///
  /// In en, this message translates to:
  /// **'District or city only. Your exact address is never shown. Separate areas with commas.'**
  String get companyServiceAreasHint;

  /// No description provided for @companyProofTitle.
  ///
  /// In en, this message translates to:
  /// **'Proof for the verified badge'**
  String get companyProofTitle;

  /// No description provided for @companyProofIntro.
  ///
  /// In en, this message translates to:
  /// **'Reviewed by Nipanze. Uploads alone do not verify you.'**
  String get companyProofIntro;

  /// No description provided for @companyNoEvidenceRequirements.
  ///
  /// In en, this message translates to:
  /// **'No proof is required for these services right now.'**
  String get companyNoEvidenceRequirements;

  /// No description provided for @companyProofNote.
  ///
  /// In en, this message translates to:
  /// **'You can save now and add proof later. JPG, PNG, or PDF, up to 5 MB each.'**
  String get companyProofNote;

  /// No description provided for @companyEvidenceNotAdded.
  ///
  /// In en, this message translates to:
  /// **'Not added'**
  String get companyEvidenceNotAdded;

  /// No description provided for @companyEvidenceUploaded.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get companyEvidenceUploaded;

  /// No description provided for @companyEvidenceUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get companyEvidenceUnderReview;

  /// No description provided for @companyEvidenceRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get companyEvidenceRejected;

  /// No description provided for @companyEvidenceExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get companyEvidenceExpired;

  /// No description provided for @companyEvidenceApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get companyEvidenceApproved;

  /// No description provided for @companyEvidenceAdd.
  ///
  /// In en, this message translates to:
  /// **'Add proof'**
  String get companyEvidenceAdd;

  /// No description provided for @companyEvidenceReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get companyEvidenceReplace;

  /// No description provided for @companyEvidenceReadError.
  ///
  /// In en, this message translates to:
  /// **'Could not read the selected file. Try another file.'**
  String get companyEvidenceReadError;

  /// No description provided for @companyEvidenceTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Choose a file up to 5 MB.'**
  String get companyEvidenceTooLarge;

  /// No description provided for @companyEvidenceUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Choose a JPG, PNG, or PDF file.'**
  String get companyEvidenceUnsupported;

  /// No description provided for @companySave.
  ///
  /// In en, this message translates to:
  /// **'Save company profile'**
  String get companySave;

  /// No description provided for @companySelectionCount.
  ///
  /// In en, this message translates to:
  /// **'{services, plural, =0{No services} =1{1 service} other{{services} services}} · {roles, plural, =0{No roles} =1{1 role} other{{roles} roles}}'**
  String companySelectionCount(int services, int roles);

  /// No description provided for @companyTeamOneToFive.
  ///
  /// In en, this message translates to:
  /// **'1–5'**
  String get companyTeamOneToFive;

  /// No description provided for @companyTeamSixToTwenty.
  ///
  /// In en, this message translates to:
  /// **'6–20'**
  String get companyTeamSixToTwenty;

  /// No description provided for @companyTeamTwentyOneToFifty.
  ///
  /// In en, this message translates to:
  /// **'21–50'**
  String get companyTeamTwentyOneToFifty;

  /// No description provided for @companyTeamFiftyPlus.
  ///
  /// In en, this message translates to:
  /// **'50+'**
  String get companyTeamFiftyPlus;

  /// No description provided for @companyYearsUnderOne.
  ///
  /// In en, this message translates to:
  /// **'Under 1'**
  String get companyYearsUnderOne;

  /// No description provided for @companyYearsOneToTwo.
  ///
  /// In en, this message translates to:
  /// **'1–2'**
  String get companyYearsOneToTwo;

  /// No description provided for @companyYearsThreeToFive.
  ///
  /// In en, this message translates to:
  /// **'3–5'**
  String get companyYearsThreeToFive;

  /// No description provided for @companyYearsSixToTen.
  ///
  /// In en, this message translates to:
  /// **'6–10'**
  String get companyYearsSixToTen;

  /// No description provided for @companyYearsTenPlus.
  ///
  /// In en, this message translates to:
  /// **'10+'**
  String get companyYearsTenPlus;

  /// No description provided for @providerTypeGroupCount.
  ///
  /// In en, this message translates to:
  /// **'{selected} of {total}'**
  String providerTypeGroupCount(Object selected, Object total);

  /// No description provided for @companyPersonalProfile.
  ///
  /// In en, this message translates to:
  /// **'Personal profile'**
  String get companyPersonalProfile;

  /// No description provided for @providerTypeJobNeedsDetails.
  ///
  /// In en, this message translates to:
  /// **'Add machines and qualifications to get matched.'**
  String get providerTypeJobNeedsDetails;

  /// No description provided for @providerTypeNextCompanyDetails.
  ///
  /// In en, this message translates to:
  /// **'Next: company details'**
  String get providerTypeNextCompanyDetails;

  /// No description provided for @providerSummaryAll.
  ///
  /// In en, this message translates to:
  /// **'All {count}'**
  String providerSummaryAll(int count);

  /// No description provided for @providerSummaryServices.
  ///
  /// In en, this message translates to:
  /// **'Services {count}'**
  String providerSummaryServices(int count);

  /// No description provided for @providerSummaryJobs.
  ///
  /// In en, this message translates to:
  /// **'Jobs {count}'**
  String providerSummaryJobs(int count);

  /// No description provided for @companyProfileSaved.
  ///
  /// In en, this message translates to:
  /// **'Company profile saved.'**
  String get companyProfileSaved;

  /// No description provided for @providerEvidenceTab.
  ///
  /// In en, this message translates to:
  /// **'Provider evidence'**
  String get providerEvidenceTab;

  /// No description provided for @providerEvidenceHeader.
  ///
  /// In en, this message translates to:
  /// **'Provider capability evidence waiting for review'**
  String get providerEvidenceHeader;

  /// No description provided for @providerEvidenceEmpty.
  ///
  /// In en, this message translates to:
  /// **'No provider evidence is waiting for review.'**
  String get providerEvidenceEmpty;

  /// No description provided for @providerEvidenceCapabilities.
  ///
  /// In en, this message translates to:
  /// **'capabilities'**
  String get providerEvidenceCapabilities;

  /// No description provided for @providerEvidenceOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Open shared evidence file'**
  String get providerEvidenceOpenFile;

  /// No description provided for @providerEvidenceCompanyDetails.
  ///
  /// In en, this message translates to:
  /// **'Company details (admin only)'**
  String get providerEvidenceCompanyDetails;

  /// No description provided for @providerEvidenceApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve this capability'**
  String get providerEvidenceApprove;

  /// No description provided for @providerEvidenceReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get providerEvidenceReject;

  /// No description provided for @providerEvidenceRejectReason.
  ///
  /// In en, this message translates to:
  /// **'Reject evidence'**
  String get providerEvidenceRejectReason;

  /// No description provided for @providerEvidenceReason.
  ///
  /// In en, this message translates to:
  /// **'Reason for rejection'**
  String get providerEvidenceReason;

  /// No description provided for @providerEvidenceReviewSaved.
  ///
  /// In en, this message translates to:
  /// **'Evidence review saved.'**
  String get providerEvidenceReviewSaved;

  /// No description provided for @providerCapabilityActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get providerCapabilityActive;

  /// No description provided for @providerCapabilityInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get providerCapabilityInactive;

  /// No description provided for @providerCapabilityPendingReview.
  ///
  /// In en, this message translates to:
  /// **'Pending review'**
  String get providerCapabilityPendingReview;

  /// No description provided for @providerCapabilityRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get providerCapabilityRejected;

  /// No description provided for @providerPolicyNoProof.
  ///
  /// In en, this message translates to:
  /// **'No proof required'**
  String get providerPolicyNoProof;

  /// No description provided for @providerPolicyProofLater.
  ///
  /// In en, this message translates to:
  /// **'Add proof to be considered for a Nipanze badge'**
  String get providerPolicyProofLater;

  /// No description provided for @providerPolicyProofRequired.
  ///
  /// In en, this message translates to:
  /// **'Proof required before it goes live'**
  String get providerPolicyProofRequired;

  /// No description provided for @providerPolicyNeedsProofTag.
  ///
  /// In en, this message translates to:
  /// **'Needs proof'**
  String get providerPolicyNeedsProofTag;

  /// No description provided for @providerPolicyUploadDocuments.
  ///
  /// In en, this message translates to:
  /// **'Upload documents'**
  String get providerPolicyUploadDocuments;

  /// No description provided for @providerEvidenceNoRequirements.
  ///
  /// In en, this message translates to:
  /// **'No evidence is configured for this capability.'**
  String get providerEvidenceNoRequirements;

  /// No description provided for @providerEvidenceSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Evidence submitted for review.'**
  String get providerEvidenceSubmitted;

  /// No description provided for @companyVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Company verification'**
  String get companyVerificationTitle;

  /// No description provided for @companyVerificationIntro.
  ///
  /// In en, this message translates to:
  /// **'Optional. Upload one or both documents for manual review by Nipanze.'**
  String get companyVerificationIntro;

  /// No description provided for @companyVerificationRegistration.
  ///
  /// In en, this message translates to:
  /// **'Business registration certificate'**
  String get companyVerificationRegistration;

  /// No description provided for @companyVerificationLicence.
  ///
  /// In en, this message translates to:
  /// **'Licences or authorization documents'**
  String get companyVerificationLicence;

  /// No description provided for @companyVerificationNotSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Not submitted'**
  String get companyVerificationNotSubmitted;

  /// No description provided for @companyVerificationPending.
  ///
  /// In en, this message translates to:
  /// **'Pending review'**
  String get companyVerificationPending;

  /// No description provided for @companyVerificationVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get companyVerificationVerified;

  /// No description provided for @companyVerificationRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get companyVerificationRejected;

  /// No description provided for @companyVerificationSeparateNote.
  ///
  /// In en, this message translates to:
  /// **'A registration certificate does not authorize regulated services. Those are verified separately, per service.'**
  String get companyVerificationSeparateNote;

  /// No description provided for @companyVerificationFileHint.
  ///
  /// In en, this message translates to:
  /// **'JPG, PNG or PDF, up to 5 MB each. You can save now and add proof later.'**
  String get companyVerificationFileHint;

  /// No description provided for @companyVerificationUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload document'**
  String get companyVerificationUpload;

  /// No description provided for @companyVerificationUploaded.
  ///
  /// In en, this message translates to:
  /// **'Document submitted'**
  String get companyVerificationUploaded;

  /// No description provided for @providerTypeEditCompanyDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit company details'**
  String get providerTypeEditCompanyDetails;

  /// No description provided for @providerTypeOtherGroup.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get providerTypeOtherGroup;

  /// No description provided for @providerTypeNoRolesConfigured.
  ///
  /// In en, this message translates to:
  /// **'No specific job roles are configured for this category yet.'**
  String get providerTypeNoRolesConfigured;

  /// No description provided for @providerNoJobRolesAdded.
  ///
  /// In en, this message translates to:
  /// **'No job roles added'**
  String get providerNoJobRolesAdded;

  /// No description provided for @providerAvailableForJobs.
  ///
  /// In en, this message translates to:
  /// **'Available for jobs'**
  String get providerAvailableForJobs;

  /// No description provided for @providerOpenJobsMatch.
  ///
  /// In en, this message translates to:
  /// **'{count} open jobs match'**
  String providerOpenJobsMatch(int count);

  /// No description provided for @companyLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave company setup?'**
  String get companyLeaveTitle;

  /// No description provided for @companyLeaveSelectionsMessage.
  ///
  /// In en, this message translates to:
  /// **'Your selected services and roles have not been saved.'**
  String get companyLeaveSelectionsMessage;

  /// No description provided for @companyLeaveDetailsMessage.
  ///
  /// In en, this message translates to:
  /// **'Your company details and selections have not been saved.'**
  String get companyLeaveDetailsMessage;

  /// No description provided for @companyLeaveKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get companyLeaveKeepEditing;

  /// No description provided for @companyLeaveDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard changes'**
  String get companyLeaveDiscard;
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
