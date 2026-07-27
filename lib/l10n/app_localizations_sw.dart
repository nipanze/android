// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swahili (`sw`).
class AppLocalizationsSw extends AppLocalizations {
  AppLocalizationsSw([String locale = 'sw']) : super(locale);

  @override
  String get appTitle => 'Nipanze';

  @override
  String get welcomeTitle => 'Kopa. Kopesha. Kua.';

  @override
  String get welcomeTagline => 'Tazama matangazo ya eneo lako';

  @override
  String get welcomeSubtitle =>
      'Soko linaloaminika linalounganisha wakopaji na wakopeshi.';

  @override
  String get selectLanguage => 'Chagua Lugha';

  @override
  String get choosePreferredLanguage => 'Chagua lugha unayopendelea';

  @override
  String get continueWithPhone => 'Endelea na Nambari ya Simu';

  @override
  String get continueWithEmail => 'Endelea na Barua Pepe';

  @override
  String get getStartedTitle => 'Anza na Nipanze';

  @override
  String get getStartedSubtitle => 'Chagua jinsi ungependa kuendelea';

  @override
  String get createAccount => 'Fungua Akaunti';

  @override
  String get createAccountSubtitle =>
      'Mpya kwenye Nipanze? Jiandikishe kwa nambari ya simu';

  @override
  String get logIn => 'Ingia';

  @override
  String get logInSubtitle => 'Tayari una akaunti? Ingia';

  @override
  String get welcomeBack => 'Karibu tena 👋';

  @override
  String get loginToAccount => 'Ingia kwenye akaunti yako';

  @override
  String get phone => 'Simu';

  @override
  String get email => 'Barua Pepe';

  @override
  String get phoneNumber => 'Nambari ya Simu';

  @override
  String get password => 'Nenosiri';

  @override
  String get confirmPassword => 'Thibitisha nenosiri';

  @override
  String get createPassword => 'Tengeneza nenosiri';

  @override
  String get rememberMe => 'Nikumbuke';

  @override
  String get forgotPassword => 'Umesahau nenosiri?';

  @override
  String get dontHaveAccount => 'Huna akaunti?';

  @override
  String get signUp => 'Jiandikishe';

  @override
  String get enterPhoneTitle => 'Weka nambari yako ya simu';

  @override
  String get enterPhoneSubtitle => 'Tutakutumia nambari ya uhakiki';

  @override
  String get sendCode => 'Tuma Nambari ya Uhakiki';

  @override
  String get tellUsAboutYou => 'Twambie kuhusu wewe';

  @override
  String get completeProfileSubtitle =>
      'Kamilisha wasifu wako na uweke nenosiri';

  @override
  String get fullName => 'Jina kamili';

  @override
  String get finish => 'Maliza';

  @override
  String get termsNotice =>
      'Kwa kuendelea, unakubaliana na Masharti ya Matumizi na Siasa ya Faragha wetu.';

  @override
  String get phoneSafeTitle => 'Nambari yako iko salama nasi';

  @override
  String get phoneSafeSubtitle => 'Hatushirikishi nambari yako na mtu yeyote.';

  @override
  String get navMarkets => 'Soko';

  @override
  String get navWatchlist => 'Fuatilia';

  @override
  String get navRequest => 'Omba';

  @override
  String get navPositions => 'Shughuli';

  @override
  String get navAccount => 'Akaunti';

  @override
  String get marketplaceTitle => 'Soko la Mikopo';

  @override
  String listingsLive(int count) {
    return '$count orodha · mubashara';
  }

  @override
  String get filtered => 'Imechujwa';

  @override
  String get applyingFilters => 'Inachuja…';

  @override
  String get noListingsFound => 'Hakuna orodha iliyopatikana';

  @override
  String get noListingsSubtitle =>
      'Angalia tena hivi karibuni — orodha mpya hutokea wakati huo huo.';

  @override
  String get noMatches => 'Hakuna matokeo';

  @override
  String get noMatchesSubtitle =>
      'Hakuna orodha inayolingana na vichujio vyako vya Pro.\nJaribu kubadilisha au kufuta vichujio.';

  @override
  String get adjustFilters => 'Badilisha vichujio';

  @override
  String get removeFromWatchlist => 'Odosha kwenye watchlist';

  @override
  String get saveToWatchlist => 'Hifadhi kwenye watchlist';

  @override
  String get months => 'miezi';

  @override
  String daysLeft(int count) {
    return '${count}s imebaki';
  }

  @override
  String hoursLeft(int count) {
    return '${count}s imebaki';
  }

  @override
  String minutesLeft(int count) {
    return '${count}d imebaki';
  }

  @override
  String get expired => 'Imemalizika';

  @override
  String get watchlistTitle => 'Orodha ya Ufuatiliaji';

  @override
  String get watchlistSubtitle => 'Orodha unazofuatilia';

  @override
  String watchlistSaved(int count) {
    return '$count zilizohifadhiwa';
  }

  @override
  String get watchlistInfoSubscribed =>
      'Bure kwa watumiaji wote. Pokea arifa wakati orodha inabadilika, viwango vinavyoboreka, au orodha inafunga.';

  @override
  String get watchlistInfoFree =>
      'Bure kwa watumiaji wote. Pokea arifa wakati orodha inabadilika. Jiandikishe kutoa mapendekezo.';

  @override
  String get watchlistError => 'Hitilafu kupakia orodha ya ufuatiliaji';

  @override
  String get watchlistEmpty => 'Hakuna orodha zilizohifadhiwa';

  @override
  String get watchlistEmptySubtitle =>
      'Vinjari soko na bonyeza \"Hifadhi kwenye watchlist\" kwenye orodha yoyote.';

  @override
  String get browseMarketplace => 'Vinjari soko';

  @override
  String get removedFromWatchlist => 'Imeondolewa kwenye watchlist';

  @override
  String get undo => 'Tendua';

  @override
  String get tryAgain => 'Jaribu tena';

  @override
  String get myActivityTitle => 'Shughuli Zangu';

  @override
  String get myActivitySubtitle => 'Simamia orodha na maombi yako';

  @override
  String myActivityStats(int listings, int offers) {
    return '$listings Orodha · $offers Maombi Yanayoendelea';
  }

  @override
  String get tabMyRequests => 'Maombi Yangu';

  @override
  String get tabMyOffers => 'Mapendekezo Yangu';

  @override
  String get noOffersYet => 'Hakuna mapendekezo bado';

  @override
  String get noOffersSubtitle =>
      'Mapendekezo unayotoa kwenye orodha za soko yataonekana hapa.';

  @override
  String get browseMarketplaceBtn => 'Vinjari Soko';

  @override
  String get activeOffers => 'Mapendekezo Yanayoendelea';

  @override
  String get matchedAccepted => 'Yaliyolingana / Kukubaliwa';

  @override
  String get history => 'Historia';

  @override
  String get withdrawOffer => 'Ondoa Pendekezo?';

  @override
  String withdrawConfirm(int amount) {
    return 'Una uhakika unataka kuondoa pendekezo lako la UGX $amount?';
  }

  @override
  String get keepOffer => 'Weka Pendekezo';

  @override
  String get withdraw => 'Ondoa';

  @override
  String get myRequestsTitle => 'Maombi Yangu';

  @override
  String sectionActive(int count) {
    return 'Yanayoendelea · $count';
  }

  @override
  String sectionContracted(int count) {
    return 'Yaliyosainiwa · $count';
  }

  @override
  String sectionClosed(int count) {
    return 'Yaliyofungwa · $count';
  }

  @override
  String get noLoanRequests => 'Hakuna maombi ya mkopo bado';

  @override
  String get noLoanRequestsSubtitle =>
      'Tuma ombi na wakopeshaji watashindana kukupa kiwango bora.';

  @override
  String get createLoanRequest => 'Unda ombi la mkopo';

  @override
  String get cancelListing => 'Futa orodha?';

  @override
  String cancelListingConfirm(String title) {
    return 'Hii itaondoa \"$title\" kutoka sokoni. Maombi yote yanayosubiri yatakataliwa.';
  }

  @override
  String get keepIt => 'Iacha';

  @override
  String get cancelListingBtn => 'Futa orodha';

  @override
  String get contractNotGenerated => 'Mkataba bado haujatengenezwa.';

  @override
  String get accountTitle => 'Akaunti';

  @override
  String get settingsTitle => 'Mipangilio';

  @override
  String get contactUs => 'Wasiliana Nasi';

  @override
  String get community => 'Jumuiya';

  @override
  String get legal => 'Kisheria';

  @override
  String get signOut => 'Toka';

  @override
  String get signOutConfirm =>
      'Una uhakika unataka kutoka kwenye akaunti yako?';

  @override
  String get cancel => 'Ghairi';

  @override
  String get profileUpdated => 'Wasifu umesasishwa.';

  @override
  String get editProfile => 'Hariri Wasifu';

  @override
  String get identityVerification => 'Uthibitisho wa Utambulisho';

  @override
  String get security => 'Usalama';

  @override
  String get notifications => 'Arifa';

  @override
  String get statListings => 'Orodha';

  @override
  String get statListingsSubtitle => 'Maombi yaliyowasilishwa';

  @override
  String get statOffers => 'Mapendekezo';

  @override
  String get statOffersSubtitle => 'Mapendekezo yaliyotolewa';

  @override
  String get statMatches => 'Mechi';

  @override
  String get statMatchesSubtitle => 'Mechi zilizofanikiwa';

  @override
  String get trustReputation => 'Uaminifu & Sifa';

  @override
  String get subscription => 'Usajili';

  @override
  String get upgradeToPro => 'Panda hadi Pro';

  @override
  String get viewPlansUpgrade => 'Angalia mipango & panda';

  @override
  String get adminDashboard => 'Dashibodi ya Msimamizi';

  @override
  String memberSince(String date) {
    return 'Mwanachama tangu $date';
  }

  @override
  String get verified => 'Imethibitishwa';

  @override
  String get districtNotSet => 'Wilaya haijawekwa';

  @override
  String get nipanzeDisclaimer =>
      'Nipanze ni jukwaa la kuoanisha tu. Hatushikili, hatuhamishe, wala hatutatuliwe fedha. Miamala yote hutokea moja kwa moja kati ya washiriki.';
}
