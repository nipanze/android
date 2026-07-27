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
  String get editProfile => 'Edit Profile';

  @override
  String get identityVerification => 'Identity Verification';

  @override
  String get security => 'Security';

  @override
  String get notifications => 'Notifications';

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
}
