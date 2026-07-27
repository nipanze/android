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

  @override
  String get lenderRequired => 'Kiwango cha Mkopeshi kinahitajika';

  @override
  String get lenderRequiredSubtitle =>
      'Kutoa maombi ni sehemu ya mpango wa Mkopeshi (pamoja na Pro). Boresha ili kufungua uwekaji wa dau kwenye orodha yoyote.';

  @override
  String get lenderTier => 'Kiwango cha Mkopeshi';

  @override
  String get lenderTierDesc =>
      'Kwa yeyote aliye tayari kutoa dau zilizoingizwa kwa muundo na kupata faida kwenye Nipanze.';

  @override
  String get everythingInFree => 'Kila kitu kwenye Bure';

  @override
  String get lenderFeature1 =>
      'Toa dau zilizo na vigezo kamili (kiwango, ada, ratiba)';

  @override
  String get lenderFeature2 => 'Ona maelezo ya dau mahali unaposhiriki';

  @override
  String get chooseLender => 'Chagua Mkopeshi';

  @override
  String get notNow => 'Sio sasa';

  @override
  String get paymentSecurityDisclaimer =>
      'Nipanze haishikili wala kuhamisha fedha. Mabadiliko ya usajili yanathibitishwa kupitia mfumo salama wa malipo.';

  @override
  String get proRequired => 'Kiwango cha Pro kinahitajika';

  @override
  String get proRequiredSubtitle =>
      'Vipengele vya hali ya juu kama mapendekezo ya masharti maalum na vichungi vya hali ya juu vimetengwa kwa wanachama wa Pro.';

  @override
  String get proTier => 'Kiwango cha Pro';

  @override
  String get proTierDesc =>
      'Ufikiaji kamili wa soko, vichungi vya hali ya juu na nafasi ya kwanza ya maombi.';

  @override
  String get everythingInLender => 'Kila kitu kwenye Mkopeshi';

  @override
  String get proFeature1 =>
      'Pendekeza viwango, ada za kuchelewa na masharti ya marejesho';

  @override
  String get proFeature2 =>
      'Vichungi vya hali ya juu (kipato, ajira, iliyothibitishwa)';

  @override
  String get proFeature3 =>
      'Kibaji kilichothibitishwa, alama ya uaminifu na uonekano wa kipaumbele';

  @override
  String get choosePro => 'Chagua Pro';

  @override
  String get plansAndPricing => 'Mipango & Bei';

  @override
  String get chooseAccessTitle => 'Chagua ufikiaji unaohitaji';

  @override
  String chooseAccessSubtitle(String flag, String country) {
    return 'Akaunti moja inaweza kuchapisha maombi na kutoa dau. Bei zinarandana na eneo la akaunti yako ($flag $country).';
  }

  @override
  String get perMonth => ' / mwezi';

  @override
  String get freePlanSubtitle =>
      'Vinjari, fuatilia orodha, chapisha maombi ya msingi, na ukubali dau.';

  @override
  String get freeFeature1 => 'Vinjari soko';

  @override
  String get freeFeature2 => 'Chapisha maombi ya msingi ya mkopo';

  @override
  String get freeFeature3 => 'Kukubali dau zilizopokelewa';

  @override
  String get currentPlan => 'Mpango wa sasa';

  @override
  String get useFree => 'Tumia Bure';

  @override
  String choosePlan(String plan) {
    return 'Chagua $plan';
  }

  @override
  String planSelectedMessage(String plan) {
    return '$plan imechaguliwa. Uwashaji wa malipo salama utapatikana hivi karibuni.';
  }

  @override
  String get unlockDealTitle => 'Fungua mkataba';

  @override
  String get unlockDealAndContact => 'Fungua mkataba & mawasiliano';

  @override
  String get dealAgreementLocked => 'Mkataba umefungwa';

  @override
  String get dealAgreementLockedSubtitle =>
      'Mwombaji na mkopeshi wote wamethibitisha mkataba. Sasa unaweza kufungua mawasiliano ili kuungana moja kwa moja.';

  @override
  String includedInPlan(String plan) {
    return 'Imejumuishwa kwenye mpango wako wa $plan';
  }

  @override
  String get unlimitedUnlocksSubtitle =>
      'Ufunguzi wa mawasiliano bila kikomo bila ada ya ziada.';

  @override
  String welcomeGiftUnlocks(int count) {
    return '🎁 Zawadi ya kuwakaribisha — zimebaki fursa $count za kufungua bure';
  }

  @override
  String get welcomeGiftSubtitle =>
      'Mkataba huu unatumia moja ya fursa zako za bure. Fursa za ziada zinagharimu UGX 5,000.';

  @override
  String get unlockFeeApplies => 'Ada ya kufungua ya UGX 5,000 inatumika';

  @override
  String get unlockFeeAppliesSubtitle =>
      'Fursa yako ya bure imetumika. Boresha kwenda Mkopeshi au Pro kwa fursa zisizo na kikomo za bure.';

  @override
  String get whatHappensNext => 'Nini kinafuata';

  @override
  String get step1Title => 'Maelezo ya mawasiliano yanawekwa wazi';

  @override
  String get step1Desc =>
      'Jina halali, nambari ya simu na barua pepe ya pande zote mbili zitashirikiwa.';

  @override
  String get step2Title => 'Muunganisho wa moja kwa moja';

  @override
  String get step2Desc =>
      'Sasa unaweza kuwasiliana na mshirika wako nje ya jukwaa la Nipanze.';

  @override
  String get step3Title => 'Kamilisha muamala';

  @override
  String get step3Desc =>
      'Kamilisha mkataba wa mkopo na ubadilishane fedha moja kwa moja.';

  @override
  String get disclaimerNonCustodial =>
      'Nipanze haishikili wala kuhamisha fedha zozote. Wewe na mshirika wako mnahusika kikamilifu na miamala yote ya kifedha na utatuzi wa migogoro.';

  @override
  String get payToUnlock => 'Lipa UGX 5,000 Ili Kufungua';

  @override
  String get unlockWithFreeCredit => 'Fungua kwa Salio la Bure';

  @override
  String get unlockContactDetails => 'Fungua maelezo ya mawasiliano';

  @override
  String get upgradeForUnlimited => 'Boresha kwa ufunguzi usio na kikomo';

  @override
  String get contactDetailsRevealed => 'Maelezo ya mawasiliano yamewekwa wazi';

  @override
  String get connectionSuccessful =>
      'Muunganisho umefanikiwa. Hapa kuna maelezo ya mawasiliano:';

  @override
  String get borrower => 'Mkopaji';

  @override
  String get lender => 'Mkopeshi';

  @override
  String get directContactNotice =>
      'Sasa unaweza kuwasiliana na mshirika wako moja kwa moja ili kukamilisha muamala nje ya jukwaa la Nipanze.';

  @override
  String get done => 'Imekamilika';

  @override
  String planTitle(String plan) {
    return 'Mpango wa $plan';
  }

  @override
  String get nonCustodialAccess => 'Ufikiaji usioshikilia fedha';

  @override
  String get howTrustWorks => 'Jinsi uaminifu unavyofanya kazi';

  @override
  String get trustExplanation =>
      'Ishara za uaminifu zinaonyesha tu shughuli zilizokamilishwa kupitia Nipanze. Hazipimi au kudokeza tabia ya urejeshaji ya nje ya jukwaa.';

  @override
  String get trustScore => 'Alama ya uaminifu';

  @override
  String get completeDealsToBuild =>
      'Kamilisha mikataba ili kujenga alama yako';

  @override
  String get noReviewsYet => 'Bado hakuna maoni';

  @override
  String successfulDeals(int count) {
    return 'Mikataba $count iliyofanikiwa';
  }

  @override
  String get repeatParticipant => 'Mshiriki wa kurudia';

  @override
  String get notRepeatYet => 'Bado si mshiriki wa kurudia';

  @override
  String get phoneVerified => 'Simu imethibitishwa';

  @override
  String get phoneNotVerified => 'Simu haijathibitishwa';

  @override
  String get publicTrustSignals =>
      'Ishara za uaminifu za umma zinatokana tu na shughuli zilizokamilishwa kupitia Nipanze.';

  @override
  String get advancedFilters => 'Vichujio vya Hali ya Juu';

  @override
  String get advancedFiltersBadge => 'Pro · Punguza matokeo ya soko';

  @override
  String get filterReset => 'Weka upya';

  @override
  String get filterClear => 'Futa';

  @override
  String get filterApply => 'Tumia vichujio';

  @override
  String get filterDone => 'Imekamilika';

  @override
  String get filterEmploymentType => 'Aina ya ajira';

  @override
  String get filterEmploymentSubtitle =>
      'Chuja kulingana na ajira iliyotangazwa na mkopaji';

  @override
  String get filterIncomeRange => 'Kiwango cha mapato ya kila mwezi';

  @override
  String get filterIncomeSubtitle =>
      'Viwango vya jumla — mapato halisi hayaonyeshwi kamwe';

  @override
  String get filterQualitySignals => 'Dalili za ubora wa orodha';

  @override
  String get filterHasSuggestedTerms => 'Ina masharti yaliyopendekezwa';

  @override
  String get filterHasSuggestedTermsSubtitle =>
      'Orodha za Pro tu zenye kiwango cha riba kilichofungwa, ada ya kuchelewa, na ratiba ya malipo';

  @override
  String get filterVerifiedBorrower => 'Mkopaji aliyethibitishwa';

  @override
  String get filterVerifiedBorrowerSubtitle =>
      'Maombi tu kutoka kwa wamiliki wa akaunti walioidhinishwa na KYC';

  @override
  String get filterPrivacyNote =>
      'Majina ya waajiri na mapato halisi hayaonyeshwi kamwe. Viwango vya mapato na vikundi vya ajira ndivyo ishara pekee zinazopatikana, kwa muundo.';

  @override
  String get empGovEmployee => 'Mfanyakazi wa serikali';

  @override
  String get empEmployedPrivate => 'Mfanyakazi (binafsi)';

  @override
  String get empSelfEmployed => 'Mfanyabiashara binafsi';

  @override
  String get empSmallBusinessOwner => 'Mmiliki wa biashara ndogo';

  @override
  String get empBusinessOwner => 'Mmiliki wa biashara';

  @override
  String get empStudent => 'Mwanafunzi';

  @override
  String get empOther => 'Nyingine';

  @override
  String get incomeUnder2m => 'Chini ya 2M UGX / mwezi';

  @override
  String get income2m5m => '2M – 5M UGX / mwezi';

  @override
  String get income5m10m => '5M – 10M UGX / mwezi';

  @override
  String get incomeOver10m => 'Zaidi ya 10M UGX / mwezi';
}
