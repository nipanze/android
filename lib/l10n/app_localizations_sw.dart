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
  String get viewOffers => 'Tazama bei';

  @override
  String get viewContract => 'Tazama mkataba';

  @override
  String get viewListing => 'Tazama ombi';

  @override
  String get offeredAmountLabel => 'Kiasi kilichotolewa';

  @override
  String get statusLabel => 'Hali';

  @override
  String get interestLabel => 'Riba';

  @override
  String get lateFeeLabel => 'Ada ya kuchelewa';

  @override
  String lateFeePerMissedInstallment(String value) {
    return '$value kwa awamu iliyokosekana';
  }

  @override
  String get repaymentLabel => 'Marejesho';

  @override
  String get totalPayableLabel => 'Jumla ya kulipa';

  @override
  String sentDateLabel(String date) {
    return 'Ilitumwa $date';
  }

  @override
  String errorLoadingContract(String error) {
    return 'Hitilafu kupakia mkataba: $error';
  }

  @override
  String listingOfferCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'bei',
      one: 'bei',
    );
    return '$count $_temp0';
  }

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
  String get profileSaved => 'Wasifu umehifadhiwa.';

  @override
  String get editProfile => 'Hariri Wasifu';

  @override
  String get changeProfilePicture => 'Badilisha picha ya wasifu';

  @override
  String get phoneNumberLabel => 'Nambari ya simu';

  @override
  String selectRegionLabel(String label) {
    return 'Chagua $label';
  }

  @override
  String get incomeTypeLabel => 'Aina ya mapato';

  @override
  String get selectIncomeType => 'Chagua aina ya mapato';

  @override
  String get employerBusinessOptionalLabel =>
      'Mwajiri / jina la biashara (si lazima)';

  @override
  String monthlyIncomeWithCurrency(String currency) {
    return 'Mapato ya mwezi ($currency)';
  }

  @override
  String get bankProfessionalTagLabel => 'Benki & Lebo ya Kitaalamu';

  @override
  String get preferredDepositBankLabel =>
      'Benki unayopendelea au ya kuweka pesa (si lazima)';

  @override
  String get preferredDepositBankHint =>
      'mf. Equity Bank, Bank of Kigali, Stanbic, KCB';

  @override
  String get accountRepresentsLabel => 'Akaunti inawakilisha';

  @override
  String get individualPersonalAccountLabel => 'Mtu binafsi / akaunti binafsi';

  @override
  String get bankLabel => 'Benki';

  @override
  String get forexExchangeCompanyLabel => 'Kampuni ya ubadilishaji fedha';

  @override
  String get saccoLabel => 'SACCO';

  @override
  String get companyLabel => 'Kampuni';

  @override
  String get bankLoanAgentLabel => 'Mimi ni wakala wa mikopo wa benki';

  @override
  String get bankLoanAgentSubtitle =>
      'Huonyesha lebo ya wakala wa benki kwa watumiaji wa Pro wanaotafuta mikopo ya benki.';

  @override
  String get showProfessionalTagLabel => 'Onyesha lebo yangu ya kitaalamu';

  @override
  String get showProfessionalTagSubtitle =>
      'Zima ili kuficha lebo za benki, kampuni ya forex, SACCO, au wakala kwenye bei.';

  @override
  String get saveChanges => 'Hifadhi mabadiliko';

  @override
  String get enterFullName => 'Weka jina lako kamili';

  @override
  String avatarUploadFailed(String error) {
    return 'Kupakia picha kumeshindikana: $error';
  }

  @override
  String couldNotSelectImage(String error) {
    return 'Haikuweza kuchagua picha: $error';
  }

  @override
  String get identityVerification => 'Uthibitisho wa Utambulisho';

  @override
  String get security => 'Usalama';

  @override
  String get notifications => 'Arifa';

  @override
  String get markAllRead => 'Weka zote kuwa zimesomwa';

  @override
  String get noNotificationsYet => 'Hakuna arifa bado';

  @override
  String get noNotificationsSubtitle =>
      'Utaarifiwa hapa bei zikifika, viwango vikibadilika, au mikataba ikiwa tayari.';

  @override
  String get todayLabel => 'LEO';

  @override
  String get yesterdayLabel => 'JANA';

  @override
  String get earlierLabel => 'ZAMANI';

  @override
  String get tapToView => 'Gusa kutazama';

  @override
  String get justNow => 'sasa hivi';

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

  @override
  String get iHold => 'Ninazo';

  @override
  String get rate => 'Kiwango';

  @override
  String get iNeed => 'Nahitaji';

  @override
  String get marketRate => 'Kiwango cha soko';

  @override
  String get stepIncomeRepayment => 'Mapato na marejesho';

  @override
  String get stepReviewPublish => 'Kagua na uchapishe';

  @override
  String get requestALoan => 'Omba mkopo';

  @override
  String stepCounter(int current, int total, String subtitle) {
    return 'Hatua ya $current kati ya $total · $subtitle';
  }

  @override
  String get subtitleLoanDetails => 'maelezo ya mkopo';

  @override
  String get subtitleRepaymentContext => 'muktadha wa marejesho';

  @override
  String get subtitleReview => 'uhakiki';

  @override
  String get panelTheBasics => 'Mambo ya msingi';

  @override
  String get panelTheNumbers => 'Nambari';

  @override
  String get panelLocationDetails => 'Mahali na maelezo';

  @override
  String get panelRepaymentSource => 'Chanzo cha marejesho';

  @override
  String get panelAbilityToRepay => 'Uwezo wa kulipa';

  @override
  String get panelPreferredTerms => 'Vigezo unavyopendelea';

  @override
  String get requestTitleLabel => 'Kichwa cha ombi';

  @override
  String get requestTitleHint => 'mfano: Gari la biashara ya Kampala';

  @override
  String get purposeLabel => 'Dhumuni';

  @override
  String get selectPurposeHint => 'Chagua dhumuni';

  @override
  String get describePurposeLabel => 'Eleza dhumuni lako';

  @override
  String amountLabelWithCurrency(String currency) {
    return 'Kiasi ($currency)';
  }

  @override
  String get amountHintLoan => '7,000,000';

  @override
  String get durationLabel => 'Muda';

  @override
  String get durationHintMonths => 'Miezi 6';

  @override
  String get descriptionOptionalLabel => 'Maelezo (hiari)';

  @override
  String get descriptionOptionalHint => 'Ongeza maelezo zaidi kwa wakopeshi';

  @override
  String get incomeSourceLabel => 'Chanzo cha mapato';

  @override
  String get incomeSourceHint => 'mfano: Mshahara, duka, kilimo, kazi za kando';

  @override
  String get preferredRepaymentPlanLabel => 'Mpango wa marejesho unaopendelea';

  @override
  String get selectRepaymentPlanHint => 'Chagua mpango wa marejesho';

  @override
  String repaymentAmountPerPeriodLabel(String currency) {
    return 'Kiasi cha marejesho kwa kila kipindi ($currency)';
  }

  @override
  String get repaymentAmountHint => 'mfano: 250,000';

  @override
  String get repaymentTimelineLabel => 'Ratiba na muda wa marejesho';

  @override
  String get repaymentTimelineHint =>
      'mfano: Kulipwa tarehe 5 ya kila mwezi saa 11:00 jioni kwa miezi 8';

  @override
  String get dueDayLabel => 'Siku ya malipo / marudio';

  @override
  String get dueDayHint =>
      'Chagua siku ya malipo (mfano: tarehe 5 ya kila mwezi)';

  @override
  String get dueCutoffTimeLabel =>
      'Muda wa mwisho wa malipo (kwa ada ya kuchelewa)';

  @override
  String get dueCutoffTimeHint => 'Chagua muda wa mwisho (mfano: 11:00 jioni)';

  @override
  String get timelineHelperText =>
      'Tarehe na muda kamili unaotumika kukokotoa ada za kuchelewa';

  @override
  String get suggestedInterestRateLabel =>
      'Kiwango cha riba kinachopendekezwa (%)';

  @override
  String get suggestedLateFeeLabel => 'Ada ya kuchelewa inayopendekezwa (%)';

  @override
  String get suggestedRepaymentScheduleLabel => 'Ratiba inayopendekezwa';

  @override
  String suggestedInstallmentAmountLabel(String currency) {
    return 'Kiasi cha awamu kinachopendekezwa ($currency)';
  }

  @override
  String get validationTitleRequired => 'Weka kichwa';

  @override
  String get validationTitleMinLength => 'Tumia angalau herufi 4';

  @override
  String get validationPurposeRequired => 'Chagua dhumuni';

  @override
  String get validationPurposeContinue => 'Chagua dhumuni ili kuendelea.';

  @override
  String get validationAmountRequired => 'Weka kiasi';

  @override
  String get validationValidNumber => 'Weka nambari sahihi';

  @override
  String validationMinAmount(String currency, String min) {
    return 'Kiwango cha chini $currency $min';
  }

  @override
  String validationMaxAmount(String currency, String max) {
    return 'Kiwango cha juu $currency $max';
  }

  @override
  String get validationDurationRequired => 'Weka muda';

  @override
  String get validationDurationRange => 'Miezi 1 hadi 60';

  @override
  String get validationIncomeSourceRequired =>
      'Weka chanzo chako cha marejesho';

  @override
  String get validationIncomeSourceDetail => 'Ongeza maelezo zaidi';

  @override
  String get validationRepaymentPlanRequired => 'Chagua mpango wa marejesho';

  @override
  String get validationRepaymentPlanContinue =>
      'Chagua mpango wa marejesho ili kuendelea.';

  @override
  String get validationRepaymentAmountRequired => 'Weka kiasi cha marejesho';

  @override
  String get validationRepaymentAmountValid => 'Weka kiasi sahihi';

  @override
  String get validationRepaymentTimelineRequired => 'Weka ratiba ya marejesho';

  @override
  String get validationRepaymentTimelineDetail =>
      'Weka ratiba inayoeleweka zaidi';

  @override
  String get validationPercentRange => 'Tumia 0 hadi 100';

  @override
  String get btnContinue => 'Endelea';

  @override
  String get btnPublishToMarketplace => 'Chapishe kwenye soko';

  @override
  String get btnBack => 'Nyuma';

  @override
  String get reviewYourRequest => 'Kagua ombi lako';

  @override
  String get reviewConfirmDetails =>
      'Thibitisha maelezo kabla ya kuchapisha sokoni.';

  @override
  String get reviewTitle => 'Kichwa';

  @override
  String get reviewAmount => 'Kiasi';

  @override
  String get reviewDuration => 'Muda';

  @override
  String get reviewPurpose => 'Dhumuni';

  @override
  String get reviewIncomeSource => 'Chanzo cha mapato';

  @override
  String get reviewPreferredRepaymentPlan => 'Mpango wa marejesho unaopendelea';

  @override
  String get reviewRepaymentAmount => 'Kiasi cha marejesho';

  @override
  String get reviewRepaymentTimeline => 'Ratiba ya marejesho';

  @override
  String get reviewDescription => 'Maelezo';

  @override
  String get reviewLockedTerms => 'Vigezo vilivyofungwa';

  @override
  String get reviewPerPeriod => 'kwa kila kipindi';

  @override
  String get reviewContactPrivacyNotice =>
      'Maelezo yako ya mawasiliano yanasalia kufichwa hadi ofa ikubaliwe.';

  @override
  String get requestSubmittedTitle => 'Ombi limewasilishwa';

  @override
  String get requestSubmittedContent =>
      'Ombi lako la mkopo sasa liko sokoni. Wakopeshi wanaweza kulikagua na kutoa ofa.';

  @override
  String get couldNotPublishRequest =>
      'Haikuweza kuchapisha ombi hili. Jaribu tena.';

  @override
  String get kycGateListing =>
      'Kamilisha uhakiki wa KYC kabla ya kuchapisha ombi.';

  @override
  String get notAllowedListing => 'Akaunti yako hairuhusiwi kuchapisha ombi.';

  @override
  String infoBannerText(String currency, String min, String max) {
    return '$currency $min-$max · Hadi miezi 60 · vigezo vinafungwa ukichapisha';
  }

  @override
  String get termsLockedNotice => 'Vimfungwa wakati ombi linapochapishwa.';

  @override
  String get upgradeToProForTerms =>
      'Boresha hadi Pro ili kupendekeza riba, ada ya kuchelewa, na ratiba.';

  @override
  String get purposeAgri => 'Vifaa vya kilimo';

  @override
  String get purposeBusiness => 'Kupanua biashara';

  @override
  String get purposeEdu => 'Elimu / Karo za shule';

  @override
  String get purposeMedical => 'Matibabu ya dharura';

  @override
  String get purposeFarming => 'Kilimo / Nyumba ya kijani';

  @override
  String get purposeHome => 'Uboreshaji wa nyumba';

  @override
  String get purposeStock => 'Bidhaa za duka';

  @override
  String get purposeLand => 'Kununua ardhi';

  @override
  String get purposeLivestock => 'Mifugo';

  @override
  String get purposeEnergy => 'Umeme wa jua / Nishati';

  @override
  String get purposeVehicle => 'Usafiri / Gari';

  @override
  String get purposeWater => 'Maji na usafi';

  @override
  String get purposeWedding => 'Harusi / Sherehe';

  @override
  String get purposeOther => 'Nyingine';

  @override
  String get planMonthly => 'Kila mwezi';

  @override
  String get planWeekly => 'Kila wiki';

  @override
  String get planOneTime => 'Malipo ya mara moja';

  @override
  String get createForexRequestTitle => 'Tengeneza Ombi la Forex';

  @override
  String get forexCurrencyHeld => 'Sarafu uliyo nayo';

  @override
  String get forexCurrencyNeeded => 'Sarafu unayohitaji';

  @override
  String get forexAmountToExchange => 'Kiasi cha kubadilisha';

  @override
  String get forexAmountHint => 'mfano: 100';

  @override
  String get forexPreferredRate => 'Kiwango cha kubadilisha unachopendelea';

  @override
  String get forexRateHint => 'mfano: 3700';

  @override
  String get forexSettlementPreference => 'Urasimu wa malipo';

  @override
  String get selectSettlementHint => 'Chagua njia ya malipo';

  @override
  String get forexPublishBtn => 'Chapishe ombi la forex';

  @override
  String get kycGateForex =>
      'Kamilisha uhakiki wa KYC kabla ya kuchapisha ombi la forex.';

  @override
  String get couldNotPublishForex => 'Haikuweza kuchapisha ombi hili la forex.';

  @override
  String get forexSettlementInPerson => 'Ana kwa ana';

  @override
  String get forexSettlementMobileMoney => 'Pesa za simu';

  @override
  String get forexSettlementBankTransfer => 'Benki';

  @override
  String get forexSettlementOther => 'Nyingine';

  @override
  String get forexRequestTitle => 'Ombi la forex';

  @override
  String get myForexRequestsTitle => 'Maombi yangu ya forex';

  @override
  String get noForexRequestsYet => 'Hujawa na maombi ya forex.';

  @override
  String get listingDetailTitle => 'Maelezo ya ombi';

  @override
  String get offersLabel => 'ORODHA ZA BEI';

  @override
  String get loanRequestTitle => 'Ombi la mkopo';

  @override
  String get makeAnOffer => 'Toa bei';

  @override
  String get makeAnOfferToUnlock => 'Toa bei ili ufikie maelezo kamili';

  @override
  String get onlyYourOfferVisible =>
      'Bei yako pekee inaonekana hapa. Orodha kamili ya bei inaonekana kwa mkopaji.';

  @override
  String get securedCollateralLabel => 'Imewekewa dhamana';

  @override
  String get noCollateralLabel => 'Hakuna dhamana';

  @override
  String get collateralLabel => 'Dhamana';

  @override
  String get estimatedValueLabel => 'Thamani iliyokadiriwa';

  @override
  String get locationLabel => 'Mahali';

  @override
  String get offerSubmittedReviewNotice =>
      'Bei imetumwa. Unaweza kuikagua hapo juu.';

  @override
  String offerCountdownLabel(String time) {
    return '$time zimesalia';
  }

  @override
  String get expiredLabel => 'Imeisha';

  @override
  String get offerSentSuccessfully => 'Bei imetumwa kikamilifu.';

  @override
  String get interestRateLabel => 'Riba (%)';

  @override
  String get latePaymentFeeLabel => 'Ada ya kuchelewa (%)';

  @override
  String get repaymentScheduleLabel => 'Ratiba ya marejesho';

  @override
  String get monthly => 'Kila mwezi';

  @override
  String get weekly => 'Kila wiki';

  @override
  String get oneTimePayment => 'Malipo ya mara moja';

  @override
  String installmentAmountLabel(String currency) {
    return 'Kiasi cha awamu ($currency)';
  }

  @override
  String get additionalExpectationsLabel => 'Matarajio ya ziada';

  @override
  String get optionalBorrowerNotesHint => 'Maelezo ya hiari kwa mkopaji';

  @override
  String get sendOffer => 'Tuma bei';

  @override
  String get couldNotSendOffer => 'Haikuweza kutuma bei.';

  @override
  String get rateOfferedLabel => 'Bei inayotolewa';

  @override
  String get amountAvailableLabel => 'Kiasi kinachopatikana';

  @override
  String get forexAmountToServe => 'Kiasi cha kuhudumiwa';

  @override
  String get forexServesLabel => 'Inahudumia';

  @override
  String get amountToExchangeOut => 'Kiasi cha kutoa';

  @override
  String get settlementTermsLabel => 'Masharti ya makubaliano';

  @override
  String get activeListingLabel => 'Ombi linaloendelea';

  @override
  String get fundedLabel => 'Imefadhiliwa';

  @override
  String userVerificationStatus(String status) {
    return 'Hali ya uthibitisho wa mtumiaji: $status';
  }

  @override
  String interestPercent(String value) {
    return '$value% riba';
  }

  @override
  String get proposedRepaymentPlanLabel => 'Mpango wa malipo uliopendekezwa';

  @override
  String get yourOfferLabel => 'Bei yako';

  @override
  String lenderNumberLabel(int number) {
    return 'Mkopeshi #$number';
  }

  @override
  String lenderTextLabel(String id) {
    return 'Mkopeshi #$id';
  }

  @override
  String get fullOfferLabel => 'Bei kamili';

  @override
  String partialOfferLabel(int coverage) {
    return 'Sehemu · $coverage%';
  }

  @override
  String vsAskLabel(String value) {
    return '$value dhidi ya ombi';
  }

  @override
  String get lenderNotesLabel => 'Maelezo ya mkopeshaji';

  @override
  String get acceptOfferLabel => 'Kubali bei';

  @override
  String get fullCoverageOfferLabel => 'Bei ya kufadhili yote';

  @override
  String partialCoverageLabel(int coverage) {
    return 'Ufadhili wa sehemu · $coverage%';
  }

  @override
  String totalPayablePaymentsLabel(int periods) {
    return 'Jumla ya kulipa ($periods malipo)';
  }

  @override
  String borrowingCostLabel(String amount) {
    return 'Gharama ya mkopo: $amount';
  }

  @override
  String get flutterwaveCheckoutTitle => 'Malipo ya Flutterwave';

  @override
  String get orderSummary => 'Muhtasari wa Agizo';

  @override
  String get paymentMethod => 'Njia ya Malipo';

  @override
  String get mobileMoney => 'Pesa za Simu (Mobile Money)';

  @override
  String get creditOrDebitCard => 'Kadi ya Benki';

  @override
  String get phoneOrAccount => 'Nambari ya Simu / Akaunti';

  @override
  String get enterMobileNumber => 'Weka nambari ya simu ya Mobile Money';

  @override
  String get payWithFlutterwave => 'Lipa na Flutterwave';

  @override
  String get processingPayment => 'Inashughulikia Malipo ya Flutterwave…';

  @override
  String get paymentSuccessful => 'Malipo Yamefanikiwa!';

  @override
  String subscriptionActivated(Object plan) {
    return 'Usajili wako wa $plan sasa ni amilifu.';
  }

  @override
  String get paymentFailed => 'Malipo yameshindikana. Tafadhali jaribu tena.';

  @override
  String get paymentStep1 => 'Maelezo';

  @override
  String get paymentStep2 => 'Inashughulikia';

  @override
  String get paymentStep3 => 'Imekamilika';

  @override
  String get paymentProcessingStep1 => 'Kuunganisha na Flutterwave…';

  @override
  String get paymentProcessingStep2 => 'Kuthibitisha malipo…';

  @override
  String get paymentProcessingStep3 => 'Kuamilisha usajili…';

  @override
  String transactionRef(String ref) {
    return 'Kumb: $ref';
  }

  @override
  String get poweredByFlutterwave => 'Inaendeshwa na Flutterwave';

  @override
  String enterMobileNumberForProvider(String provider) {
    return 'Nambari ya simu ya $provider';
  }

  @override
  String mobileMoneyPromptHint(String provider) {
    return 'Utapokea arifa ya $provider kwenye simu yako ili kuthibitisha malipo.';
  }

  @override
  String get prefilledFromAccount => 'Imejazwa kutoka kwa akaunti yako';

  @override
  String get editPhoneNumber => 'Hariri';

  @override
  String get lockPhoneNumber => 'Funga';

  @override
  String get liveCalcTitle => 'Muhtasari wa malipo';

  @override
  String get liveCalcLoanAmount => 'Kiasi cha mkopo';

  @override
  String get liveCalcPlan => 'Mpango wa malipo';

  @override
  String get liveCalcDuration => 'Muda';

  @override
  String get liveCalcInstallment => 'Malipo kwa kila kipindi';

  @override
  String get liveCalcTotalPayments => 'Jumla ya malipo';

  @override
  String get liveCalcTotalPayback => 'Jumla ya kulipa';

  @override
  String get liveCalcBorrowingCost => 'Gharama ya kukopa';

  @override
  String get liveCalcNoData =>
      'Jaza sehemu zilizo juu ili uone muhtasari wa malipo yako.';

  @override
  String get freeTermsBanner =>
      'Acha wazi — wakopeshaji watapendekezwa masharti yao. Boresha hadi Pro ili upendekeze viwango.';

  @override
  String get offerReadOnlyNotice =>
      'Angalia masharti yanayopendekezwa na mkopeshaji hapa chini. Kubali au subiri ofa bora.';

  @override
  String get sponsoredLabel => 'Imesponsorwa';

  @override
  String get borrowerTermsMissing => '—';

  @override
  String get repaymentCalcFormula =>
      'malipo × idadi ya malipo = jumla ya kulipa';

  @override
  String liveCalcWeeklyNote(int months, int count) {
    return 'Mpango wa wiki: miezi $months × 4 = malipo $count';
  }

  @override
  String liveCalcMonthlyNote(int count) {
    return 'Malipo $count ya kila mwezi';
  }

  @override
  String get liveCalcOneTimeNote => 'Malipo 1 ya mara moja';

  @override
  String get kycGateTitle => 'Thibitisha kitambulisho chako kwanza';

  @override
  String get kycGateBody =>
      'Ili kuchapisha maombi ya mkopo au sarafu na kuungana na wakopeshaji, unahitaji kukamilisha uhakiki wa kitambulisho. Inachukua dakika chache tu.';

  @override
  String get kycGatePendingTitle => 'Uhakiki unakaguliwa';

  @override
  String get kycGatePendingBody =>
      'Stakabadhi zako za kitambulisho zinakaguliwa. Utaarifiwa mara tu akaunti yako itakapoidhinishwa.';

  @override
  String get kycGateRejectedTitle => 'Uhakiki umekataliwa';

  @override
  String get kycGateRejectedBody =>
      'Stakabadhi zako za KYC hazikuidhinishwa. Tafadhali tuma tena na stakabadhi halali.';

  @override
  String get kycGateExpiredTitle => 'Uhakiki umepita muda';

  @override
  String get kycGateExpiredBody =>
      'Uhakiki wako wa KYC umepita muda. Tafadhali tuma tena ili kuendelea kuchapisha maombi.';

  @override
  String get kycStep1 => 'Tuma kitambulisho cha taifa au pasipoti';

  @override
  String get kycStep2 => 'Subiri ukaguzi (kawaida ndani ya masaa 24)';

  @override
  String get kycStep3 => 'Chapisha maombi mara tu unapoidhinishwa';

  @override
  String get kycGateCta => 'Anza uhakiki';

  @override
  String get kycGateResubmitCta => 'Tuma tena uhakiki';

  @override
  String get kycPageTitle => 'Uthibitisho wa kitambulisho';

  @override
  String get kycStatusApproved => 'KYC Imeidhinishwa';

  @override
  String get kycStatusApprovedDesc =>
      'Kitambulisho kimethibitishwa. Sasa unaweza kuunda matangazo.';

  @override
  String get kycStatusPending => 'Inakaguliwa';

  @override
  String get kycStatusPendingDesc =>
      'Stakabadhi zimewasilishwa. Ukaguzi wa msimamizi unaendelea.';

  @override
  String get kycStatusRejected => 'Imekataliwa';

  @override
  String get kycStatusRejectedDesc =>
      'Ombi limekataliwa. Tafadhali pakia tena na uwasilishe upya.';

  @override
  String get kycStatusExpired => 'Imepita muda';

  @override
  String get kycStatusExpiredDesc =>
      'KYC yako imepita muda. Tafadhali thibitisha upya.';

  @override
  String get kycStatusNotSubmitted => 'Haijwasilishwa';

  @override
  String get kycStatusNotSubmittedDesc =>
      'Wasilisha hati zako ili kufungua uwezo wa kuunda matangazo.';

  @override
  String get kycRejectionReason => 'Sababu ya kukataliwa';

  @override
  String get kycIdentityVerified => 'Kitambulisho kimethibitishwa';

  @override
  String kycExpires(String date) {
    return 'Inaisha tarehe $date';
  }

  @override
  String get kycPendingNotice =>
      'Stakabadhi zimewasilishwa — ukaguzi wa msimamizi unaendelea. Hii kawaida huchukua siku 1–2 za kazi.';

  @override
  String get kycRequiredDocs => 'Hati zinazohitajika';

  @override
  String get kycRequiredDocsSubtitle =>
      'Pakia picha wazi na zenye mwanga mzuri. Hati zote zimehifadhiwa kwa usalama.';

  @override
  String get kycDocNationalIdFront => 'Kitambulisho cha taifa — mbele';

  @override
  String get kycDocNationalIdFrontSubtitle =>
      'Picha wazi ya upande wa mbele wa kitambulisho chako cha taifa cha Uganda';

  @override
  String get kycDocNationalIdBack => 'Kitambulisho cha taifa — nyuma';

  @override
  String get kycDocNationalIdBackSubtitle =>
      'Picha wazi ya upande wa nyuma wa kitambulisho chako cha taifa';

  @override
  String get kycDocSelfie => 'Selfie na kitambulisho';

  @override
  String get kycDocSelfieSubtitle =>
      'Shikilia kitambulisho chako cha taifa karibu na uso wako';

  @override
  String get kycDocUploadedTapReplace => 'Imepakiwa — gusa ili kubadilisha';
  String get kycDocUploadedUnderReview => 'Imepakiwa — inakaguliwa';

  @override
  String get kycPrivacyNote =>
      'Utambulisho wako hauonyeshwi kwa washiriki wengine wa soko. Hati zinakaguliwa na wasimamizi wa Nipanze peke yao.';

  @override
  String get kycSubmitForReview => 'Wasilisha kwa ukaguzi';

  @override
  String get kycUploadAllDocs => 'Pakia hati tatu zote kuwezesha uwasilishaji.';

  @override
  String get kycChooseSource => 'Chagua chanzo';

  @override
  String get kycSourceCamera => 'Kamera';

  @override
  String get kycSourceLibrary => 'Maktaba ya picha';

  @override
  String get kycDismiss => 'Ondoa';
}
