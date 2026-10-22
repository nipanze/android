// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kinyarwanda (`rw`).
class AppLocalizationsRw extends AppLocalizations {
  AppLocalizationsRw([String locale = 'rw']) : super(locale);

  @override
  String get appTitle => 'Nipanze';

  @override
  String get welcomeTitle => 'Guriza. Guriza. Gura.';

  @override
  String get welcomeTagline => 'Reba ibyanditswe hafi yawe';

  @override
  String get welcomeSubtitle =>
      'Isoko ryawe ryizewe rifite abatanga serivisi b\'ukuri.';

  @override
  String get selectLanguage => 'Hitamo Ururimi';

  @override
  String get choosePreferredLanguage => 'Hitamo ururimi wifuza';

  @override
  String get continueWithPhone => 'Komeza ukoresheje Telefoni';

  @override
  String get continueWithEmail => 'Komeza ukoresheje Imeyili';

  @override
  String get getStartedTitle => 'Tangira na Nipanze';

  @override
  String get getStartedSubtitle => 'Hitamo uko wifuza gukomeza';

  @override
  String get createAccount => 'Fungura Konti';

  @override
  String get createAccountSubtitle =>
      'Ushya kuri Nipanze? Iyandikishe ukoresheje telefoni';

  @override
  String get logIn => 'Injira';

  @override
  String get logInSubtitle => 'Usanganywe konti? Injira';

  @override
  String get welcomeBack => 'Murakaza neza 👋';

  @override
  String get loginToAccount => 'Injira muri konti yawe';

  @override
  String get phone => 'Telefoni';

  @override
  String get email => 'Imeyili';

  @override
  String get phoneNumber => 'Numero ya Telefoni';

  @override
  String get password => 'Ijambo ry\'ibanga';

  @override
  String get confirmPassword => 'Emeza ijambo ry\'ibanga';

  @override
  String get createPassword => 'Krema ijambo ry\'ibanga';

  @override
  String get rememberMe => 'Unyibuke';

  @override
  String get forgotPassword => 'Wibagiwe ijambo ry\'ibanga?';

  @override
  String get dontHaveAccount => 'Nta konti ufite?';

  @override
  String get signUp => 'Iyandikishe';

  @override
  String get enterPhoneTitle => 'Andika numero yawe ya telefoni';

  @override
  String get enterPhoneSubtitle => 'Tuzakoherereza kode yo kwemeza';

  @override
  String get sendCode => 'Oherereza Kode yo Kwemeza';

  @override
  String get tellUsAboutYou => 'Tubwire ibyawe';

  @override
  String get completeProfileSubtitle =>
      'Wuzuze umwirondoro wawe unemeze ijambo ry\'ibanga';

  @override
  String get fullName => 'Izina ryose';

  @override
  String get finish => 'Rangiza';

  @override
  String get termsNotice =>
      'Muri gukomeza, wemeye amabwiriza yacu n\'amatsinda y\'amabwiriza y\'ibanga.';

  @override
  String get phoneSafeTitle => 'Numero yawe irinzwe neza';

  @override
  String get phoneSafeSubtitle =>
      'Ntitwigeze tusangiza numero yawe n\'umuntu uwo ari we wese.';

  @override
  String get navMarkets => 'Amasoko';

  @override
  String get navWatchlist => 'Ibyo ukurikira';

  @override
  String get navRequest => 'Saba';

  @override
  String get navPositions => 'Ibikorwa';

  @override
  String get navAccount => 'Konti';

  @override
  String get marketplaceTitle => 'Nipanze';

  @override
  String listingsLive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count amatangazo akora',
      one: '$count itangazo rikora',
    );
    return '$_temp0';
  }

  @override
  String get filtered => 'Shunguwe';

  @override
  String get applyingFilters => 'Gushungura…';

  @override
  String get noListingsFound => 'Nta nguzanyo ziriho';

  @override
  String get noListingsSubtitle =>
      'Ongera ugerageze n\'amatsiko — inguzanyo nshya ziza mu gihe nyacyo.';

  @override
  String get noMatches => 'Nta bihuye';

  @override
  String get noMatchesSubtitle =>
      'Nta nguzanyo zihuye n\'ibyo washunguye.\nGerageza guhindura cyangwa gukuraho ibipimo.';

  @override
  String get adjustFilters => 'Hindura ibipimo';

  @override
  String get removeFromWatchlist => 'Kura mu byo ukurikira';

  @override
  String get saveToWatchlist => 'Bika mu byo ukurikira';

  @override
  String get months => 'amezi';

  @override
  String daysLeft(int count) {
    return '$count iminsi isigaye';
  }

  @override
  String hoursLeft(int count) {
    return '$count amasaha asigaye';
  }

  @override
  String minutesLeft(int count) {
    return '$count iminota isigaye';
  }

  @override
  String get expired => 'Byarangiye';

  @override
  String get listingExpiryTitle => 'Igihe itangazo rirangirira';

  @override
  String get listingExpiryTooltip => 'Erekana igihe gisigaye';

  @override
  String listingRemainingDaysHours(int days, int hours) {
    return 'Iminsi $days, amasaha $hours isigaye';
  }

  @override
  String listingRemainingHoursMinutes(int hours, int minutes) {
    return 'Amasaha $hours, iminota $minutes isigaye';
  }

  @override
  String listingRemainingMinutes(int minutes) {
    return 'Iminota $minutes isigaye';
  }

  @override
  String listingRemainingSeconds(int seconds) {
    return 'Amasegonda $seconds asigaye';
  }

  @override
  String get openToOffers => 'Urahawe kwakira ibiciro';

  @override
  String get marketplaceForYou => 'Ibyawe';

  @override
  String get marketplaceAll => 'Byose';

  @override
  String get marketplaceLoan => 'Inguzanyo';

  @override
  String get marketplaceLoans => 'Inguzanyo';

  @override
  String get marketplaceForex => 'Forex';

  @override
  String get marketplaceNeeds => 'Ibikenewe';

  @override
  String get marketplaceNeeded => 'Bikenewe';

  @override
  String get declareCapabilityToBidTitle => 'Service Capability Required';

  @override
  String get declareCapabilityToBidMessage =>
      'To submit an offer on this request, you must first declare that you offer services in this category.';

  @override
  String get declareServiceNow => 'Add Service & Continue';

  @override
  String get postServiceAction => 'Tanga serivisi';

  @override
  String get postServiceSubtitle =>
      'Shyira ku rutonde serivisi utanga, uhuze n\'abakiriya bazishaka';

  @override
  String get viewDetails => 'Reba ibisobanuro';

  @override
  String get proAdvancedFilters => 'Amayunguruzo ya Pro yisumbuye';

  @override
  String get today => 'Uyu munsi';

  @override
  String get weekAgo => 'Icyumweru 1 gishize';

  @override
  String daysAgo(int count) {
    return 'Iminsi $count ishize';
  }

  @override
  String weeksAgo(int count) {
    return 'Ibyumweru $count bishize';
  }

  @override
  String get watchlistTitle => 'Urutonde rw\'Ikurikirana';

  @override
  String get watchlistSubtitle => 'Inguzanyo ukurikira';

  @override
  String watchlistSaved(int count) {
    return '$count zachunwe';
  }

  @override
  String get watchlistInfoSubscribed =>
      'Kubuntu ku batumiaji bose. Menya iyo habaye impinduka ku nguzanyo, inyungu zigabanuka, cyangwa inguzanyo iri gufunga.';

  @override
  String get watchlistInfoFree =>
      'Kubuntu ku batumiaji bose. Menya iyo habaye impinduka. Iyandikishe kugira ngo utange ibirego.';

  @override
  String get watchlistError => 'Ikosa mu gufungura urutonde rw\'ikurikirana';

  @override
  String get watchlistEmpty => 'Nta nguzanyo zachunwe';

  @override
  String get watchlistEmptySubtitle =>
      'Shakisha isoko hanyuma kanda \"Bika mu byo ukurikira\" ku nguzanyo iyo ari yo yose.';

  @override
  String get browseMarketplace => 'Reba isoko';

  @override
  String get removedFromWatchlist => 'Yakuwe mu byo ukurikira';

  @override
  String get undo => 'Subiraho';

  @override
  String get tryAgain => 'Ongera ugerageze';

  @override
  String get myActivityTitle => 'Ibikorwa Byanjye';

  @override
  String get myActivitySubtitle => 'Genzura inguzanyo n\'ibirego byawe';

  @override
  String myActivityStats(int listings, int offers) {
    return '$listings Inguzanyo · $offers Ibirego Bikomeje';
  }

  @override
  String get tabMyRequests => 'Izimusaba Zanjye';

  @override
  String get tabMyOffers => 'Ibirego Byanjye';

  @override
  String get tabDeals => 'Amasezerano';

  @override
  String get noDealsYet => 'Nta masezerano arahari';

  @override
  String get noDealsSubtitle =>
      'Igihe ikirego cyakiriwe nawe cyangwa uwo mukorana, amasezerano yanyu azagaragara hano.';

  @override
  String get noOffersYet => 'Nta birego birahari';

  @override
  String get noOffersSubtitle =>
      'Ibirego utanga ku nguzanyo z\'isoko bizagaragara hano.';

  @override
  String get browseMarketplaceBtn => 'Shakisha';

  @override
  String get activeOffers => 'Ibirego Bikomeje';

  @override
  String get matchedAccepted => 'Byahuye / Byakiriwe';

  @override
  String get history => 'Amateka';

  @override
  String get withdrawOffer => 'Kuraho Irego?';

  @override
  String withdrawConfirm(int amount) {
    return 'Urizera kuraho irigo ryawe rya UGX $amount?';
  }

  @override
  String get keepOffer => 'Bika Irego';

  @override
  String get withdraw => 'Kuraho';

  @override
  String get myRequestsTitle => 'Izimusaba Zanjye';

  @override
  String sectionActive(int count) {
    return 'Zikomeje · $count';
  }

  @override
  String sectionContracted(int count) {
    return 'Zisigiriwe · $count';
  }

  @override
  String sectionClosed(int count) {
    return 'Zafunzwe · $count';
  }

  @override
  String get noRequests => 'Nta busabe burahari';

  @override
  String get noRequestsSubtitle =>
      'Tanga ubusabe wakire ibyifuzo by\'Abatanga Serivisi bashobora kugufasha.';

  @override
  String get createRequest => 'Tanga ubusabe';

  @override
  String get cancelListing => 'Kuraho inguzanyo?';

  @override
  String cancelListingConfirm(String title) {
    return 'Iki kizakuraho \"$title\" ku isoko. Ibirego byose bicomeje bizavanwa.';
  }

  @override
  String get keepIt => 'Bika';

  @override
  String get cancelListingBtn => 'Kuraho inguzanyo';

  @override
  String get contractNotGenerated => 'Amasezerano ntiyateguwe.';

  @override
  String get viewOffers => 'Reba ibiciro';

  @override
  String get viewContract => 'Reba amasezerano';

  @override
  String get viewListing => 'Reba ubusabe';

  @override
  String get offeredAmountLabel => 'Amafaranga yatanzwe';

  @override
  String get statusLabel => 'Imiterere';

  @override
  String get interestLabel => 'Inyungu';

  @override
  String get lateFeeLabel => 'Amafaranga yo gukererwa';

  @override
  String lateFeePerMissedInstallment(String value) {
    return '$value kuri buri gice cyakererewe';
  }

  @override
  String get repaymentLabel => 'Kwishyura';

  @override
  String get totalPayableLabel => 'Igiteranyo cyo kwishyura';

  @override
  String sentDateLabel(String date) {
    return 'Byoherejwe $date';
  }

  @override
  String errorLoadingContract(String error) {
    return 'Ikosa mu gufungura amasezerano: $error';
  }

  @override
  String listingOfferCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ibiciro',
      one: 'igiciro',
    );
    return '$count $_temp0';
  }

  @override
  String get accountTitle => 'Konti';

  @override
  String get settingsTitle => 'Igenamiterere';

  @override
  String get contactUs => 'Twandikire';

  @override
  String get community => 'Umuryango';

  @override
  String get legal => 'Amategeko';

  @override
  String get signOut => 'Sohoka';

  @override
  String get signOutConfirm => 'Urizera gusohoka muri konti yawe?';

  @override
  String get cancel => 'Kurekera';

  @override
  String get profileUpdated => 'Umwirondoro wasuzumwe.';

  @override
  String get profileSaved => 'Umwirondoro wabitswe.';

  @override
  String get editProfile => 'Hindura Umwirondoro';

  @override
  String get changeProfilePicture => 'Hindura ifoto y\'umwirondoro';

  @override
  String get phoneNumberLabel => 'Numero ya Telefone';

  @override
  String selectRegionLabel(String label) {
    return 'Hitamo $label';
  }

  @override
  String get incomeTypeLabel => 'Ubwoko bw\'inyungu';

  @override
  String get selectIncomeType => 'Hitamo ubwoko bw\'inyungu';

  @override
  String get employerBusinessOptionalLabel =>
      'Umukoresha / izina ry\'ubucuruzi (si ngombwa)';

  @override
  String monthlyIncomeWithCurrency(String currency) {
    return 'Amafaranga winjiza buri kwezi ($currency)';
  }

  @override
  String get bankProfessionalTagLabel => 'Banki & ikirango cy\'umwuga';

  @override
  String get preferredDepositBankLabel =>
      'Banki ukunda cyangwa ubitsamo (si ngombwa)';

  @override
  String get preferredDepositBankHint =>
      'urug. Equity Bank, Bank of Kigali, Stanbic, KCB';

  @override
  String get accountRepresentsLabel => 'Konti ihagarariye';

  @override
  String get individualPersonalAccountLabel =>
      'Umuntu ku giti cye / konti bwite';

  @override
  String get bankLabel => 'Banki';

  @override
  String get forexExchangeCompanyLabel => 'Ikigo kivunjisha amafaranga';

  @override
  String get saccoLabel => 'SACCO';

  @override
  String get companyLabel => 'Ikigo';

  @override
  String get bankLoanAgentLabel => 'Ndi umukozi wa banki ushinzwe inguzanyo';

  @override
  String get bankLoanAgentSubtitle =>
      'Yerekana ikirango cy\'umukozi wa banki ku bakoresha Pro bashaka inguzanyo za banki.';

  @override
  String get showProfessionalTagLabel => 'Erekana ikirango cyanjye cy\'umwuga';

  @override
  String get showProfessionalTagSubtitle =>
      'Zimya kugira ngo uhishe ibirango bya banki, forex, SACCO, cyangwa umukozi ku byifuzo.';

  @override
  String get saveChanges => 'Bika impinduka';

  @override
  String get enterFullName => 'Shyiramo amazina yawe yose';

  @override
  String avatarUploadFailed(String error) {
    return 'Kohereza ifoto byanze: $error';
  }

  @override
  String couldNotSelectImage(String error) {
    return 'Ntibyashobotse guhitamo ifoto: $error';
  }

  @override
  String get choosePhoto => 'Hitamo ifoto';

  @override
  String get selectPhotoSource => 'Hitamo aho ukura ifoto yawe y\'umwirondoro';

  @override
  String get takePhoto => 'Fata ifoto';

  @override
  String get useCamera => 'Koresha ikamera yawe';

  @override
  String get chooseFromGallery => 'Hitamo mu bubiko bw\'amafoto';

  @override
  String get pickExistingPhoto => 'Hitamo ifoto isanzwe ihari';

  @override
  String get removePhoto => 'Kura mu gihagararo ifoto';

  @override
  String get removePhotoSubtitle => 'Siba ifoto y\'umwirondoro uriho sasa';

  @override
  String get identityVerification => 'Kwemeza Indangamuntu';

  @override
  String get security => 'Umutekano';

  @override
  String get notifications => 'Amatangazo';

  @override
  String get markAllRead => 'Shyira byose nk\'ibyasomwe';

  @override
  String get noNotificationsYet => 'Nta matangazo arahari';

  @override
  String get noNotificationsSubtitle =>
      'Uzabona amatangazo hano igihe ibiciro bigeze, ibipimo bihindutse, cyangwa amasezerano aboneka.';

  @override
  String get todayLabel => 'UYU MUNSI';

  @override
  String get yesterdayLabel => 'EJO HASHIZE';

  @override
  String get earlierLabel => 'MBERE';

  @override
  String get tapToView => 'Kanda urebe';

  @override
  String get justNow => 'ubu';

  @override
  String get statListings => 'Inguzanyo';

  @override
  String get statListingsSubtitle => 'Izimusaba zatangiwe';

  @override
  String get statOffers => 'Ibirego';

  @override
  String get statOffersSubtitle => 'Ibirego byatanzwe';

  @override
  String get statMatches => 'Guhuza';

  @override
  String get statMatchesSubtitle => 'Guhuza byagenze neza';

  @override
  String get trustReputation => 'Icyizere & Isura';

  @override
  String get subscription => 'Kwiyandikisha';

  @override
  String get upgradeToPro => 'Komeza kuri Pro';

  @override
  String get viewPlansUpgrade => 'Reba gahunda & komeza';

  @override
  String get adminDashboard => 'Imbaho y\'Umuyobozi';

  @override
  String memberSince(String date) {
    return 'Umunyamuryango kuva $date';
  }

  @override
  String get verified => 'Byemejwe';

  @override
  String get districtNotSet => 'Akarere ntikagorwa';

  @override
  String get nipanzeDisclaimer =>
      'Nipanze ni urubuga rwo guhuza abantu. Ntitubika, ntitwimura, cyangwa ntitukemura amafaranga. Ibikorwa byose biba hagati y\'abakoresha ku giti cyabo.';

  @override
  String get lenderRequired => 'Ukeneye konti y\'Umuguriza';

  @override
  String get lenderRequiredSubtitle =>
      'Gutanga ibyifuzo ni igice cy\'ipulani y\'Umuguriza (iboneka no mu Pro). Kuzamura konti ngo ufungure gutanga ibyifuzo.';

  @override
  String get lenderTier => 'Kirenga cy\'Umuguriza';

  @override
  String get lenderTierDesc =>
      'Kugirango umuntu wese witeguye gutanga ibyifuzo biteguye neza no kunguka kuri Nipanze.';

  @override
  String get everythingInFree => 'Ibyose biri muri Kubuntu';

  @override
  String get lenderFeature1 =>
      'Tanga ibyifuzo birimo amategeko yose (ingano, amafaranga, igihe)';

  @override
  String get lenderFeature2 => 'Reba amakuru arambuye y\'ibyifuzo wajemo';

  @override
  String get chooseLender => 'Hitamo Umuguriza';

  @override
  String get notNow => 'Oya ntabwo ari ubu';

  @override
  String get paymentSecurityDisclaimer =>
      'Nipanze ntiyabika cyangwa ngo yimura amafaranga. Guhindura abunzi bwemezwa binyuze mu nzira yizewe yo kwishyura.';

  @override
  String get proRequired => 'Ukeneye konti ya Pro';

  @override
  String get proRequiredSubtitle =>
      'Ibyiza byisumbuye nko gutanga amasezerano yihariye n\'uyunguruzo byisumbuye biri kuri Pro gusa.';

  @override
  String get proTier => 'Kirenga cya Pro';

  @override
  String get proTierDesc =>
      'Kugera ku isoko ryose, uyunguruzo bwa kumenya neza n\'umwanya wa mbere.';

  @override
  String get everythingInLender => 'Ibyose biri mu Muguriza';

  @override
  String get proFeature1 =>
      'Tanga ingano y\'inyungu, igihano cyo gutinda n\'amatariki yo kwishyura';

  @override
  String get proFeature2 => 'Uyunguruzo rwihariye (inguano, akazi, kwemezwa)';

  @override
  String get proFeature3 =>
      'Ikirango cyemejwe, amanota y\'ikizere n\'ukuboneka ku mwanya wa mbere';

  @override
  String get choosePro => 'Hitamo Pro';

  @override
  String get plansAndPricing => 'Ipulani n\'Ibiciro';

  @override
  String get chooseAccessTitle => 'Hitamo ubushobozi ukeneye';

  @override
  String chooseAccessSubtitle(String flag, String country) {
    return 'Konti imwe ishobora gusaba no gutanga ibyifuzo. Ibiciro bihura n\'akarere ka konti yawe ($flag $country).';
  }

  @override
  String get perMonth => 'ukwezi';

  @override
  String get freePlanSubtitle =>
      'Shakisha, kurikirana, tangaza ubusabe bw\'ibanze, no kwemera ibyifuzo.';

  @override
  String get freeFeature1 => 'Shakisha ku isoko';

  @override
  String get freeFeature2 => 'Tanga ubusabe bw\'ibanze bwo kuguzwa';

  @override
  String get freeFeature3 => 'Emera ibyifuzo wakiriye';

  @override
  String get currentPlan => 'Ipulani iriho';

  @override
  String get useFree => 'Koresha Kubuntu';

  @override
  String choosePlan(String plan) {
    return 'Hitamo $plan';
  }

  @override
  String planSelectedMessage(String plan) {
    return '$plan yatoranyijwe. Kwishyura kwizewe bizaboneka vuba.';
  }

  @override
  String get unlockDealTitle => 'Fungura ubwumvikane';

  @override
  String get unlockDealAndContact => 'Fungura ubwumvikane n\'amakuru y\'ibanze';

  @override
  String get dealAgreementLocked => 'Amasezerano yafunzwe';

  @override
  String get dealAgreementLockedSubtitle =>
      'Umusabi n\'umuguriza bombi bemeje amasezerano. Ubu ushobora gufungura amakuru bagezaho ngo mvugane imbona nkubone.';

  @override
  String includedInPlan(String plan) {
    return 'Biri mu ipulani yawe ya $plan';
  }

  @override
  String get unlimitedUnlocksSubtitle =>
      'Gufungura amakuru yo kuvugana bitagira umupaka bila kudasaba icyiru.';

  @override
  String welcomeGiftUnlocks(int count) {
    return '🎁 Impano y\'ikaze — haracyari fursa $count zo gufungura kubuntu';
  }

  @override
  String get welcomeGiftSubtitle =>
      'Iki gikorwa gikoresha imwe mu fursa zawe zo gufungura kubuntu. Izindi fursa zishyurwa UGX 5,000.';

  @override
  String get unlockFeeApplies => 'Igiciro cyo gufungura ni UGX 5,000';

  @override
  String get unlockFeeAppliesSubtitle =>
      'Fursa yawe yo gufungura kubuntu yakoreshejwe. Kuzamura kuri Umuguriza cyangwa Pro ubonereho gufungura bitagira umupaka.';

  @override
  String get whatHappensNext => 'Ikurikira n\'iki';

  @override
  String get step1Title => 'Amakuru yo kuvugana yaragaragajwe';

  @override
  String get step1Desc =>
      'Izina ry\'amategeko, terefone, n\'e-mail by\'pande zombi bizasangizwa.';

  @override
  String get step2Title => 'Guhuza imbona nkubone';

  @override
  String get step2Desc =>
      'Ubu ushobora kuvugana n\'uwo mukorana hanze y\'urubuga rwa Nipanze.';

  @override
  String get step3Title => 'Soza igikorwa';

  @override
  String get step3Desc =>
      'Soza amasezerano y\'inguframe n\'ihererekanya ry\'amafaranga imbona nkubone.';

  @override
  String get disclaimerNonCustodial =>
      'Nipanze ntiyabika cyangwa ngo yimura amafaranga ayo ari yo yose. Wowe n\'uwo mukorana ni mwe bonyine mubazwa ibikorwa byose by\'amafaranga n\'ikemurampaka.';

  @override
  String get payToUnlock => 'Ishyura UGX 5,000 Ufungure';

  @override
  String get unlockWithFreeCredit => 'Fungura ukoresheje fursa y\'ubuntu';

  @override
  String get unlockContactDetails => 'Fungura amakuru yo kuvugana';

  @override
  String get upgradeForUnlimited =>
      'Zamura ubonereho gufungura bitagira umupaka';

  @override
  String get contactDetailsRevealed => 'Amakuru yo kuvugana yaragaragajwe';

  @override
  String get connectionSuccessful =>
      'Guhuza kwayendeye neza. Aya ni amakuru yo kuvugana:';

  @override
  String get borrower => 'Umusabi';

  @override
  String get lender => 'Umuguriza';

  @override
  String get directContactNotice =>
      'Ubu ushobora kuvugana n\'uwo mukorana imbona nkubone ngo usoze igikorwa hanze ya Nipanze.';

  @override
  String get done => 'Byarangiye';

  @override
  String planTitle(String plan) {
    return 'Ipulani ya $plan';
  }

  @override
  String get nonCustodialAccess => 'Ubushobozi bw\'ubunzi butabika amafaranga';

  @override
  String get howTrustWorks => 'Uko ikizere gukora';

  @override
  String get trustExplanation =>
      'Ibyerekana ikizere bigaragaza gusa ibikorwa byakozwe binyuze kuri Nipanze. Ntitubara ibikorwa byo kwishyura hanze y\'urubuga.';

  @override
  String get trustScore => 'Amanota y\'ikizere';

  @override
  String get completeDealsToBuild => 'Soza amasezerano ngo wubake amanota yawe';

  @override
  String get noReviewsYet => 'Nta bitekerezo biratangwa';

  @override
  String successfulDeals(int count) {
    return 'Amasezerano $count yagezweho neza';
  }

  @override
  String get repeatParticipant => 'Umukoresha unyaruka';

  @override
  String get notRepeatYet => 'Ntiraba umukoresha unyaruka';

  @override
  String get phoneVerified => 'Terefone yaremejwe';

  @override
  String get phoneNotVerified => 'Terefone ntiyaremejwe';

  @override
  String get publicTrustSignals =>
      'Ibyerekana ikizere by\'abantu bishingiye gusa ku bikorwa byakozwe binyuze kuri Nipanze.';

  @override
  String get advancedFilters => 'Uyunguruzo bwisumbuye';

  @override
  String get advancedFiltersBadge => 'Pro · Shungura ibiri kuri isoko';

  @override
  String get filterReset => 'Subira imbere';

  @override
  String get filterClear => 'Siba';

  @override
  String get filterApply => 'Shyira uyunguruzo';

  @override
  String get filterDone => 'Byarangiye';

  @override
  String get filterEmploymentType => 'Ubwoko bw\'akazi';

  @override
  String get filterEmploymentSubtitle =>
      'Shungura hakurikijwe akazi ka muguzi kwatangajwe';

  @override
  String get filterIncomeRange => 'Urwego rw\'inyungu za buri kwezi';

  @override
  String get filterIncomeSubtitle =>
      'Ibikorwa bya hafi — inyungu nyayo ntizigaragazwa na rimwe';

  @override
  String get filterQualitySignals => 'Ibimenyetso by\'ubwiza bw\'urutonde';

  @override
  String get filterHasSuggestedTerms => 'Bifite amategeko atekerezwa';

  @override
  String get filterHasSuggestedTermsSubtitle =>
      'Irutonde ry\'Pro gusa rifite igipimo cy\'inyungu gitunganye, igihano cy\'gutinda, n\'igihe cyo kwishyura';

  @override
  String get filterVerifiedBorrower => 'Umusabi wemejwe';

  @override
  String get filterVerifiedBorrowerSubtitle =>
      'Izimusaba gusa zivuye ku bafite konti zemejwe na KYC';

  @override
  String get filterPrivacyNote =>
      'Amazina y\'abakora ndetse n\'inyungu nyayo ntibigaragazwa na rimwe. Imikorere y\'inyungu n\'amoko y\'akazi ni ibyerekana by\'ingenzi gusa, by\'ingenzi.';

  @override
  String get empGovEmployee => 'Umukozi wa leta';

  @override
  String get empEmployedPrivate => 'Umukozi (abikorera)';

  @override
  String get empSelfEmployed => 'Akora afite ubwe';

  @override
  String get empSmallBusinessOwner => 'Nyir\'ubucuruzi buto';

  @override
  String get empBusinessOwner => 'Nyir\'ubucuruzi';

  @override
  String get empStudent => 'Umunyeshuri';

  @override
  String get empOther => 'Ikindi';

  @override
  String get incomeUnder2m => 'Munsi ya 2M UGX / ukwezi';

  @override
  String get income2m5m => '2M – 5M UGX / ukwezi';

  @override
  String get income5m10m => '5M – 10M UGX / ukwezi';

  @override
  String get incomeOver10m => 'Hejuru ya 10M UGX / ukwezi';

  @override
  String get iHold => 'Mfite';

  @override
  String get rate => 'Igipimo';

  @override
  String get iNeed => 'Nkeneye';

  @override
  String get marketRate => 'Igipimo cy\'isoko';

  @override
  String get stepIncomeRepayment => 'Inyungu no kwishyura';

  @override
  String get stepReviewPublish => 'Kusuzuma no gutangaza';

  @override
  String get requestALoan => 'Saba inguzanyo';

  @override
  String stepCounter(int current, int total, String subtitle) {
    return 'Intambwe ya $current kuri $total · $subtitle';
  }

  @override
  String get subtitleLoanDetails => 'iBIKUBIYE MU NGUZANYO';

  @override
  String get subtitleRepaymentContext => 'uburyo bwo kwishyura';

  @override
  String get subtitleReview => 'isuzuma';

  @override
  String get panelTheBasics => 'Iby\'iremezo';

  @override
  String get panelTheNumbers => 'Imibare';

  @override
  String get panelLocationDetails => 'Ahantu n\'ibindi';

  @override
  String get panelRepaymentSource => 'Inkomoko y\'ubwishyu';

  @override
  String get panelAbilityToRepay => 'Ubushobozi bwo kwishyura';

  @override
  String get panelPreferredTerms => 'Amasezerano wifuza';

  @override
  String get requestTitleLabel => 'Umutwe w\'usabe';

  @override
  String get requestTitleHint => 'urugero: Imodoka y\'ubucuruzi ya Kampala';

  @override
  String get purposeLabel => 'Impamvu';

  @override
  String get selectPurposeHint => 'Hitamo impamvu';

  @override
  String get describePurposeLabel => 'Sobanura impamvu';

  @override
  String amountLabelWithCurrency(String currency) {
    return 'Umubare ($currency)';
  }

  @override
  String get amountHintLoan => '7,000,000';

  @override
  String get durationLabel => 'Igihe';

  @override
  String get durationHintMonths => 'Amezi 6';

  @override
  String get descriptionOptionalLabel => 'Ibusobanuro (amahitamo)';

  @override
  String get descriptionOptionalHint =>
      'Ongeraho ibindi abakuguriza bakwiriye kumenya';

  @override
  String get incomeSourceLabel => 'Inkomoko y\'inzu';

  @override
  String get incomeSourceHint => 'urugero: Umushahara, iduka, ubuhinzi';

  @override
  String get preferredRepaymentPlanLabel => 'Uburyo bwo kwishyura wifuza';

  @override
  String get selectRepaymentPlanHint => 'Hitamo uburyo bwo kwishyura';

  @override
  String repaymentAmountPerPeriodLabel(String currency) {
    return 'Ayishyurwa mu gihe ($currency)';
  }

  @override
  String get repaymentAmountHint => 'urugero: 250,000';

  @override
  String get repaymentTimelineLabel => 'Igihe n\'isaha yo kwishyura';

  @override
  String get repaymentTimelineHint =>
      'urugero: Kwishyurwa ku itariki 5 za buri kwezi mbele ya saa kumi n\'imwe z\'umugoroba mu miezi 8';

  @override
  String get dueDayLabel => 'Umunsi wo kwishyura';

  @override
  String get dueDayHint =>
      'Hitamo umunsi wo kwishyura (urugero: itariki 5 za buri kwezi)';

  @override
  String get dueCutoffTimeLabel => 'Isaha ntarengwa (y\'amande y\'ubukererwe)';

  @override
  String get dueCutoffTimeHint => 'Hitamo isaha ntarengwa (urugero: 17:00)';

  @override
  String get timelineHelperText =>
      'Itariki n\'isaha nyawo bikoreshwa mu kubara amande y\'ubukererwe';

  @override
  String get suggestedInterestRateLabel => 'Inyungu isabwa (%)';

  @override
  String get suggestedLateFeeLabel => 'Amande y\'ubukererwe (%)';

  @override
  String get suggestedRepaymentScheduleLabel => 'Igihe cyo kwishyura gisasabwa';

  @override
  String suggestedInstallmentAmountLabel(String currency) {
    return 'Kwisbyura mu byiciro ($currency)';
  }

  @override
  String get validationTitleRequired => 'Andika umutwe';

  @override
  String get validationTitleMinLength => 'Andika nibura inyuguti 4';

  @override
  String get validationPurposeRequired => 'Hitamo impamvu';

  @override
  String get validationPurposeContinue => 'Hitamo impamvu kugira ngo ukomeze.';

  @override
  String get validationAmountRequired => 'Andika umubare';

  @override
  String get validationValidNumber => 'Andika umubare ukwiye';

  @override
  String validationMinAmount(String currency, String min) {
    return 'Kuri make $currency $min';
  }

  @override
  String validationMaxAmount(String currency, String max) {
    return 'Kuri menshi $currency $max';
  }

  @override
  String get validationDurationRequired => 'Andika igihe';

  @override
  String get validationDurationRange => 'Amezi 1 kugeza kuri 60';

  @override
  String get validationIncomeSourceRequired => 'Andika inkomoko y\'ubwishyu';

  @override
  String get validationIncomeSourceDetail => 'Ongeraho ibindi bisobanuro';

  @override
  String get validationRepaymentPlanRequired => 'Hitamo uburyo bwo kwishyura';

  @override
  String get validationRepaymentPlanContinue =>
      'Hitamo uburyo bwo kwishyura kugira ngo ukomeze.';

  @override
  String get validationRepaymentAmountRequired => 'Andika ayo kwishyura';

  @override
  String get validationRepaymentAmountValid => 'Andika umubare ukwiye';

  @override
  String get validationRepaymentTimelineRequired =>
      'Andika igihe cyo kwishyura';

  @override
  String get validationRepaymentTimelineDetail => 'Andika igihe cyumvikana';

  @override
  String get validationPercentRange => 'Koresha 0 kugeza 100';

  @override
  String get btnContinue => 'Komeza';

  @override
  String get btnPublishToMarketplace => 'Tangaza ku isoko';

  @override
  String get btnBack => 'Subira inyuma';

  @override
  String get reviewYourRequest => 'Suzuza usabe wabyo';

  @override
  String get reviewConfirmDetails =>
      'Emeza ibikubiyemo mbere yo gutangaza ku isoko.';

  @override
  String get reviewTitle => 'Umutwe';

  @override
  String get reviewAmount => 'Umubare';

  @override
  String get reviewDuration => 'Igihe';

  @override
  String get reviewPurpose => 'Impamvu';

  @override
  String get reviewIncomeSource => 'Inkomoko y\'inzu';

  @override
  String get reviewPreferredRepaymentPlan => 'Uburyo bwo kwishyura wifuza';

  @override
  String get reviewRepaymentAmount => 'Ayishyurwa';

  @override
  String get reviewRepaymentTimeline => 'Igihe cyo kwishyura';

  @override
  String get reviewDescription => 'Ibusobanuro';

  @override
  String get reviewLockedTerms => 'Amasezerano yafunzwe';

  @override
  String get reviewPerPeriod => 'mu gihe';

  @override
  String get reviewContactPrivacyNotice =>
      'Umwirondoro wawe uguma uhishwe kugeza icyifuzo cyemewe.';

  @override
  String get requestSubmittedTitle => 'Usabe yoherejwe';

  @override
  String get requestSubmittedContent =>
      'Inguzanyo usaba iri ku isoko ubu. Abakuguriza bazozi suzuma.';

  @override
  String get couldNotPublishRequest =>
      'Ntabwo bishobotse gutangaza ubusabe. Ongera ugerageze.';

  @override
  String get kycGateListing => 'Wuzuza KYC mbere yo gutangaza.';

  @override
  String get notAllowedListing => 'Konte yawe ntiyemerewe gutangaza.';

  @override
  String infoBannerText(String currency, String min, String max) {
    return '$currency $min-$max · Kugeza ku miezi 60 · amasezerano afungwa gutangazwa';
  }

  @override
  String get termsLockedNotice => 'Bifungirwa igihe ubusabe butangajwe.';

  @override
  String get upgradeToProForTerms =>
      'Zamura ugeze kuri Pro kugira ngo utange inyungu n\'amande.';

  @override
  String get purposeAgri => 'Ibyuma by\'ubuhinzi';

  @override
  String get purposeBusiness => 'Kwagura ubucuruzi';

  @override
  String get purposeEdu => 'Uburezi / Amafaranga y\'ishuri';

  @override
  String get purposeMedical => 'Ubwishingizi bw\'ubuzima';

  @override
  String get purposeFarming => 'Ubuhinzi';

  @override
  String get purposeHome => 'Gusana inzu';

  @override
  String get purposeStock => 'Ibicuruzwa';

  @override
  String get purposeLand => 'Gugura ubutaka';

  @override
  String get purposeLivestock => 'Ubworozi';

  @override
  String get purposeEnergy => 'Imirasire y\'izuba / Ningufu';

  @override
  String get purposeVehicle => 'Ikinyabiziga';

  @override
  String get purposeWater => 'Azi n\'isuku';

  @override
  String get purposeWedding => 'Ubukwe / Ibikorwa';

  @override
  String get purposeOther => 'Ikindi';

  @override
  String get planMonthly => 'Buri kwezi';

  @override
  String get planWeekly => 'Buri cyumweru';

  @override
  String get planOneTime => 'Inshuro imwe';

  @override
  String get createForexRequestTitle => 'Kurema ubusabe bwa forex';

  @override
  String get forexCurrencyHeld => 'Icyiciro ufite';

  @override
  String get forexCurrencyNeeded => 'Icyiciro nkeneye';

  @override
  String get forexAmountToExchange => 'Ayagomba kuvunjwa';

  @override
  String get forexAmountHint => 'urugero: 100';

  @override
  String get forexPreferredRate => 'Igipimo cyo kuvunja wifuza';

  @override
  String get forexRateHint => 'urugero: 3700';

  @override
  String get forexSettlementPreference => 'Uburyo bwo kwishyura';

  @override
  String get selectSettlementHint => 'Hitamo uburyo bwo kwishyura';

  @override
  String get forexPublishBtn => 'Tangaza ubusabe bwa forex';

  @override
  String get kycGateForex => 'Wuzuza KYC mbere yo gutangaza ubusabe bwa forex.';

  @override
  String get couldNotPublishForex =>
      'Ntabwo bishobotse gutangaza ubusabe bwa forex.';

  @override
  String get forexSettlementInPerson => 'Ana kwa ana';

  @override
  String get forexSettlementMobileMoney => 'Mobile Money';

  @override
  String get forexSettlementBankTransfer => 'Banki';

  @override
  String get forexSettlementOther => 'Ikindi';

  @override
  String get forexRequestTitle => 'Ubusabe bwa forex';

  @override
  String get myForexRequestsTitle => 'Ubusabe bwanjye bwa forex';

  @override
  String get noForexRequestsYet => 'Nta ubusabe bwa forex buhari.';

  @override
  String get listingDetailTitle => 'Ibikubiye mu busabe';

  @override
  String get needDetailTitle => 'Ibisobanuro by\'ubusabe';

  @override
  String get termLabel => 'Igihe';

  @override
  String get loanTypeLabel => 'Ubwoko bw\'inguzanyo';

  @override
  String get aboutRequest => 'IBYEREKEYE UBUSABE';

  @override
  String get notSpecified => 'Ntabwo byasobanuwe';

  @override
  String get verifiedRequester => 'Usaba wemejwe';

  @override
  String get timelineLabel => 'Igihe ntarengwa';

  @override
  String get trustLabel => 'Icyizere';

  @override
  String get categoryDetailsLabel => 'IBISOBANURO BY\'ICYICIRO';

  @override
  String get aboutNeedLabel => 'IBYEREKEYE UBUSABE';

  @override
  String get forexHoldLabel => 'Mfite';

  @override
  String get forexNeedLabel => 'Nkeneye';

  @override
  String get nearbyLabel => 'Hafi';

  @override
  String get flexibleLabel => 'Byoroshye';

  @override
  String offersCount(int count) {
    return 'Ibiciro $count';
  }

  @override
  String get offersLabel => 'AMATANGA';

  @override
  String get loanRequestTitle => 'Ubusabe bw\'inguzanyo';

  @override
  String get makeAnOffer => 'Tanga igiciro';

  @override
  String get makeAnOfferToUnlock =>
      'Tanga igiciro kugirango ubone amakuru yose';

  @override
  String get onlyYourOfferVisible =>
      'Igiciro watanze ni cyo gusa kigaragara hano. Urutonde rwose rw\'ibiciro rubonwa n\'usaba inguzanyo.';

  @override
  String get securedCollateralLabel => 'Gifite ingwate';

  @override
  String get noCollateralLabel => 'Nta ngwate';

  @override
  String get hasCollateralLabel => 'Ifite ingwate';

  @override
  String get collateralLabel => 'Ingwate';

  @override
  String get collateralPromptText => 'Hitamo niba uyu mubazo ufite ingwate.';

  @override
  String get collateralDetailsLabel => 'Ibisobanuro by\'ingwate';

  @override
  String get collateralDetailsHint =>
      'urugero: urupapuro rw\'umutungo, imodoka, ibikoresho, ibikoresho by\'ubuhinzi';

  @override
  String get collateralAssetRequired => 'Sobanura ingwate';

  @override
  String get collateralAssetDetailShort => 'Ongeraho ibisobanuro bike';

  @override
  String collateralValueLabel(String currency) {
    return 'Agaciro kagereranyijwe ($currency)';
  }

  @override
  String get estimatedValueLabel => 'Agaciro kagereranyijwe';

  @override
  String get locationLabel => 'Ahantu';

  @override
  String get offerSubmittedReviewNotice =>
      'Igiciro cyoherejwe. Ushobora kukireba hejuru.';

  @override
  String offerCountdownLabel(String time) {
    return 'Hasigaye $time';
  }

  @override
  String get expiredLabel => 'Byarangiye';

  @override
  String get offerSentSuccessfully => 'Igiciro cyoherejwe neza.';

  @override
  String get interestRateLabel => 'Inyungu (%)';

  @override
  String get latePaymentFeeLabel => 'Amafaranga yo gukererwa (%)';

  @override
  String get repaymentScheduleLabel => 'Gahunda yo kwishyura';

  @override
  String get monthly => 'Buri kwezi';

  @override
  String get weekly => 'Buri cyumweru';

  @override
  String get oneTimePayment => 'Kwishyura rimwe';

  @override
  String installmentAmountLabel(String currency) {
    return 'Amafaranga ya buri gice ($currency)';
  }

  @override
  String get additionalExpectationsLabel => 'Ibindi wifuza';

  @override
  String get optionalBorrowerNotesHint =>
      'Ibisobanuro bitari itegeko ku usaba inguzanyo';

  @override
  String get sendOffer => 'Ohereza igiciro';

  @override
  String get couldNotSendOffer => 'Ntibyashobotse kohereza igiciro.';

  @override
  String get rateOfferedLabel => 'Igiciro gitangwa';

  @override
  String get amountAvailableLabel => 'Amafaranga aboneka';

  @override
  String get forexAmountToServe => 'Ayazatangwa';

  @override
  String get forexServesLabel => 'Ibikora';

  @override
  String get amountToExchangeOut => 'Ayavunjwa';

  @override
  String get settlementTermsLabel => 'Amabwiriza y\'iryozwa';

  @override
  String get activeListingLabel => 'Ubusabe buri gukora';

  @override
  String get fundedLabel => 'Byamaze guterwa inkunga';

  @override
  String userVerificationStatus(String status) {
    return 'Imiterere yo kwemeza umukoresha: $status';
  }

  @override
  String interestPercent(String value) {
    return '$value% inyungu';
  }

  @override
  String get proposedRepaymentPlanLabel => 'Gahunda yo kwishyura yatanzwe';

  @override
  String get yourOfferLabel => 'Igiciro cyawe';

  @override
  String lenderNumberLabel(int number) {
    return 'Utanga inguzanyo #$number';
  }

  @override
  String lenderTextLabel(String id) {
    return 'Utanga inguzanyo #$id';
  }

  @override
  String get fullOfferLabel => 'Igiciro cyuzuye';

  @override
  String partialOfferLabel(int coverage) {
    return 'Igice · $coverage%';
  }

  @override
  String vsAskLabel(String value) {
    return '$value ugereranyije n\'icyasabwe';
  }

  @override
  String get lenderNotesLabel => 'Ibisobanuro by\'utanga inguzanyo';

  @override
  String get acceptOfferLabel => 'Emera igiciro';

  @override
  String get fullCoverageOfferLabel => 'Igiciro gifata byose';

  @override
  String partialCoverageLabel(int coverage) {
    return 'Igice gifashwa · $coverage%';
  }

  @override
  String totalPayablePaymentsLabel(int periods) {
    return 'Amafaranga yose yo kwishyura ($periods kwishyura)';
  }

  @override
  String borrowingCostLabel(String amount) {
    return 'Ikiguzi cy\'inguzanyo: $amount';
  }

  @override
  String get flutterwaveCheckoutTitle => 'Kwishyura kuri Flutterwave';

  @override
  String get orderSummary => 'Inshamake y\'igiciro';

  @override
  String get paymentMethod => 'Uburyo bwo kwishyura';

  @override
  String get mobileMoney => 'Mobile Money';

  @override
  String get creditOrDebitCard => 'Ikarita ya banki';

  @override
  String get phoneOrAccount => 'Numero ya terefone / Konti';

  @override
  String get enterMobileNumber => 'Shyiramo numero ya Mobile Money';

  @override
  String get payWithFlutterwave => 'Ishyura ukoresheje Flutterwave';

  @override
  String get processingPayment => 'Kwishyura kuri Flutterwave birikugenda…';

  @override
  String get paymentSuccessful => 'Kwishyura byagenze neza!';

  @override
  String subscriptionActivated(Object plan) {
    return 'Ifatabuguzi ryawe rya $plan ubu riri gukora.';
  }

  @override
  String get paymentFailed => 'Kwishyura ntabwo byakunze. Ongera ugerageze.';

  @override
  String get paymentStep1 => 'Amakuru';

  @override
  String get paymentStep2 => 'Birakora';

  @override
  String get paymentStep3 => 'Byarangiye';

  @override
  String get paymentProcessingStep1 => 'Guhuza na Flutterwave…';

  @override
  String get paymentProcessingStep2 => 'Kwemeza kwishyura…';

  @override
  String get paymentProcessingStep3 => 'Gufungura ifatabuguzi…';

  @override
  String transactionRef(String ref) {
    return 'Inomero: $ref';
  }

  @override
  String get poweredByFlutterwave => 'Ishyirwa mu bikorwa na Flutterwave';

  @override
  String enterMobileNumberForProvider(String provider) {
    return 'Numero ya terefone ya $provider';
  }

  @override
  String mobileMoneyPromptHint(String provider) {
    return 'Urakira ubutumwa bwa $provider kuri terefone yawe wemeze kwishyura.';
  }

  @override
  String get prefilledFromAccount => 'Yatanzwe na konti yawe';

  @override
  String get editPhoneNumber => 'Hindura';

  @override
  String get lockPhoneNumber => 'Funga';

  @override
  String get liveCalcTitle => 'Imyanzuro y\'ibisubizo';

  @override
  String get liveCalcLoanAmount => 'Ingano y\'inguzanyo';

  @override
  String get liveCalcPlan => 'Gahunda yo gusubiza';

  @override
  String get liveCalcDuration => 'Igihe';

  @override
  String get liveCalcInstallment => 'Igishoro cya buri gihe';

  @override
  String get liveCalcTotalPayments => 'Umubare wose w\'ibisubizo';

  @override
  String get liveCalcTotalPayback => 'Igiteranyo cy\'ibisubizo';

  @override
  String get liveCalcBorrowingCost => 'Igiciro cy\'inguzanyo';

  @override
  String get totalAmountPayableLabel => 'Total amount payable';

  @override
  String get totalInterestLabel => 'Total interest';

  @override
  String get liveCalcNoData =>
      'Uzuza ibice hejuru kugira ngo ubone imyanzuro y\'ibisubizo byawe.';

  @override
  String get freeTermsBanner =>
      'Siga ubusa — abatangira inguzanyo bazatanga amategeko yabo. Muze ku Pro gutanga ibyifuzo.';

  @override
  String get offerReadOnlyNotice =>
      'Reba amategeko asabwa n\'umuguzi hepfo. Emera cyangwa tegereza ikirushijeho.';

  @override
  String get sponsoredLabel => 'Yongewe';

  @override
  String get borrowerTermsMissing => '—';

  @override
  String get repaymentCalcFormula =>
      'igishoro × umubare w\'ibisubizo = igiteranyo';

  @override
  String liveCalcWeeklyNote(int months, int count) {
    return 'Gahunda ya buri cyumweru: amezi $months × 4 = $count bisubizo';
  }

  @override
  String liveCalcMonthlyNote(int count) {
    return 'Bisubizo $count bya buri kwezi';
  }

  @override
  String get liveCalcOneTimeNote => 'Isubizwa 1 rimwe';

  @override
  String get kycGateTitle => 'Banza wemeze umwirondoro wawe';

  @override
  String get kycGateBody =>
      'Kugira ngo usabe inguzanyo cyangwa ivunjisha kandi uhuzwe n\'abategereje kugukopa, ugomba kubanza kwemeza umwirondoro. Bitwara iminota mike gusa.';

  @override
  String get kycGatePendingTitle => 'Kwikora kwasuzumwe';

  @override
  String get kycGatePendingBody =>
      'Inyandiko zawe z\'umwirondoro ziri gusuzumwa. Uramenyeshwa mugihe konti yawe yemewe.';

  @override
  String get kycGateRejectedTitle => 'Kwemeza kwateshejwe agaciro';

  @override
  String get kycGateRejectedBody =>
      'Ibyangombwa byawe ntibyemewe. Nyamuneka yongera utange inyandiko zikora.';

  @override
  String get kycGateExpiredTitle => 'Kwemeza kwarangiye';

  @override
  String get kycGateExpiredBody =>
      'Kwemeza umwirondoro wawe kwarangiye. Nyamuneka yongera wemeze utange ubusabe.';

  @override
  String get kycStep1 => 'Tanga indangamuntu cyangwa pasiporo';

  @override
  String get kycStep2 => 'Tegereza isuzuma (bizwi munsi y\'amasaha 24)';

  @override
  String get kycStep3 => 'Saba inguzanyo mugihe wamaze kwemerwa';

  @override
  String get kycGateCta => 'Tanga umwirondoro';

  @override
  String get kycGateResubmitCta => 'Yongera utange umwirondoro';

  @override
  String get kycPageTitle => 'Kwemeza indangamuntu';

  @override
  String get kycStatusApproved => 'KYC Yemejwe';

  @override
  String get kycStatusApprovedDesc =>
      'Umwirondoro wemejwe. Ubu urashobora gushyira amakuru ku isoko.';

  @override
  String get kycStatusPending => 'Irasuzumwa';

  @override
  String get kycStatusPendingDesc =>
      'Inyandiko zatanzwe. Isuzuma ry\'umunyamabanga riragenda.';

  @override
  String get kycStatusRejected => 'Yateshejwe agaciro';

  @override
  String get kycStatusRejectedDesc =>
      'Ubusabe bwateshejwe agaciro. Nyamuneka ongera utange maze wongereshe.';

  @override
  String get kycStatusExpired => 'Yarangiye';

  @override
  String get kycStatusExpiredDesc =>
      'KYC yawe yarangiye. Nyamuneka ongera kwemeza.';

  @override
  String get providerVerificationRequiredTitle =>
      'Kwemeza utanga serivisi birakenewe';

  @override
  String get providerVerificationRequiredDesc =>
      'Emeza ko utanga serivisi mbere yo kuzikorera muri iki cyiciro.';

  @override
  String get identityVerificationRequiredTitle =>
      'Kwemeza umwirondoro birakenewe';

  @override
  String get identityVerificationRequiredDesc =>
      'Emeza umwirondoro wawe mbere yo gutangaza cyangwa gutanga serivisi kuri Nipanze.';

  @override
  String get startProviderVerificationBtn => 'Tangira kwemeza utanga serivisi';

  @override
  String get verifyIdentityBtn => 'Emeza umwirondoro';

  @override
  String get maybeLaterBtn => 'Wenda nyuma';

  @override
  String get kycStatusNotSubmitted => 'Ntibyatanzwe';

  @override
  String get kycStatusNotSubmittedDesc =>
      'Tanga inyandiko zawe kugira ngo ubone uburenganzira bwo gushyira amakuru.';

  @override
  String get kycRejectionReason => 'Impamvu yo guteshwa agaciro';

  @override
  String get kycIdentityVerified => 'Umwirondoro wemejwe';

  @override
  String kycExpires(String date) {
    return 'Irarangira kuwa $date';
  }

  @override
  String get kycPendingNotice =>
      'Inyandiko zatanzwe — isuzuma ry\'umunyamabanga riragenda. Ibi bisanzwe bitwara iminsi 1–2 y\'akazi.';

  @override
  String get kycRequiredDocs => 'Inyandiko zisabwa';

  @override
  String get kycRequiredDocsSubtitle =>
      'Shiraho amafoto akera neza n\'umucyo mwiza. Inyandiko zose zibikwa mu buryo bw\'umutekano.';

  @override
  String get kycDocNationalIdFront => 'Indangamuntu — imbere';

  @override
  String get kycDocNationalIdFrontSubtitle =>
      'Ifoto ikera y\'imbere y\'indangamuntu yawe y\'u Rwanda';

  @override
  String get kycDocNationalIdBack => 'Indangamuntu — inyuma';

  @override
  String get kycDocNationalIdBackSubtitle =>
      'Ifoto ikera y\'inyuma y\'indangamuntu yawe';

  @override
  String get kycDocSelfie => 'Selfie n\'indangamuntu';

  @override
  String get kycDocSelfieSubtitle =>
      'Shyira indangamuntu yawe iruhande rw\'mu maso wawe';

  @override
  String get kycDocUploadedTapReplace => 'Yakoherejwe — kanda ubasangire';

  @override
  String get kycDocUploadedUnderReview => 'Yakoherejwe — irimo gusuzumwa';

  @override
  String get kycPrivacyNote =>
      'Umwirondoro wawe ntugaragarira abandi bagize isoko. Inyandiko zisuzumwa n\'ubutegetsi bwa Nipanze gusa.';

  @override
  String get kycSubmitForReview => 'Tanga isuzuma';

  @override
  String get kycUploadAllDocs =>
      'Kohereza ifoto y\'umwirondoro n\'inyandiko zose zigenewe kugira ngo ushoboze gutanga.';

  @override
  String get kycChooseSource => 'Hitamo isoko';

  @override
  String get kycSourceCamera => 'Kamera';

  @override
  String get kycSourceLibrary => 'Ububiko bw\'amafoto';

  @override
  String get kycDismiss => 'Reka';

  @override
  String get referAndEarn => 'Tumira kandi ubone ibihembo';

  @override
  String get yourReferralCode => 'Kode yawe y\'itumanaho';

  @override
  String get enterCode => 'Injira kode';

  @override
  String get shareLink => 'Sangiza link';

  @override
  String get copyCode => 'Kopiyaho kode';

  @override
  String get enterReferralCode => 'Injira kode y\'itumanaho';

  @override
  String get referralCodeSubtitle =>
      'Niba inshuti yakwitumye kuri Nipanze, injiza kode yayo aha munsi.';

  @override
  String get referralCodeHint => 'urugero: JOHN1234';

  @override
  String get referralCodeLabel => 'Kode y\'itumanaho';

  @override
  String get applyCode => 'Ongera kode';

  @override
  String get totalReferrals => 'Umubare w\'itumanaho';

  @override
  String get registered => 'Biyandikishije';

  @override
  String get qualified => 'Bakuye ibisabwa';

  @override
  String get pendingRewards => 'Ibihembo birimo gutegereza';

  @override
  String get availableRewards => 'Ibihembo bihari';

  @override
  String get totalEarned => 'Igiteranyo cyabitswe';

  @override
  String get totalPaid => 'Igiteranyo cyishyuwe';

  @override
  String get referralHistory => 'Amateka y\'itumanaho';

  @override
  String get noReferralsYet => 'Nta bitumanaho bihari';

  @override
  String get noReferralsSubtitle =>
      'Ibitumanaho wasangiza bizagaragara aha nyuma yo kwiyandikisha.';

  @override
  String get referralCodeCopied => 'Kode y\'itumanaho yakopijwe';

  @override
  String get referralCodeApplied => 'Kode y\'itumanaho yakoreshejwe neza!';

  @override
  String get privacyAndVisibility => 'Ubusuguzi n\'Ukugaragara';

  @override
  String get blockedUsers => 'Abakoresha bafunzwe';

  @override
  String get blockUser => 'Funga umukoresha';

  @override
  String get blockUserConfirmTitle => 'Funga uyu mukoresha?';

  @override
  String get blockUserConfirmBody =>
      'Ntazashobora kubona cyangwa gukorana n\'ibisabwa byawe by\'inguzanyo cyangwa amavunja y\'ahazaza.';

  @override
  String get block => 'Funga';

  @override
  String get unblock => 'Fungura';

  @override
  String get unblockUserConfirmTitle => 'Fungura uyu mukoresha?';

  @override
  String get unblockUserConfirmBody =>
      'Amabwiriza asanzwe yo kugaragara ku isoko azongera gukora.';

  @override
  String get userBlocked => 'Umukoresha yafunzwe.';

  @override
  String get userUnblocked => 'Umukoresha yafunguwe.';

  @override
  String get noBlockedUsers => 'Nta bakoresha bafunzwe';

  @override
  String get noBlockedUsersSubtitle => 'Abantu ufunze bazagaragara hano.';

  @override
  String blockedOnDate(String date) {
    return 'Yafunzwe $date';
  }

  @override
  String get invitePeopleAndTrackRewards =>
      'Tumira abantu kandi urekere ibihembo';

  @override
  String get codeGenerating => 'Kode yawe irimo gukorwa…';

  @override
  String get inviteEarnDescription =>
      'Tumira abantu kuri Nipanze ubone ibihembo mu gihe bafashe ibikorwa byasabwaga.';

  @override
  String get stepShare => 'Sangiza';

  @override
  String get stepSignUp => 'Iyandikishe';

  @override
  String get stepVerify => 'Emeza';

  @override
  String get stepQualify => 'Kora ibisabwa';

  @override
  String get stepEarn => 'Bona';

  @override
  String get registeredReferrals => 'Abatumiriwe bariyandikishije';

  @override
  String get verifiedReferrals => 'Abatumiriwe bemejwe';

  @override
  String get qualifiedReferrals => 'Abatumiriwe bakuze ibisabwa';

  @override
  String get notYetAvailable => 'Ntiraboneka';

  @override
  String get readyToClaim => 'Byiteguye gufatwa';

  @override
  String get lifetimeRewards => 'Ibihembo byose';

  @override
  String get alreadyPaid => 'Bishywe';

  @override
  String get qualifiedTooltip =>
      'Uwatumiwe yakuje ibisabwa ni umuntu watumiye wakoresheje ibikorwa byasabwaga ku cyihembo.';

  @override
  String get subscriptionCurrency => 'Ifaranga ryo kwiyandikisha';

  @override
  String subscriptionCurrencyDesc(
      String currency, String country, String dialCode) {
    return 'Ifaranga ryawe ryo kwiyandikisha riri kuri $currency ($country) dukurikije igihugu cy\'inimero yawe ($dialCode).';
  }

  @override
  String get subscriptionCurrencyLocked =>
      'Ifaranga ryo kwiyandikisha rifunze ku karere k\'inimero yawe kubera ibyemezo byo kwishyura.';

  @override
  String get understood => 'Nsumbya';

  @override
  String get principalLossWarningTitle => 'Iburira ryo igihombo cy\'imari';

  @override
  String get belowTargetReturnTitle =>
      'Iburira ry\'inyungu iri munsi y\'intego';

  @override
  String get sendAnyway => 'Ohereza icyifuzo uko biri';

  @override
  String get safetyToolkit => 'Igikoresho cy\'umutekano';

  @override
  String get safetyTips => 'Inama z\'umutekano';

  @override
  String get reportListingOrUser =>
      'Raporo y\'itangazamakuru cyangwa umukoresha';

  @override
  String get supportAndHelp => 'Ubufasha n\'ubwunganizi';

  @override
  String get appLock => 'Gufunga porogaramu';

  @override
  String get appLockDescription =>
      'Saba biometrics cyangwa PIN y\'igikoresho nyuma yo gutangira cyangwa mu masegonda 30 ku mugongo.';

  @override
  String get unlockNipanze => 'Fungura Nipanze';

  @override
  String get referralChecking => 'Igenzura ry\'kode y\'itumanaho...';

  @override
  String get referralAccepted => 'Kode y\'itumanaho yemerewe.';

  @override
  String get profilePicture => 'Ifoto y\'umwirondoro';

  @override
  String get profilePictureKycNote =>
      'Irasabwa ku rwego rwo kwemeza umwirondoro. Shyiraho ifoto igaragara yawe.';

  @override
  String get affordabilityWarningTitle =>
      'Kwishyura bishobora kuba biri hasi cyane';

  @override
  String affordabilityWarningBody(
      String currency, String total, String shortfall) {
    return 'Kwishyura kwawe kwose kwa $currency $total kuri hasi ho $currency $shortfall ku bwinshi usaba. Abaguriza bakeneye inyungu — tekereza ku kuzamura umubare w\'icyiciro cyawe.';
  }

  @override
  String get affordabilityDialogTitle => 'Tangaza n\'ubundi?';

  @override
  String get affordabilityDialogBody =>
      'Ibyifuzo byawe byo kwishyura biraboneka ko biri hasi kuruta ibyo abaguriza benshi bakwemera. Ushobora gutangaza, ariko nushobora kubona ibyifuzo. Tekereza kuzamura umubare w\'icyiciro.';

  @override
  String paymentScheduleTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ibyiciro',
      one: 'icyiciro',
    );
    return 'GUKURIKIZA KWISHYURA ($count $_temp0)';
  }

  @override
  String plusMoreCount(int count) {
    return '+$count bindi';
  }

  @override
  String get quickTermGuideLabel => 'ISANGANO RYA VUBA RYA IBYIFUZO';

  @override
  String get termGuideLow => '💡 Inyungu Hasi';

  @override
  String get termGuideFair => '🤝 Ibyifuzo Bikwiye';

  @override
  String get termGuideNegotiable => '📊 Biraganirwaho';

  @override
  String get offerMeansForYou => 'Iki cyifuzo gisobanura iki kuri wowe';

  @override
  String get totalRepayableLabel => 'Ayose yo kwishyura';

  @override
  String get effectiveInterestLabel => 'Inyungu nyakuri';

  @override
  String get loanAmountLabel => 'Umubare w\'inguframe';

  @override
  String get highEffectiveRateWarning =>
      'Iki cyifuzo gifite inyungu nyakuri iri hejuru. Tekereza kuganira cyangwa gutegereza icyifuzo cyo hasi.';

  @override
  String get allowInstitutionMatchingLabel => 'Emera guhuza n\'ibigo by\'imari';

  @override
  String get allowInstitutionMatchingSubtitle =>
      'Emerera abakozi bemejwe ba banki cyangwa ikigo cyawe kubona icyifuzo cyawe cy\'inguframe ku byifuzo bihuye.';

  @override
  String get filterInstitutionMatches => 'Guhuza n\'ibigo';

  @override
  String get filterInstitutionMatchesSubtitle =>
      'Ibyifuzo by\'inguframe gusa bivuye kubaguzwa bakemeye guhuzwa n\'ikigo cyawe.';

  @override
  String get filterInstitutionMatchesIneligible =>
      'Shyiraho ikigo cyawe muri Profil → Banki & Umwuga kugira ngo ureke iki kiciro.';

  @override
  String get filterSmartMatchingSection => 'Guhuza kwegekwa';

  @override
  String get institutionTypeBank => 'Banki';

  @override
  String get institutionTypeSacco => 'SACCO';

  @override
  String get institutionTypeMfi => 'Ikigo cy\'imari iciriritse (MFI)';

  @override
  String get institutionTypeCreditCompany => 'Kampani y\'inguzanyo';

  @override
  String get institutionTypeForex => 'Ikigo cy\'ivunjisha (Forex)';

  @override
  String get institutionTypeCompany => 'Kampani';

  @override
  String get contactDetailsTitle => 'Amakuru yo Guhamagara';

  @override
  String get dealAgreementCreated => 'Amasezerano y\'Ubwikorezi Yakozwe';

  @override
  String get dealAgreementCreatedSubtitle =>
      'Ushobora guhita uvugana n\'undi munyabyarwa kugira ngo mukomeze ubwikorezi bwayo.';

  @override
  String get contactTheOtherParty => 'Vugana n\'Undi Munyabyarwa';

  @override
  String get detailsOnlyVisibleToYou => 'Aya makuru aboneshwa nawe wenyine.';

  @override
  String get contactInfoLocked => 'Amakuru yo Guhamagara Arafunzwe';

  @override
  String get contactInfoLockedSubtitle =>
      'Fungura amakuru yo guhamagara y\'undi munyabyarwa kugira ngo umuhamagare, umwandikire imeli, cyangwa kuri WhatsApp.';

  @override
  String get oneTimeUnlockFee => 'Ikiguzi cyo gufungura inshuro imwe';

  @override
  String get revealsContactInfoNotice =>
      'Yerekana amakuru yo guhamagara kuri ubu bwikorezi bwonyine.';

  @override
  String get oppositePartyContact => 'Amakuru y\'Undi Munyabyarwa';

  @override
  String successfulDealsCount(int count) {
    return '$count Guhuza';
  }

  @override
  String reviewsCount(int count) {
    return 'Ibitekerezo $count';
  }

  @override
  String get emailAddressLabel => 'Aderesi ya Imeli';

  @override
  String get whatsappLabel => 'WhatsApp';

  @override
  String get callAction => 'Hamagara';

  @override
  String get emailAction => 'Imeli';

  @override
  String get chatAction => 'Ganira';

  @override
  String get safetyFirstTitle => 'Umutekano Mbere';

  @override
  String get safetyFirstDesc =>
      'Vugana mu buryo bw\'inshingano. Nipanze ntabwo ibika amafaranga kandi ntabwo yivanga cyangwa ngo irengere igikorwa cyose.';

  @override
  String get goToMyDeals => 'Jya mu Bwikorezi Bwange';

  @override
  String get backToActivity => 'Subira mu Bikorwa';

  @override
  String get previewDeal => 'Reba Ubwikorezi';

  @override
  String get reachOutToLenderDirectly => 'Vugana n\'umuguriza imbona nkubone';

  @override
  String get reachOutToBorrowerDirectly => 'Vugana n\'umusabi imbona nkubone';

  @override
  String get nipanzeDisclaimerCardText =>
      'Nipanze ntiyabika amafaranga cyangwa ngo ikemure amasezerano.\nBanza wemeze amakuru mbere yo kohereza icyo ari cyo cyose.';

  @override
  String get phoneCopiedToClipboard => 'Numero ya telefone yakopiwe';

  @override
  String get emailCopiedToClipboard => 'Aderesi ya imeli yakopiwe';

  @override
  String get whatsappCopiedToClipboard => 'Numero ya WhatsApp yakopiwe';

  @override
  String get notProvided => 'Ntabwo byatanzwe';

  @override
  String get viewOppositePartyContact => 'Reba Amakuru y\'Undi Munyabyarwa';

  @override
  String get tapToViewContactDetails =>
      'Kanda urebere amakuru yo guhamagara y\'undi munyabyarwa.\nAmasezerano ya nyuma ari hagati y\'umuguzi n\'umuguzanya pe.';

  @override
  String get needsRequestTitle => 'Ubusabe bw\'ibikenewe';

  @override
  String get createNeedsRequestTitle => 'Tanga ubusabe bw\'Ibikenewe';

  @override
  String get needsTitleLabel => 'Umutwe w\'icyo ukeneye';

  @override
  String get needsTitleHint => 'urug. ibikoresho bya sola ku iduka ryanjye';

  @override
  String get needsCategoryLabel => 'Icyiciro';

  @override
  String get needsSpecificationLabel => 'Ibisobanuro';

  @override
  String get needsSpecificationHint =>
      'Sobanura icyo ukeneye, ingano, ubwiza, n\'ibiteganyijwe mu kugemura.';

  @override
  String get needsSpecificationRequired => 'Sobanura icyo ukeneye';

  @override
  String get needsSpecificationMinLength => 'Koresha nibura inyuguti 12';

  @override
  String needsBudgetLabel(String currency) {
    return 'Ingengo ($currency)';
  }

  @override
  String get needsBudgetHint => 'urug. 500000';

  @override
  String get needsBudgetHelper =>
      'Shyiramo 0 niba ushaka ko abatanga serivisi baguha ibiciro.';

  @override
  String get needsLocationRequired => 'Hitamo ahantu';

  @override
  String get needsCustomLocationLabel => 'Andika ahantu hihariye';

  @override
  String get needsCustomLocationHint =>
      'urug. Jinja, Fort Portal, cyangwa agace uherereyemo';

  @override
  String get needsUrgencyLabel => 'Byihutirwa';

  @override
  String get needsPublishBtn => 'Tangaza ubusabe bw\'Ibikenewe';

  @override
  String get needsPreviewBtn => 'Banza urebe ubusabe';

  @override
  String get needsPreviewTitle => 'Ongera usuzume ubusabe bwawe';

  @override
  String get needsPreviewEdit => 'Hindura';

  @override
  String get needsRequestSubmittedContent =>
      'Ubusabe bwawe bw\'Ibikenewe buri ku isoko. Abatanga serivisi bashobora kubureba no gusubiza.';

  @override
  String needsBudgetPreview(String currency, String amount) {
    return 'Ingengo: $currency $amount';
  }

  @override
  String get needsCategoryBusinessEquipment => 'Ibikoresho by\'ubucuruzi';

  @override
  String get needsCategoryInventory => 'Ibicuruzwa byo mu bubiko';

  @override
  String get needsCategoryAgriculture => 'Ubuhinzi';

  @override
  String get needsCategoryEducation => 'Uburezi';

  @override
  String get needsCategoryHealth => 'Ubuzima';

  @override
  String get needsCategoryHomeEnergy => 'Urugo n\'ingufu';

  @override
  String get needsCategoryCommunity => 'Umuryango';

  @override
  String get needsCategoryTechnology => 'Ikoranabuhanga';

  @override
  String get needsCategoryTransport => 'Ubwikorezi';

  @override
  String get needsUrgencyUrgent => 'Byihutirwa cyane';

  @override
  String get needsUrgencyWithin30Days => 'Mu minsi 30';

  @override
  String get needsUrgencyThisMonth => 'Muri uku kwezi';

  @override
  String get needsUrgencyFlexible => 'Biroroshye guhinduka';

  @override
  String get needsCategoryTravelInternational => 'Ingendo n\'Amahanga';

  @override
  String get needsCategoryMachineryEquipment => 'Imashini n\'Ibikoresho';

  @override
  String get needsCategoryProfessionalServices => 'Serivisi z\'Abanyamwuga';

  @override
  String get needsCategoryTransportLogistics => 'Ubwikorezi n\'Ingendo';

  @override
  String get needsCategorySpecializedProducts =>
      'Ibicuruzwa Byihariye no Gutumiza';

  @override
  String get needsMakeOffer => 'Tanga Igiciro';

  @override
  String get needsProviderOffers => 'Ibiciro by\'Abatanga Serivisi';

  @override
  String get needsAcceptOffer => 'Emera Igiciro';

  @override
  String get providerServicesTitle => 'Serivisi z\'Utanga Serivisi';

  @override
  String get providerServicesSubtitle =>
      'Bwira abantu icyo ushobora kubafashamo.';

  @override
  String get financialServicesCategory => 'Serivisi z\'Imari';

  @override
  String get financialServicesDesc =>
      'Serivisi z\'inguzanyo, forex, abaganga ba banki, SACCO, microfinance n\'inama z\'imari.';

  @override
  String get bankLoanAgentCapability => 'Umuganga w\'Inguzanyo ya Banki';

  @override
  String get moneyLenderPrivateLenderCapability =>
      'Umuterankunga ku Giti cye / Umuha w\'Inguzanyo';

  @override
  String get financialAdvisoryCapability => 'Inama z\'Imari';

  @override
  String get forexCurrencyExchangeCapability => 'Forex / Guhindura Inkunga';

  @override
  String get loanServicesCapability => 'Serivisi z\'Inguzanyo';

  @override
  String get saccoMicrofinanceCapability => 'SACCO / Serivisi za Microfinance';

  @override
  String get otherFinancialServicesCapability => 'Serivisi Zindi z\'Imari';

  @override
  String get organisationOptional => 'Umuryango wawe (ntibisabwa)';

  @override
  String get organisationSubtitle =>
      'Ongeraho ikigo, ubucuruzi cyangwa umuryango wawe n\'inshingano zawe kugira ngo abasaba bamenye uwo uhagarariye.';

  @override
  String get organisationHint =>
      'urugero: Equity Bank, Hans Finance, ABC Forex';

  @override
  String get organisationLabel => 'Ikigo / Banki / Umuryango';

  @override
  String get roleOptional => 'Inshingano zawe (ntibisabwa)';

  @override
  String get roleHint =>
      'urugero: Utanga Inguzanyo Ku Giti Cye, Umuganga wa Banki';

  @override
  String get showProfessionalTagProvider => 'Erekana ikimenyetso cy\'inzobere';

  @override
  String get showProfessionalTagProviderSubtitle =>
      'Erekana serivisi, ikigo n\'inshingano zawe ku bitangwa.';

  @override
  String get allowInstitutionMatchingProvider =>
      'Emera guhuza mu buryo bw\'ubwenge';

  @override
  String get allowInstitutionMatchingProviderSubtitle =>
      'Reka ubusabe bujyanye bubone ibyo utanga.';

  @override
  String get allowSmartMatchingProvider => 'Emera guhuza mu buryo bw\'ubwenge';

  @override
  String get allowSmartMatchingProviderSubtitle =>
      'Reka ubusabe bujyanye bubone ibyo utanga.';

  @override
  String servicesCount(int count) {
    return 'Serivisi $count';
  }

  @override
  String get zeroServicesAdded => 'Nta serivisi zongeweho';

  @override
  String get addServices => 'Ongeraho serivisi';

  @override
  String get addService => 'Ongeraho Serivisi';

  @override
  String get providerVerified => 'Uwatanze Serivisi Yemejwe';

  @override
  String get selfDeclared => 'Yiyemeje';

  @override
  String get yourServices => 'Serivisi Zawe';

  @override
  String get yourServicesSubtitle => 'Cunga serivisi utanga ku bandi';

  @override
  String get noServicesYet => 'Nta serivisi zongeyeho kugeza ubu';

  @override
  String get noServicesYetSubtitle =>
      'Ongeraho ibyo ushobora gutanga kugira ngo ubone amahirwe ajyanye n\'ibyo ushobora gukora no gutanga ibiciro ku Byifuzo.';

  @override
  String get chooseCategory => 'Hitamo Icyiciro';

  @override
  String get chooseCapabilities => 'Hitamo Ubushobozi';

  @override
  String get marketingAndPromotion => 'Kwamamaza no Kumenyekanisha';

  @override
  String get socialMediaMarketing => 'Kwamamaza ku Mbuga Nkoranyambaga';

  @override
  String get tiktokPromotion => 'Kwamamaza kuri TikTok';

  @override
  String get instagramPromotion => 'Kwamamaza kuri Instagram';

  @override
  String get youtubePromotion => 'Kwamamaza kuri YouTube';

  @override
  String get facebookPromotion => 'Kwamamaza kuri Facebook';

  @override
  String get influencerMarketing => 'Kwamamaza binyuze ku Bamamare';

  @override
  String get contentCreation => 'Gukora Ibikubiyemo';

  @override
  String get productReviews => 'Isuzuma ry\'Ibicuruzwa';

  @override
  String get eventPromotion => 'Kwamamaza Ibirori';

  @override
  String get whatsAppCommunityPromotion =>
      'Kwamamaza kuri WhatsApp / Umuryango';

  @override
  String get affiliateMarketing => 'Kwamamaza ku Bafatanyabikorwa';

  @override
  String get advertisingCampaigns => 'Ubukangurambaga bwo Kwamamaza';

  @override
  String get brandPromotion => 'Kumenyekanisha Ikirango';

  @override
  String get otherMarketingServices => 'Izindi Serivisi zo Kwamamaza';

  @override
  String get iHaveAnAudience => 'Mfite Abankurikira';

  @override
  String get whereIsYourAudience => 'Abankurikira bari he?';

  @override
  String get selectAudiencePlatforms => 'Hitamo ahantu hose hakureba';

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
  String get audiencePlatformOther => 'Ahandi';

  @override
  String get tellBusinessesAboutYourAudience =>
      'Sobanurira ubucuruzi abankurikira bawe';

  @override
  String get audienceFollowersMembersCount =>
      'Umubare w\'abagukurikira / abanyamuryango';

  @override
  String get audienceMainLocation => 'Ahantu nyamukuru abankurikira bari';

  @override
  String get audienceMainInterest => 'Icyo bakunda / icyiciro nyamukuru';

  @override
  String get declaredAudience => 'Abankurikira watangaje';

  @override
  String get addSelected => 'Ongeraho Ibyatoranyijwe';

  @override
  String get removeService => 'Kuraho Serivisi';

  @override
  String get removeServiceConfirm =>
      'Uremeza ko ushaka gukuraho iyi serivisi ku mwirondoro wawe?';

  @override
  String get providerOpportunitiesTitle => 'Abantu barashaka ibyo utanga';

  @override
  String get workProfileTitle => 'Profayili y\'akazi';

  @override
  String get workProfileSubtitle =>
      'Sobanura akazi ushaka bitandukanye na serivisi utanga.';

  @override
  String get workProfilesDisabled => 'Profayili z\'akazi ntizirafungurwa.';

  @override
  String get addWorkProfile => 'Ongeraho profayili y\'akazi';

  @override
  String get noWorkProfilesYet =>
      'Nta profayili y\'akazi irahari. Yongeraho niba ushaka ko abantu bamenya akazi ushoboye.';

  @override
  String get jobOpportunitiesUnavailable =>
      'Guhuza abantu n\'akazi ntibiraboneka. Profayili yawe irabitswe ku gihe kizaza kandi ntabwo itanga ikirango cy\'uwagenzuwe.';

  @override
  String get jobRole => 'Uruhare rw\'akazi';

  @override
  String get workTypes => 'Ubwoko bw\'akazi';

  @override
  String get qualifications => 'Impamyabumenyi n\'ubumenyi';

  @override
  String get experience => 'Uburambe';

  @override
  String get availability => 'Kuboneka';

  @override
  String get fullTime => 'Igihe cyose';

  @override
  String get partTime => 'Igihe gito';

  @override
  String get contract => 'Amasezerano';

  @override
  String get weekends => 'Mu mpera z\'icyumweru';

  @override
  String get preferredLocation => 'Aho wifuza';

  @override
  String get flexible => 'Byahinduka';

  @override
  String get onsite => 'Ku kazi';

  @override
  String get remote => 'Kure';

  @override
  String get hybrid => 'Bivanze';

  @override
  String get expectedPay => 'Umushahara wifuza';

  @override
  String get payOpen => 'Umushahara ufunguye';

  @override
  String get per => 'Kuri';

  @override
  String get perHour => 'isaha';

  @override
  String get perDay => 'umunsi';

  @override
  String get perWeek => 'icyumweru';

  @override
  String get perProject => 'umushinga';

  @override
  String get languages => 'Indimi';

  @override
  String get profileSummary => 'Incamake ya profayili';

  @override
  String get saveWorkProfile => 'Bika profayili y\'akazi';

  @override
  String get deactivateWorkProfile => 'Hagarika profayili y\'akazi';

  @override
  String get deactivateWorkProfileConfirm =>
      'Ibi bihisha profayili y\'akazi ariko ntibikuraho serivisi utanga.';

  @override
  String get deactivate => 'Hagarika';

  @override
  String get inactive => 'Ntikora';

  @override
  String get edit => 'Hindura';

  @override
  String get retry => 'Ongera ugerageze';

  @override
  String get requiredField => 'Birasabwa';

  @override
  String get viewOpportunities => 'Reba amahirwe';

  @override
  String get addYourServices => 'Ongeraho serivisi zawe';

  @override
  String get canYouHelp => 'Ushobora gufasha abantu mu kintu runaka?';

  @override
  String get youDontProvideThisService => 'Nturatanga iyi serivisi kugeza ubu.';

  @override
  String addCapabilityAction(String capability) {
    return 'Ongeraho $capability';
  }

  @override
  String opportunitiesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Amahirwe $count',
      one: 'Amahirwe 1',
    );
    return '$_temp0';
  }

  @override
  String get navHome => 'Ahabanza';

  @override
  String get navPost => 'Ohereza';

  @override
  String get navActivity => 'Ibikorwa';

  @override
  String get postChoiceTitle => 'Urashaka kohereza iki?';

  @override
  String get postLoanAction => 'Inguzanyo';

  @override
  String get postLoanSubtitle => 'Kora ubusabe bw\'inguzanyo';

  @override
  String get postForexAction => 'Forex';

  @override
  String get postForexSubtitle => 'Kora ubusabe bwo kuvunja amafaranga';

  @override
  String get postNeedAction => 'Icyo ukeneye';

  @override
  String get postNeedSubtitle => 'Tanga icyo ukeneye';

  @override
  String get forYouTitle => 'Ibyakugenewe';

  @override
  String get peopleLookingForServices => 'Abantu barashaka serivisi utanga';

  @override
  String get addYourServicesPrompt => 'Ufite serivisi waza ufasha abantu?';

  @override
  String get whatCanYouHelpWith => 'Ni iki wafasha abandi?';

  @override
  String get whatCanYouHelpWithSubtitle =>
      'Tubwire ibyo utanga tuzaguhuza n\'ababikeneye.';

  @override
  String get addYourServicesCta => 'Ongeraho serivisi zawe';

  @override
  String get newCategoriesAvailable => 'Ibyiciro bishya birahari';

  @override
  String newCategoriesAvailableSubtitle(Object categories) {
    return 'Twongeyeho $categories. Ushobora kuba ufite icyo watanga muri byo.';
  }

  @override
  String get exploreNewCategoriesCta => 'Reba ibyiciro bishya';

  @override
  String matchingNeedsSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ibyifuzo bishya # bihuye na serivisi zawe.',
      one: 'Icyifuzo gishya # gihuye na serivisi zawe.',
    );
    return '$_temp0';
  }

  @override
  String get seeOpportunitiesCta => 'Reba amahirwe';

  @override
  String get discoveryQuestionTitle => 'Ikibazo kigufi';

  @override
  String get discoveryBusinessTitle => 'Hari icyo uteganya mu gihe kizaza?';

  @override
  String get discoveryBusinessQuestion =>
      'Ese vuba aha uzakenera ibikoresho, ubwikorezi, kugura ibicuruzwa cyangwa serivisi z\'ubucuruzi?';

  @override
  String get discoveryTravelQuestion =>
      'Ese uteganya gukora urugendo mu mezi make ari imbere?';

  @override
  String get discoveryEducationQuestion =>
      'Ese amahirwe yo kwimenyereza umwuga cyangwa kwiteza imbere mu kazi yakugirira akamaro?';

  @override
  String get discoveryFinancialQuestion =>
      'Ese ushimishijwe n\'inguzanyo, inkunga y\'amafaranga cyangwa amahirwe ya Forex?';

  @override
  String get discoveryEquipment => 'Ibikoresho';

  @override
  String get discoveryLogistics => 'Ubwikorezi';

  @override
  String get discoveryServices => 'Serivisi';

  @override
  String get discoveryProcurement => 'Kugura ibicuruzwa';

  @override
  String get discoveryYes => 'Yego';

  @override
  String get discoveryLater => 'Wenda nyuma';

  @override
  String get discoveryNotNow => 'Si ubu';

  @override
  String get discoveryNo => 'Oya';

  @override
  String get discoveryLoans => 'Inguzanyo';

  @override
  String get discoveryForex => 'Forex';

  @override
  String get discoveryBoth => 'Byombi';

  @override
  String get discoveryTravelCta => 'Shaka ubufasha bw\'urugendo';

  @override
  String get discoveryEducationCta => 'Shaka amahirwe y\'uburezi';

  @override
  String get discoveryBusinessCta => 'Shakisha amahirwe';

  @override
  String get discoveryFinancialCta => 'Fungura isoko';

  @override
  String get discoveryOptionsTooltip => 'Amahitamo yo gushakisha';

  @override
  String get discoveryHideQuestion => 'Hisha iki kibazo';

  @override
  String get discoveryFewerQuestions => 'Erekana ibibazo bike bisa n\'iki';

  @override
  String get discoverySkip => 'Simbuka';

  @override
  String get discoveryExploreOpportunities => 'Shakisha amahirwe';

  @override
  String get savedPlansTitle => 'Imigambi n\'ibyo ukunda';

  @override
  String get savedPlansEmptyTitle => 'Nta migambi wabika';

  @override
  String get savedPlansEmptySubtitle =>
      'Imigambi n\'ibyo ukunda bibitswe mu ibanga bivuye mu bibazo byo gushakisha bizagaragara hano.';

  @override
  String get savedPlanActions => 'Ibikorwa by\'umugambi';

  @override
  String get savedPlanEdit => 'Hindura';

  @override
  String get savedPlanDelete => 'Siba';

  @override
  String get savedPlanReminderSet => 'Kwibutswa byashyizweho';

  @override
  String savedPlanUpdated(String date) {
    return 'Byavuguruwe $date';
  }

  @override
  String get savedPlanTravel => 'Urugendo';

  @override
  String get savedPlanEducationCareer => 'Uburezi n\'umwuga';

  @override
  String get savedPlanBusiness => 'Ubucuruzi';

  @override
  String get savedPlanFinancial => 'Imari';

  @override
  String get savedPlanGeneral => 'Rusange';

  @override
  String get savedPlanNoDetails => 'Nta bisobanuro byongeweho';

  @override
  String get savedPlanDeleteTitle => 'Siba uyu mugambi?';

  @override
  String get savedPlanDeleteConfirmation =>
      'Uyu mugambi wabitswe mu ibanga uzavanwa kuri konti yawe.';

  @override
  String get savedPlanCancel => 'Hagarika';

  @override
  String get savedPlanEditTitle => 'Hindura umugambi';

  @override
  String get savedPlanName => 'Izina ry\'umugambi';

  @override
  String get savedPlanDestination => 'Aho ujya';

  @override
  String get savedPlanPreferredLocation => 'Ahantu ukunda';

  @override
  String get savedPlanTimeframe => 'Igihe giteganyijwe';

  @override
  String get savedPlanAddDate => 'Ongeraho itariki uteganya';

  @override
  String get savedPlanReminder => 'Kwibutswa';

  @override
  String get savedPlanNoReminder => 'Nta kwibutswa';

  @override
  String get savedPlanOneWeekBefore => 'Icyumweru kimwe mbere';

  @override
  String get savedPlanOneMonthBefore => 'Ukwezi kumwe mbere';

  @override
  String get savedPlanSave => 'Bika';

  @override
  String get savedPlanStartingLocation => 'Aho uhera';

  @override
  String get savedPlanAssistanceNeeded => 'Ubufasha ukeneye';

  @override
  String get savedPlanWhatWouldHelp => 'Ni iki cyakugirira akamaro?';

  @override
  String postDurationActiveDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Bikora mu minsi $days.',
      one: 'Bikora mu munsi 1.',
    );
    return '$_temp0';
  }

  @override
  String postDurationFullNotice(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Ubusabe bwawe buzakora mu minsi $days.',
      one: 'Ubusabe bwawe buzakora mu munsi 1.',
    );
    return '$_temp0';
  }

  @override
  String get postDurationNotice =>
      'Ubusabe bwawe buzarangira mu buryo bwikora nyuma y\'iki gihe.';

  @override
  String get nationalityUgandan => 'Umunya-Uganda';

  @override
  String get nationalityKenyan => 'Umunya-Kenya';

  @override
  String get nationalityTanzanian => 'Umunya-Tanzaniya';

  @override
  String get nationalityRwandan => 'Umunyarwanda';

  @override
  String get nationalityNigerian => 'Umunya-Nijeriya';

  @override
  String get nationalitySouthAfrican => 'Umunya-Afurika y\'Epfo';

  @override
  String get nationalityEgyptian => 'Umunya-Misiri';

  @override
  String get nationalityCongoleseDrc => 'Umunya-Kongo (DRC)';

  @override
  String get nationalityBurundian => 'Umunya-Burundi';

  @override
  String get nationalitySouthSudanese => 'Umunya-Sudani y\'Epfo';

  @override
  String get nationalitySomali => 'Umunya-Somaliya';

  @override
  String get iWantJobs => 'Ndashaka akazi';

  @override
  String get iWantJobsSubtitle =>
      'Tunganya umwirondoro wo gushaka akazi muri iki cyiciro';

  @override
  String get searchCategories => 'Shakisha ibyiciro';

  @override
  String get searchCatalog => 'Shakisha ibyiciro, serivisi n\'imirimo';

  @override
  String get catalogNoMatch => 'Nta bihuye bibonetse';

  @override
  String get requestService => 'Saba serivisi';

  @override
  String get catalogRequestSubmitted => 'Icyifuzo cya serivisi cyoherejwe';

  @override
  String get reportContent => 'Tanga raporo y\'ibirimo';

  @override
  String get contentReportSubmitted => 'Raporo yoherejwe';

  @override
  String get providerSafetyMedical =>
      'Nipanze ntitanga inama z\'ubuvuzi cyangwa ngo yemeze ubuvuzi. Uburyo bwo kuvura busaba inzobere ibifitiye uruhushya, uburenganzira n\'ivuriro ry\'ibyihutirwa.';

  @override
  String get providerSafetyInvestment =>
      'Nipanze ntiyishyuza cyangwa ngo ibike amafaranga, itange inama z\'ishoramari cyangwa yemeze inyungu.';

  @override
  String get providerSafetyTraditional =>
      'Ntukavuge ko ukiza indwara cyangwa wemeza ibisubizo. Ubuvuzi gakondo bugengwa n\'amategeko y\'aho uri.';

  @override
  String get providerSafetyWellness =>
      'Kwamamaza massage na spa bigenewe ubuzima bwiza n\'ubuvuzi gusa. Serivisi z\'imibonano mpuzabitsina zirabujijwe.';

  @override
  String get providerSafetyAcademic =>
      'Shaka ubuyobozi n\'ibitekerezo. Gutanga umurimo w\'undi nk\'uwawe bishobora kugutera kwirukanwa.';

  @override
  String get providerSafetyDomestic =>
      'Ntushyire aderesi nyayo y\'urugo mu mwirondoro cyangwa itangazo bigaragarira bose.';

  @override
  String get noMatchingJobOpportunities =>
      'Nta mahirwe y\'akazi ahwanye arahari ubu. Amahirwe azagaragara hano abakoresha nibashyiraho ibyifuzo.';

  @override
  String get selectAtLeastOneRole =>
      'Nyamuneka hitamo byibura inshingano imwe y\'akazi';

  @override
  String qualificationsDeclared(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Impamyabumenyi $count zatangajwe',
      one: 'Impamyabumenyi 1 yatangajwe',
    );
    return '$_temp0';
  }

  @override
  String rolesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Inshingano $count',
      one: 'Inshingano 1',
    );
    return '$_temp0';
  }

  @override
  String get providerTypeChange => 'Hindura';

  @override
  String get providerIdentityRequiredInfo =>
      'Andika izina rigaragara kandi wemeze uburenganzira bwo guhagararira kugira ukomeze.';

  @override
  String get providerIdentitySwitchSuccess =>
      'Umwirondoro w’utanga serivisi wahinduwe.';

  @override
  String get providerIdentityCurrent => 'Iriho';

  @override
  String get providerIdentityDisplayHeading => 'Wifuza kugaragazwa ute?';

  @override
  String get providerIdentityDisplayName => 'Izina rigaragara';

  @override
  String get providerIdentityCompanyName => 'Izina ry’ikigo cyangwa ubucuruzi';

  @override
  String get providerIdentityCompanyOnly => 'Izina ry’ikigo';

  @override
  String get providerIdentityCompanyRepresentative => 'Ikigo gihagarariwe';

  @override
  String get providerIdentityRepresentativeName => 'Izina ry’uhagarariye ikigo';

  @override
  String get providerIdentityAuthority => 'Nemerewe guhagararira ubu bucuruzi';

  @override
  String providerIdentityRepresentedBy(String name) {
    return 'Uhagarariwe na $name';
  }

  @override
  String providerIdentitySwitchTitle(String identity) {
    return 'Hindura ube $identity?';
  }

  @override
  String get providerIdentitySwitchBody =>
      'Ibi bihindura iki cyiciro gusa. Ibindi byiciro ntibihinduka.';

  @override
  String get providerIdentityDataKept =>
      'Amakuru ya serivisi aragumana. Nta kintu gisibwa.';

  @override
  String providerIdentityOldServicesInactive(String identity) {
    return 'Serivisi za $identity muri iki cyiciro zirahagarara ariko zishobora kongera gukorwa.';
  }

  @override
  String providerIdentityNewOffers(String identity) {
    return 'Amasoko mashya azakoresha umwirondoro wawe wa $identity.';
  }

  @override
  String get providerIdentityVerificationReset =>
      'Ibisabwa mu igenzura bishobora guhinduka. Igenzura ntiryimurwa.';

  @override
  String get providerIdentityHistoryKept =>
      'Amasezerano, ibitekerezo, amateka n’imyanya y’akazi bwite bigumana uko biri.';

  @override
  String providerIdentityPendingOffers(int count) {
    return 'Ufite amasoko $count ategereje. Azaguma uko yoherejwe; ushobora kuyakuraho.';
  }

  @override
  String get providerIdentityReviewTitle => 'Suzuma ihinduka';

  @override
  String get providerIdentityCategory => 'Icyiciro';

  @override
  String get providerIdentityNewIdentity => 'Umwirondoro mushya';

  @override
  String get providerIdentityPublicName => 'Izina rigaragara ku bandi';

  @override
  String get providerIdentityReused => 'Ibyakoreshejwe mu mwirondoro usanzwe';

  @override
  String get providerIdentityNeedsAttention => 'Ibyo kwitaho';

  @override
  String get providerIdentityCompanyVerificationStatus =>
      'Igenzura ry’ikigo ririhariye kandi ntiryimurwa.';

  @override
  String get providerIdentityNoActiveWarning =>
      'Nta serivisi izaba ikora muri iki cyiciro nyuma yo guhindura.';

  @override
  String get providerIdentityConfirm => 'Emeza ihinduka';

  @override
  String get providerTypeWhatWeOffer => 'Ibyo dutanga';

  @override
  String get providerTypeWhatRoles => 'Ukora iyihe mirimo?';

  @override
  String get providerTypeStepOneOfThree => 'INTAMBWE YA 1 KURI 3';

  @override
  String get providerTypePickRoles =>
      'Hitamo imirimo yose ijyanye nawe. Ushobora kongeraho indi nyuma.';

  @override
  String get providerTypeNextKind => 'Komeza: hitamo ubwoko';

  @override
  String providerTypeSaveServicesCount(Object count) {
    return 'Bika serivisi $count';
  }

  @override
  String get providerTypeSelectService => 'Hitamo nibura serivisi imwe';

  @override
  String get providerTypeHiddenCompanyOnly =>
      'Byahishwe: bitangwa na Sosiyete gusa';

  @override
  String get providerTypeOfferingAs => 'Utanga nka';

  @override
  String get providerTypeOffering => 'Utanga serivisi muri iki cyiciro';

  @override
  String get providerTypeTitle => 'Ni nde utanga serivisi?';

  @override
  String get providerTypeSubtitle =>
      'Ibi bifasha abantu kumenya niba bazakorana nawe cyangwa n’ubucuruzi bwawe. Ushobora kubihitamo ukundi kuri buri cyiciro.';

  @override
  String get providerTypeIndividual => 'Umuntu ku giti cye';

  @override
  String get providerTypeIndividualDesc =>
      'Ntanga ubumenyi bwanjye ku bakiriya ku giti cyanjye, ndi umwigenga cyangwa umukozi.';

  @override
  String get providerTypeCompany => 'Ikigo / Umuryango';

  @override
  String get providerTypeCompanyDesc =>
      'Ubucuruzi, ikigo cy’ubuhuza, itsinda cyangwa ikigo cyanditse.';

  @override
  String get providerTypeNotVerification =>
      'Guhitamo ibi ntibikugenzura. Igenzura ririhariye kandi risabwa gusa iyo serivisi irikeneye.';

  @override
  String get providerTypeChooseOne => 'Hitamo kimwe kugira ngo ukomeze';

  @override
  String get providerTypeJobsPersonalNote =>
      'Umwirondoro w’akazi ni uwawe ku giti cyawe kandi ubikwa mu izina ryawe.';

  @override
  String get providerTypeStepOneOfTwo => 'INTAMBWE YA 1 MURI 2';

  @override
  String get providerTypeCompanyServicesHint =>
      'Hitamo serivisi zose ikigo cyawe gitanga.';

  @override
  String get providerTypeCompanyRolesHint => 'Imirimo ushobora guhitamo';

  @override
  String get providerTypeCompanyRolesSubtitle =>
      'Hitamo imirimo ukora. Umwirondoro w’akazi ni uwawe bwite kandi ubikwa ku izina ryawe. Ushobora kongeraho imashini n’ubumenyi nyuma.';

  @override
  String providerTypeCompanySelectionCount(int services, int roles) {
    String _temp0 = intl.Intl.pluralLogic(
      services,
      locale: localeName,
      other: 'serivisi $services',
      one: 'serivisi 1',
      zero: 'Nta serivisi',
    );
    String _temp1 = intl.Intl.pluralLogic(
      roles,
      locale: localeName,
      other: 'imirimo $roles',
      one: 'umurimo 1',
      zero: 'Nta mirimo',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get companyStepTwoOfTwo => 'INTAMBWE YA 2 MURI 2';

  @override
  String get companyDetailsTitle => 'Tubwire ibijyanye n’ikigo cyawe';

  @override
  String get companyDetailsSubtitle =>
      'Ibi byose si itegeko. Aya makuru abikwa mu ibanga kandi agaragara kuri wowe n’abayobozi ba Nipanze gusa.';

  @override
  String get companyName => 'Izina ry’ikigo cyangwa ubucuruzi';

  @override
  String get companyRegistrationNumber => 'Nomero yo kwandikisha';

  @override
  String get companyRegistrationPrivate =>
      'Bigaragara kuri wowe n’abayobozi ba Nipanze gusa.';

  @override
  String get companyTeamSize => 'Umubare w’abakozi';

  @override
  String get companyYearsInBusiness => 'Imyaka mu bucuruzi';

  @override
  String get companyServiceAreas => 'Ukora he?';

  @override
  String get companyServiceAreasHint =>
      'Akarere cyangwa umujyi gusa. Aderesi yawe nyayo ntizagaragara. Tandukanya ahantu ukoresheje koma.';

  @override
  String get companyProofTitle =>
      'Ibyemezo byo kubona ikimenyetso cy’uko wemejwe';

  @override
  String get companyProofIntro =>
      'Bisuzumwa na Nipanze. Kohereza inyandiko byonyine ntibikemeza.';

  @override
  String get companyNoEvidenceRequirements =>
      'Ubu nta cyemezo gisabwa kuri izi serivisi.';

  @override
  String get companyProofNote =>
      'Ushobora kubika ubu ukazongeraho ibimenyetso nyuma. JPG, PNG cyangwa PDF, bitarenze MB 5 kuri buri kimwe.';

  @override
  String get companyEvidenceNotAdded => 'Nticyoherejwe';

  @override
  String get companyEvidenceUploaded => 'Cyoherejwe';

  @override
  String get companyEvidenceUnderReview => 'Kirimo gusuzumwa';

  @override
  String get companyEvidenceRejected => 'Cyanzwe';

  @override
  String get companyEvidenceExpired => 'Igihe cyacyo cyarangiye';

  @override
  String get companyEvidenceApproved => 'Cyemejwe';

  @override
  String get companyEvidenceAdd => 'Ongeraho icyemezo';

  @override
  String get companyEvidenceReplace => 'Simbuza';

  @override
  String get companyDocumentRemove => 'Kuraho';

  @override
  String get providerEvidenceRemoveConfirm =>
      'Ushaka gukuraho iyi nyandiko wohereje? Ntushobora kubisubiza inyuma.';

  @override
  String get companyDocumentsTitle => 'Ohereza inyandiko z’ikigo';

  @override
  String get companyDocumentsSubtitle =>
      'Ohereza inyandiko z’iyandikisha ry’ubucuruzi, impushya, ibyemezo n’izindi nyandiko zijyanye n’ikigo.';

  @override
  String get companyDocumentTypeLabel => 'Ubwoko bw’inyandiko';

  @override
  String get companyDocumentTypeCertificate => 'Icyemezo';

  @override
  String get companyDocumentTypeOther => 'Ibindi';

  @override
  String get companyEvidenceReadError =>
      'Ntibyashobotse gusoma dosiye wahisemo. Gerageza indi.';

  @override
  String get companyEvidenceTooLarge => 'Hitamo dosiye itarengeje MB 5.';

  @override
  String get companyEvidenceUnsupported =>
      'Hitamo dosiye ya JPG, PNG cyangwa PDF.';

  @override
  String get companySave => 'Bika umwirondoro w’ikigo';

  @override
  String companySelectionCount(int services, int roles) {
    String _temp0 = intl.Intl.pluralLogic(
      services,
      locale: localeName,
      other: 'serivisi $services',
      one: 'serivisi 1',
      zero: 'Nta serivisi',
    );
    String _temp1 = intl.Intl.pluralLogic(
      roles,
      locale: localeName,
      other: 'imirimo $roles',
      one: 'umurimo 1',
      zero: 'Nta mirimo',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get companyTeamOneToFive => '1–5';

  @override
  String get companyTeamSixToTwenty => '6–20';

  @override
  String get companyTeamTwentyOneToFifty => '21–50';

  @override
  String get companyTeamFiftyPlus => '50+';

  @override
  String get companyYearsUnderOne => 'Munsi ya 1';

  @override
  String get companyYearsOneToTwo => '1–2';

  @override
  String get companyYearsThreeToFive => '3–5';

  @override
  String get companyYearsSixToTen => '6–10';

  @override
  String get companyYearsTenPlus => '10+';

  @override
  String providerTypeGroupCount(Object selected, Object total) {
    return '$selected kuri $total';
  }

  @override
  String get companyPersonalProfile => 'Umwirondoro bwite';

  @override
  String get providerTypeJobNeedsDetails =>
      'Ongeraho imashini n’ubumenyi kugira ngo uhuze n’akazi.';

  @override
  String get providerTypeNextCompanyDetails => 'Komeza: amakuru y’ikigo';

  @override
  String providerSummaryAll(int count) {
    return 'Byose $count';
  }

  @override
  String providerSummaryServices(int count) {
    return 'Serivisi $count';
  }

  @override
  String providerSummaryJobs(int count) {
    return 'Imirimo $count';
  }

  @override
  String get companyProfileSaved => 'Umwirondoro w’ikigo wabitswe.';

  @override
  String get providerEvidenceTab => 'Ibimenyetso by’abatanga serivisi';

  @override
  String get providerEvidenceHeader =>
      'Ibimenyetso by’abatanga serivisi bitegereje gusuzumwa';

  @override
  String get providerEvidenceEmpty =>
      'Nta bimenyetso by’abatanga serivisi bitegereje gusuzumwa.';

  @override
  String get providerEvidenceCapabilities => 'ubushobozi';

  @override
  String get providerEvidenceOpenFile => 'Fungura dosiye y’icyemezo';

  @override
  String get providerEvidenceCompanyDetails =>
      'Amakuru y’ikigo (abayobozi gusa)';

  @override
  String get providerEvidenceApprove => 'Emeza ubu bushobozi';

  @override
  String get providerEvidenceReject => 'Anga';

  @override
  String get providerEvidenceRejectReason => 'Anga icyemezo';

  @override
  String get providerEvidenceReason => 'Impamvu yo kwanga';

  @override
  String get providerEvidenceReviewSaved => 'Isuzuma ry’icyemezo ryabitswe.';

  @override
  String get providerCapabilityActive => 'Birakora';

  @override
  String get providerCapabilityInactive => 'Ntibikora';

  @override
  String get providerCapabilityPendingReview => 'Bitegereje gusuzumwa';

  @override
  String get providerCapabilityRejected => 'Byanzwe';

  @override
  String get providerPolicyNoProof => 'Nta cyemezo gikenewe';

  @override
  String get providerPolicyProofLater =>
      'Ongeraho icyemezo kugira ngo usuzumirwe kubona ikirango cya Nipanze';

  @override
  String get providerPolicyProofRequired =>
      'Icyemezo kirakenewe mbere yo gutangira';

  @override
  String get providerPolicyNeedsProofTag => 'Icyemezo kirakenewe';

  @override
  String get providerPolicyUploadDocuments => 'Ohereza inyandiko';

  @override
  String get providerEvidenceNoRequirements =>
      'Nta cyemezo cyateganyijwe kuri ubu bushobozi.';

  @override
  String get providerEvidenceSubmitted =>
      'Icyemezo cyoherejwe kugira ngo gisuzumwe.';

  @override
  String get companyVerificationTitle => 'Igenzura ry’ikigo';

  @override
  String get companyVerificationIntro =>
      'Si ngombwa. Ohereza inyandiko imwe cyangwa zombi kugira ngo Nipanze izisuzume.';

  @override
  String get companyVerificationRegistration =>
      'Icyemezo cy’iyandikisha ry’ubucuruzi';

  @override
  String get companyVerificationLicence =>
      'Impushya cyangwa inyandiko z’uburenganzira';

  @override
  String get companyVerificationNotSubmitted => 'Ntabwo byoherejwe';

  @override
  String get companyVerificationPending => 'Bitegereje gusuzumwa';

  @override
  String get companyVerificationVerified => 'Byemejwe';

  @override
  String get companyVerificationRejected => 'Byanzwe';

  @override
  String get companyVerificationSeparateNote =>
      'Icyemezo cy’iyandikisha nticyemeza serivisi zigengwa n’amategeko. Zisuzumwa ukwazo kuri buri serivisi.';

  @override
  String get companyVerificationFileHint =>
      'JPG, PNG cyangwa PDF, bitarenze MB 5 buri imwe. Ushobora kubika ubu ukazohereza ibimenyetso nyuma.';

  @override
  String get companyVerificationUpload => 'Ohereza inyandiko';

  @override
  String get companyVerificationUploaded => 'Inyandiko yoherejwe';

  @override
  String get providerTypeEditCompanyDetails => 'Hindura amakuru y’ikigo';

  @override
  String get providerTypeOtherGroup => 'Ibindi';

  @override
  String get providerTypeNoRolesConfigured =>
      'Nta mirimo yihariye yateganyijwe muri iki cyiciro kugeza ubu.';

  @override
  String get providerNoJobRolesAdded => 'Nta mirimo y’akazi yongeweho';

  @override
  String get providerAvailableForJobs => 'Aboneka ku kazi';

  @override
  String providerOpenJobsMatch(int count) {
    return 'Imirimo $count ihuye irafunguye';
  }

  @override
  String get companyLeaveTitle => 'Uve mu igenamiterere ry’ikigo?';

  @override
  String get companyLeaveSelectionsMessage =>
      'Serivisi n’imirimo wahisemo ntibirabikwa.';

  @override
  String get companyLeaveDetailsMessage =>
      'Amakuru y’ikigo n’ibyo wahisemo ntibirabikwa.';

  @override
  String get companyLeaveKeepEditing => 'Komeza guhindura';

  @override
  String get companyLeaveDiscard => 'Hagarika ibyahinduwe';
}
