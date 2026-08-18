// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Nipanze';

  @override
  String get welcomeTitle => 'اقترض. أقرض. انمو.';

  @override
  String get welcomeTagline => 'استكشف العروض المحلية';

  @override
  String get welcomeSubtitle => 'سوق موثوق يربط بين المقترضين والمقرضين.';

  @override
  String get selectLanguage => 'اختر اللغة';

  @override
  String get choosePreferredLanguage => 'اختر لغتك المفضلة';

  @override
  String get continueWithPhone => 'المتابعة برقم الهاتف';

  @override
  String get continueWithEmail => 'المتابعة بالبريد الإلكتروني';

  @override
  String get getStartedTitle => 'ابدأ مع Nipanze';

  @override
  String get getStartedSubtitle => 'اختر كيف ترغب في المتابعة';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get createAccountSubtitle => 'جديد في Nipanze؟ سجل برقم الهاتف';

  @override
  String get logIn => 'تسجيل الدخول';

  @override
  String get logInSubtitle => 'لديك حساب بالفعل؟ سجل الدخول';

  @override
  String get welcomeBack => 'مرحباً بعودتك 👋';

  @override
  String get loginToAccount => 'تسجيل الدخول إلى حسابك';

  @override
  String get phone => 'الهاتف';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get password => 'كلمة المرور';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get createPassword => 'إنشاء كلمة المرور';

  @override
  String get rememberMe => 'تذكرني';

  @override
  String get forgotPassword => 'هل نسيت كلمة المرور؟';

  @override
  String get dontHaveAccount => 'ليس لديك حساب؟';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get enterPhoneTitle => 'أدخل رقم هاتفك';

  @override
  String get enterPhoneSubtitle => 'سنرسل لك رمز التحقق';

  @override
  String get sendCode => 'إرسال رمز التحقق';

  @override
  String get tellUsAboutYou => 'أخبرنا عن نفسك';

  @override
  String get completeProfileSubtitle => 'أكمل ملفك الشخصي وعين كلمة المرور';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get finish => 'إنهاء';

  @override
  String get termsNotice =>
      'بالمتابعة، فإنك توافق على شروط الاستخدام وسياسة الخصوصية الخاصة بنا.';

  @override
  String get phoneSafeTitle => 'رقمك في أمان معنا';

  @override
  String get phoneSafeSubtitle => 'نحن لا نشارك رقمك مع أي شخص آخر.';

  @override
  String get navMarkets => 'الأسواق';

  @override
  String get navWatchlist => 'قائمة المتابعة';

  @override
  String get navRequest => 'طلب';

  @override
  String get navPositions => 'الأنشطة';

  @override
  String get navAccount => 'الحساب';

  @override
  String get marketplaceTitle => 'السوق';

  @override
  String listingsLive(int count) {
    return '$count عروض · مباشر';
  }

  @override
  String get filtered => 'مصفى';

  @override
  String get applyingFilters => 'جاري تطبيق التصفية…';

  @override
  String get noListingsFound => 'لم يتم العثور على عروض';

  @override
  String get noListingsSubtitle =>
      'تحقق لاحقاً — تظهر العروض الجديدة في الوقت الفعلي.';

  @override
  String get noMatches => 'لا توجد نتائج';

  @override
  String get noMatchesSubtitle =>
      'لا توجد عروض تطابق فلاتر Pro الخاصة بك.\nجرب تعديل أو مسح معايير التصفية.';

  @override
  String get adjustFilters => 'تعديل الفلاتر';

  @override
  String get removeFromWatchlist => 'إزالة من قائمة المتابعة';

  @override
  String get saveToWatchlist => 'حفظ في قائمة المتابعة';

  @override
  String get months => 'أشهر';

  @override
  String daysLeft(int count) {
    return '$count يوم متبقٍ';
  }

  @override
  String hoursLeft(int count) {
    return '$count ساعة متبقية';
  }

  @override
  String minutesLeft(int count) {
    return '$count دقيقة متبقية';
  }

  @override
  String get expired => 'منتهي';

  @override
  String get watchlistTitle => 'قائمة المتابعة';

  @override
  String get watchlistSubtitle => 'العروض التي تتابعها';

  @override
  String watchlistSaved(int count) {
    return '$count محفوظ';
  }

  @override
  String get watchlistInfoSubscribed =>
      'مجاني للجميع. احصل على إشعارات عند تغيير العروض أو تحسن الأسعار أو إغلاق الإعلانات.';

  @override
  String get watchlistInfoFree =>
      'مجاني للجميع. احصل على إشعارات عند تغيير العروض. اشترك لتقديم العروض.';

  @override
  String get watchlistError => 'خطأ في تحميل قائمة المتابعة';

  @override
  String get watchlistEmpty => 'لا توجد إعلانات محفوظة';

  @override
  String get watchlistEmptySubtitle =>
      'تصفح السوق واضغط على \"حفظ في قائمة المتابعة\" على أي إعلان.';

  @override
  String get browseMarketplace => 'تصفح السوق';

  @override
  String get removedFromWatchlist => 'تمت الإزالة من قائمة المتابعة';

  @override
  String get undo => 'تراجع';

  @override
  String get tryAgain => 'حاول مجدداً';

  @override
  String get myActivityTitle => 'نشاطي';

  @override
  String get myActivitySubtitle => 'إدارة إعلاناتك وعروضك';

  @override
  String myActivityStats(int listings, int offers) {
    return '$listings إعلانات · $offers عروض نشطة';
  }

  @override
  String get tabMyRequests => 'طلباتي';

  @override
  String get tabMyOffers => 'عروضي';

  @override
  String get noOffersYet => 'لا توجد عروض بعد';

  @override
  String get noOffersSubtitle =>
      'العروض التي تضعها على إعلانات السوق ستظهر هنا.';

  @override
  String get browseMarketplaceBtn => 'تصفح السوق';

  @override
  String get activeOffers => 'العروض النشطة';

  @override
  String get matchedAccepted => 'متطابق / مقبول';

  @override
  String get history => 'السجل';

  @override
  String get withdrawOffer => 'سحب العرض؟';

  @override
  String withdrawConfirm(int amount) {
    return 'هل أنت متأكد من سحب عرضك بقيمة UGX $amount؟';
  }

  @override
  String get keepOffer => 'احتفظ بالعرض';

  @override
  String get withdraw => 'سحب';

  @override
  String get myRequestsTitle => 'طلباتي';

  @override
  String sectionActive(int count) {
    return 'نشط · $count';
  }

  @override
  String sectionContracted(int count) {
    return 'متعاقد عليه · $count';
  }

  @override
  String sectionClosed(int count) {
    return 'مغلق · $count';
  }

  @override
  String get noLoanRequests => 'لا توجد طلبات قرض بعد';

  @override
  String get noLoanRequestsSubtitle =>
      'انشر طلباً وسيتنافس المقرضون لتقديم أفضل سعر.';

  @override
  String get createLoanRequest => 'إنشاء طلب قرض';

  @override
  String get cancelListing => 'إلغاء الإعلان؟';

  @override
  String cancelListingConfirm(String title) {
    return 'سيؤدي هذا إلى إزالة \"$title\" من السوق. سيتم رفض جميع العروض المعلقة.';
  }

  @override
  String get keepIt => 'الإبقاء عليه';

  @override
  String get cancelListingBtn => 'إلغاء الإعلان';

  @override
  String get contractNotGenerated => 'لم يتم إنشاء العقد بعد.';

  @override
  String get viewOffers => 'عرض العروض';

  @override
  String get viewContract => 'عرض العقد';

  @override
  String get viewListing => 'عرض الإعلان';

  @override
  String get offeredAmountLabel => 'المبلغ المعروض';

  @override
  String get statusLabel => 'الحالة';

  @override
  String get interestLabel => 'الفائدة';

  @override
  String get lateFeeLabel => 'رسوم التأخير';

  @override
  String lateFeePerMissedInstallment(String value) {
    return '$value لكل قسط فائت';
  }

  @override
  String get repaymentLabel => 'السداد';

  @override
  String get totalPayableLabel => 'إجمالي المستحق';

  @override
  String sentDateLabel(String date) {
    return 'أُرسل في $date';
  }

  @override
  String errorLoadingContract(String error) {
    return 'خطأ في تحميل العقد: $error';
  }

  @override
  String listingOfferCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'عروض',
      one: 'عرض',
    );
    return '$count $_temp0';
  }

  @override
  String get accountTitle => 'الحساب';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get contactUs => 'اتصل بنا';

  @override
  String get community => 'المجتمع';

  @override
  String get legal => 'قانوني';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get signOutConfirm => 'هل أنت متأكد من تسجيل الخروج من حسابك؟';

  @override
  String get cancel => 'إلغاء';

  @override
  String get profileUpdated => 'تم تحديث الملف الشخصي.';

  @override
  String get profileSaved => 'تم حفظ الملف الشخصي.';

  @override
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String get changeProfilePicture => 'تغيير صورة الملف الشخصي';

  @override
  String get phoneNumberLabel => 'رقم الهاتف';

  @override
  String selectRegionLabel(String label) {
    return 'اختر $label';
  }

  @override
  String get incomeTypeLabel => 'نوع الدخل';

  @override
  String get selectIncomeType => 'اختر نوع الدخل';

  @override
  String get employerBusinessOptionalLabel =>
      'اسم جهة العمل / النشاط (اختياري)';

  @override
  String monthlyIncomeWithCurrency(String currency) {
    return 'الدخل الشهري ($currency)';
  }

  @override
  String get bankProfessionalTagLabel => 'البنك والوسم المهني';

  @override
  String get preferredDepositBankLabel =>
      'البنك المفضل أو بنك الإيداع (اختياري)';

  @override
  String get preferredDepositBankHint =>
      'مثال: Equity Bank, Bank of Kigali, Stanbic, KCB';

  @override
  String get accountRepresentsLabel => 'يمثل الحساب';

  @override
  String get individualPersonalAccountLabel => 'فرد / حساب شخصي';

  @override
  String get bankLabel => 'بنك';

  @override
  String get forexExchangeCompanyLabel => 'شركة صرافة';

  @override
  String get saccoLabel => 'SACCO';

  @override
  String get companyLabel => 'شركة';

  @override
  String get bankLoanAgentLabel => 'أنا وكيل قروض بنكية';

  @override
  String get bankLoanAgentSubtitle =>
      'يعرض وسم وكيل بنك لمستخدمي Pro الباحثين عن قروض بنكية.';

  @override
  String get showProfessionalTagLabel => 'إظهار الوسم المهني الخاص بي';

  @override
  String get showProfessionalTagSubtitle =>
      'أوقفه لإخفاء وسوم البنك أو شركة الصرافة أو SACCO أو الوكيل على العروض.';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get enterFullName => 'أدخل اسمك الكامل';

  @override
  String avatarUploadFailed(String error) {
    return 'فشل رفع الصورة: $error';
  }

  @override
  String couldNotSelectImage(String error) {
    return 'تعذر اختيار الصورة: $error';
  }

  @override
  String get identityVerification => 'التحقق من الهوية';

  @override
  String get security => 'الأمان';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get markAllRead => 'تعليم الكل كمقروء';

  @override
  String get noNotificationsYet => 'لا توجد إشعارات حتى الآن';

  @override
  String get noNotificationsSubtitle =>
      'ستظهر الإشعارات هنا عند وصول العروض أو تغير الأسعار أو جاهزية العقود.';

  @override
  String get todayLabel => 'اليوم';

  @override
  String get yesterdayLabel => 'أمس';

  @override
  String get earlierLabel => 'سابقاً';

  @override
  String get tapToView => 'اضغط للعرض';

  @override
  String get justNow => 'الآن';

  @override
  String get statListings => 'الإعلانات';

  @override
  String get statListingsSubtitle => 'الطلبات المنشورة';

  @override
  String get statOffers => 'العروض';

  @override
  String get statOffersSubtitle => 'العروض المقدمة';

  @override
  String get statMatches => 'التطابقات';

  @override
  String get statMatchesSubtitle => 'تطابقات ناجحة';

  @override
  String get trustReputation => 'الثقة والسمعة';

  @override
  String get subscription => 'الاشتراك';

  @override
  String get upgradeToPro => 'الترقية إلى Pro';

  @override
  String get viewPlansUpgrade => 'عرض الخطط والترقية';

  @override
  String get adminDashboard => 'لوحة تحكم المسؤول';

  @override
  String memberSince(String date) {
    return 'عضو منذ $date';
  }

  @override
  String get verified => 'موثق';

  @override
  String get districtNotSet => 'المنطقة غير محددة';

  @override
  String get nipanzeDisclaimer =>
      'Nipanze منصة وساطة غير حارسة. لا نحتجز أو ننقل أو نسوي الأموال. تتم جميع المعاملات مباشرة بين المشاركين.';

  @override
  String get lenderRequired => 'مستوى المقرض مطلوب';

  @override
  String get lenderRequiredSubtitle =>
      'تقديم العروض هو جزء من خطة المقرض (مضمنة أيضًا في Pro). قم بالترقية لفتح إمكانية تقديم العروض على أي إعلان.';

  @override
  String get lenderTier => 'مستوى المقرض';

  @override
  String get lenderTierDesc =>
      'لكل من هو مستعد لتقديم عروض مهيكلة وتحقيق عوائد على Nipanze.';

  @override
  String get everythingInFree => 'كل شيء في الخطة المجانية';

  @override
  String get lenderFeature1 =>
      'تقديم عروض بشروط كاملة (الفائدة، الرسوم، الجدول الزمني)';

  @override
  String get lenderFeature2 => 'عرض تفاصيل العرض حيث تشارك';

  @override
  String get chooseLender => 'اختيار المقرض';

  @override
  String get notNow => 'ليس الآن';

  @override
  String get paymentSecurityDisclaimer =>
      'Nipanze لا تحتجز ولا تنقل الأموال. يتم تأكيد تغييرات الاشتراك عبر تدفق دفع آمن.';

  @override
  String get proRequired => 'مستوى Pro مطلوب';

  @override
  String get proRequiredSubtitle =>
      'الميزات المتقدمة مثل اقتراحات الشروط المخصصة والتصفية المتقدمة مخصصة لمشتركي Pro.';

  @override
  String get proTier => 'مستوى Pro';

  @override
  String get proTierDesc =>
      'وصول كامل إلى السوق، تصفية متقدمة وتمركز أولوية للطلبات.';

  @override
  String get everythingInLender => 'كل شيء في خطة المقرض';

  @override
  String get proFeature1 => 'اقتراح الفوائد وغرامات التأخير وشروط السداد';

  @override
  String get proFeature2 => 'تصفية متقدمة (الدخل، التوظيف، الموثق)';

  @override
  String get proFeature3 => 'شارة موثقة، درجة موثوقية ورؤية ذات أولوية';

  @override
  String get choosePro => 'اختيار Pro';

  @override
  String get plansAndPricing => 'الخطط والأسعار';

  @override
  String get chooseAccessTitle => 'اختر مستوى الوصول الذي تحتاجه';

  @override
  String chooseAccessSubtitle(String flag, String country) {
    return 'يمكن لحساب واحد نشر الطلبات وتقديم العروض. تتطابق الأسعار مع منطقة حسابك ($flag $country).';
  }

  @override
  String get perMonth => ' / شهرياً';

  @override
  String get freePlanSubtitle =>
      'التصفح، متابعة الإعلانات، نشر الطلبات الأساسية، وقبول العروض.';

  @override
  String get freeFeature1 => 'تصفح السوق';

  @override
  String get freeFeature2 => 'نشر طلبات القروض الأساسية';

  @override
  String get freeFeature3 => 'قبول العروض المستلمة';

  @override
  String get currentPlan => 'الخطة الحالية';

  @override
  String get useFree => 'استخدام المجاني';

  @override
  String choosePlan(String plan) {
    return 'اختيار $plan';
  }

  @override
  String planSelectedMessage(String plan) {
    return 'تم اختيار $plan. ستتوفر عملية تفعيل الدفع الآمن قريبًا.';
  }

  @override
  String get unlockDealTitle => 'فتح الصفقة';

  @override
  String get unlockDealAndContact => 'فتح الصفقة وبيانات الاتصال';

  @override
  String get dealAgreementLocked => 'اتفاقية الصفقة مقفلة';

  @override
  String get dealAgreementLockedSubtitle =>
      'أكد كل من المقترض والمقرض الصفقة. يمكنك الآن فتح بيانات الاتصال للتواصل مباشرة.';

  @override
  String includedInPlan(String plan) {
    return 'مضمن في خطة $plan الخاصة بك';
  }

  @override
  String get unlimitedUnlocksSubtitle =>
      'فتح غير محدود لبيانات الاتصال بدون رسوم إضافية.';

  @override
  String welcomeGiftUnlocks(int count) {
    return '🎁 هدية الترحيب — $count فتح مجاني متبقي';
  }

  @override
  String get welcomeGiftSubtitle =>
      'تستخدم هذه الصفقة إحدى عمليات الفتح المجانية الخاصة بك. تكلفة عمليات الفتح الإضافية 5,000 شلن أوغندي.';

  @override
  String get unlockFeeApplies => 'تطبق رسوم فتح بقيمة 5,000 شلن أوغندي';

  @override
  String get unlockFeeAppliesSubtitle =>
      'تم استخدام فتح الترحيب الخاص بك. قم بالترقية إلى المقرض أو Pro للحصول على فتح مجاني غير محدود.';

  @override
  String get whatHappensNext => 'ماذا يحدث بعد ذلك';

  @override
  String get step1Title => 'الكشف عن بيانات الاتصال';

  @override
  String get step1Desc =>
      'سيتم مشاركة الاسم القانوني ورقم الهاتف والبريد الإلكتروني لكلا الطرفين.';

  @override
  String get step2Title => 'اتصال مباشر';

  @override
  String get step2Desc => 'يمكنك الآن الاتصال بشريكك خارج منصة Nipanze.';

  @override
  String get step3Title => 'إكمال المعاملة';

  @override
  String get step3Desc => 'إتمام اتفاقية القروض وتبادل الأموال مباشرة.';

  @override
  String get disclaimerNonCustodial =>
      'Nipanze لا تحتجز ولا تنقل أي أموال. أنت وشريكك مسؤولان بشكل كامل عن جميع المعاملات المالية وحل النزاعات.';

  @override
  String get payToUnlock => 'دفع 5,000 شلن للفتح';

  @override
  String get unlockWithFreeCredit => 'الفتح باستخدام الرصيد المجاني';

  @override
  String get unlockContactDetails => 'فتح بيانات الاتصال';

  @override
  String get upgradeForUnlimited => 'الترقية للحصول على فتح غير محدود';

  @override
  String get contactDetailsRevealed => 'تم الكشف عن بيانات الاتصال';

  @override
  String get connectionSuccessful => 'تم الاتصال بنجاح. إليك بيانات الاتصال:';

  @override
  String get borrower => 'المقترض';

  @override
  String get lender => 'المقرض';

  @override
  String get directContactNotice =>
      'يمكنك الآن الاتصال بشريكك مباشرة لإكمال المعاملة خارج منصة Nipanze.';

  @override
  String get done => 'تم';

  @override
  String planTitle(String plan) {
    return 'خطة $plan';
  }

  @override
  String get nonCustodialAccess => 'وصول غير حارسي';

  @override
  String get howTrustWorks => 'كيف تعمل الثقة';

  @override
  String get trustExplanation =>
      'تعكس مؤشرات الثقة فقط النشاط المكتمل من خلال Nipanze. ولا تقيم أو تضمن سلوك السداد خارج المنصة.';

  @override
  String get trustScore => 'درجة الثقة';

  @override
  String get completeDealsToBuild => 'أكمل الصفقات لبناء درجتك';

  @override
  String get noReviewsYet => 'لا توجد تقييمات بعد';

  @override
  String successfulDeals(int count) {
    return '$count صفقات ناجحة';
  }

  @override
  String get repeatParticipant => 'مشارك مكرر';

  @override
  String get notRepeatYet => 'ليس مشاركًا مكررًا بعد';

  @override
  String get phoneVerified => 'الهاتف موثق';

  @override
  String get phoneNotVerified => 'الهاتف غير موثق';

  @override
  String get publicTrustSignals =>
      'تستند مؤشرات الثقة العامة فقط إلى النشاط المكتمل عبر Nipanze.';

  @override
  String get advancedFilters => 'فلاتر متقدمة';

  @override
  String get advancedFiltersBadge => 'Pro · تضييق نطاق بحثك';

  @override
  String get filterReset => 'إعادة ضبط';

  @override
  String get filterClear => 'مسح';

  @override
  String get filterApply => 'تطبيق الفلاتر';

  @override
  String get filterDone => 'تم';

  @override
  String get filterEmploymentType => 'نوع العمل';

  @override
  String get filterEmploymentSubtitle => 'التصفية حسب التوظيف المُعلن للمقترض';

  @override
  String get filterIncomeRange => 'نطاق الدخل الشهري';

  @override
  String get filterIncomeSubtitle =>
      'شرائح تقريبية — الدخل الدقيق لا يُظهر أبداً';

  @override
  String get filterQualitySignals => 'مؤشرات جودة الإعلان';

  @override
  String get filterHasSuggestedTerms => 'يحتوي على شروط مقترحة';

  @override
  String get filterHasSuggestedTermsSubtitle =>
      'فقط الإعلانات التي تحتوي على نسبة فائدة ثابتة وغرامات تأخير وجدول سداد';

  @override
  String get filterVerifiedBorrower => 'مقترض موثق';

  @override
  String get filterVerifiedBorrowerSubtitle =>
      'فقط الطلبات من أصحاب الحسابات الموثقة عبر KYC';

  @override
  String get filterPrivacyNote =>
      'لا تُظهر أسماء جهات العمل أو الدخل الدقيق أبداً. الشرائح الدخلية وفئات التوظيف هي الإشارات الوحيدة المتاحة، بتصميم مقصود.';

  @override
  String get empGovEmployee => 'موظف حكومي';

  @override
  String get empEmployedPrivate => 'موظف (خاص)';

  @override
  String get empSelfEmployed => 'عامل حر';

  @override
  String get empSmallBusinessOwner => 'صاحب مشروع صغير';

  @override
  String get empBusinessOwner => 'صاحب عمل';

  @override
  String get empStudent => 'طالب';

  @override
  String get empOther => 'أخرى';

  @override
  String get incomeUnder2m => 'أقل من 2 مليون UGX / شهر';

  @override
  String get income2m5m => '2 – 5 مليون UGX / شهر';

  @override
  String get income5m10m => '5 – 10 مليون UGX / شهر';

  @override
  String get incomeOver10m => 'أكثر من 10 مليون UGX / شهر';

  @override
  String get iHold => 'لدي';

  @override
  String get rate => 'سعر الصرف';

  @override
  String get iNeed => 'أحتاج';

  @override
  String get marketRate => 'سعر السوق';

  @override
  String get stepIncomeRepayment => 'الدخل والسداد';

  @override
  String get stepReviewPublish => 'المراجعة والنشر';

  @override
  String get requestALoan => 'طلب قروض';

  @override
  String stepCounter(int current, int total, String subtitle) {
    return 'الخطوة $current من $total · $subtitle';
  }

  @override
  String get subtitleLoanDetails => 'تفاصيل القرض';

  @override
  String get subtitleRepaymentContext => 'سياق السداد';

  @override
  String get subtitleReview => 'مراجعة';

  @override
  String get panelTheBasics => 'الأساسيات';

  @override
  String get panelTheNumbers => 'الأرقام';

  @override
  String get panelLocationDetails => 'الموقع والتفاصيل';

  @override
  String get panelRepaymentSource => 'مصدر السداد';

  @override
  String get panelAbilityToRepay => 'القدرة على السداد';

  @override
  String get panelPreferredTerms => 'الشروط المفضلة';

  @override
  String get requestTitleLabel => 'عنوان الطلب';

  @override
  String get requestTitleHint => 'مثال: شاحنة توصيل لخط كامبالا';

  @override
  String get purposeLabel => 'الغرض';

  @override
  String get selectPurposeHint => 'اختر الغرض';

  @override
  String get describePurposeLabel => 'صف غرضك';

  @override
  String amountLabelWithCurrency(String currency) {
    return 'المبلغ ($currency)';
  }

  @override
  String get amountHintLoan => '7,000,000';

  @override
  String get durationLabel => 'المدة';

  @override
  String get durationHintMonths => '6 أشهر';

  @override
  String get descriptionOptionalLabel => 'الوصف (اختياري)';

  @override
  String get descriptionOptionalHint => 'أضف أي تفاصيل يفضل أن يعلمها المقرضون';

  @override
  String get incomeSourceLabel => 'مصدر الدخل';

  @override
  String get incomeSourceHint => 'مثال: راتب، دخل متجر، زراعة، عمل إضافي';

  @override
  String get preferredRepaymentPlanLabel => 'خطة السداد المفضلة';

  @override
  String get selectRepaymentPlanHint => 'اختر خطة السداد';

  @override
  String repaymentAmountPerPeriodLabel(String currency) {
    return 'مبلغ السداد لكل فترة ($currency)';
  }

  @override
  String get repaymentAmountHint => 'مثال: 250,000';

  @override
  String get repaymentTimelineLabel => 'الجدول والوقت المحدد للسداد';

  @override
  String get repaymentTimelineHint =>
      'مثال: يدفع بحلول اليوم الخامس من كل شهر الساعة 5:00 مساءً لمدة 8 أشهر';

  @override
  String get dueDayLabel => 'يوم الاستحقاق / التكرار';

  @override
  String get dueDayHint => 'اختر يوم الاستحقاق (مثال: اليوم الخامس من كل شهر)';

  @override
  String get dueCutoffTimeLabel =>
      'الوقت النهائي للاستحقاق (لحساب رسوم التأخير)';

  @override
  String get dueCutoffTimeHint => 'اختر الوقت النهائي (مثال: 5:00 مساءً)';

  @override
  String get timelineHelperText =>
      'اليوم والوقت الدقيق المستخدمان لحساب رسوم التأخير';

  @override
  String get suggestedInterestRateLabel => 'سعر الفائدة المقترح (%)';

  @override
  String get suggestedLateFeeLabel => 'رسوم التأخير المقترحة (%)';

  @override
  String get suggestedRepaymentScheduleLabel => 'جدول السداد المقترح';

  @override
  String suggestedInstallmentAmountLabel(String currency) {
    return 'مبلغ القسط المقترح ($currency)';
  }

  @override
  String get validationTitleRequired => 'أدخل عنواناً';

  @override
  String get validationTitleMinLength => 'استخدم 4 أحرف على الأقل';

  @override
  String get validationPurposeRequired => 'اختر غرضاً';

  @override
  String get validationPurposeContinue => 'اختر غرضاً للمتابعة.';

  @override
  String get validationAmountRequired => 'أدخل مبلغا';

  @override
  String get validationValidNumber => 'أدخل رقماً صالباً';

  @override
  String validationMinAmount(String currency, String min) {
    return 'الحد الأدنى $currency $min';
  }

  @override
  String validationMaxAmount(String currency, String max) {
    return 'الحد الأقصى $currency $max';
  }

  @override
  String get validationDurationRequired => 'أدخل المدة';

  @override
  String get validationDurationRange => 'من 1 إلى 60 شهراً';

  @override
  String get validationIncomeSourceRequired => 'أدخل مصدر السداد الخاص بك';

  @override
  String get validationIncomeSourceDetail => 'أضف المزيد من التفاصيل';

  @override
  String get validationRepaymentPlanRequired => 'اختر خطة السداد';

  @override
  String get validationRepaymentPlanContinue => 'اختر خطة السداد للمتابعة.';

  @override
  String get validationRepaymentAmountRequired => 'أدخل مبلغ السداد';

  @override
  String get validationRepaymentAmountValid => 'أدخل مبلغا صالباً';

  @override
  String get validationRepaymentTimelineRequired => 'أدخل الجدول الزمني للسداد';

  @override
  String get validationRepaymentTimelineDetail =>
      'أضف جدولاً زمنيًا أكثر وضوحًا';

  @override
  String get validationPercentRange => 'استخدم من 0 إلى 100';

  @override
  String get btnContinue => 'متابعة';

  @override
  String get btnPublishToMarketplace => 'النشر في السوق';

  @override
  String get btnBack => 'رجوع';

  @override
  String get reviewYourRequest => 'راجع طلبك';

  @override
  String get reviewConfirmDetails => 'تأكد من التفاصيل قبل النشر في السوق.';

  @override
  String get reviewTitle => 'العنوان';

  @override
  String get reviewAmount => 'المبلغ';

  @override
  String get reviewDuration => 'المدة';

  @override
  String get reviewPurpose => 'الغرض';

  @override
  String get reviewIncomeSource => 'مصدر الدخل';

  @override
  String get reviewPreferredRepaymentPlan => 'خطة السداد المفضلة';

  @override
  String get reviewRepaymentAmount => 'مبلغ السداد';

  @override
  String get reviewRepaymentTimeline => 'الجدول الزمني للسداد';

  @override
  String get reviewDescription => 'الوصف';

  @override
  String get reviewLockedTerms => 'الشروط المفضلة المقفلة';

  @override
  String get reviewPerPeriod => 'لكل فترة';

  @override
  String get reviewContactPrivacyNotice =>
      'تبقى تفاصيل الاتصال بك مخفية حتى قبول العرض وإكمال عملية الفتح.';

  @override
  String get requestSubmittedTitle => 'تم تقديم الطلب';

  @override
  String get requestSubmittedContent =>
      'طلب القرض الخاص بك متاح الآن في السوق. يمكن للمقرضين مراجعته وتقديم العروض.';

  @override
  String get couldNotPublishRequest => 'تعذر نشر هذا الطلب. حاول مرة أخرى.';

  @override
  String get kycGateListing => 'أكمل التحقق من الهوية KYC قبل نشر العرض.';

  @override
  String get notAllowedListing => 'حسابك غير مصرح له بنشر عرض.';

  @override
  String infoBannerText(String currency, String min, String max) {
    return '$currency $min-$max · حتى 60 شهراً · تُقفل الشروط عند النشر';
  }

  @override
  String get termsLockedNotice => 'مقفل عند نشر الطلب.';

  @override
  String get upgradeToProForTerms =>
      'ترقية إلى Pro لاقتراح الفائدة ورسوم التأخير وشروط السداد.';

  @override
  String get purposeAgri => 'معدات زراعية';

  @override
  String get purposeBusiness => 'توسيع الأعمال';

  @override
  String get purposeEdu => 'التعليم / الرسوم الدراسية';

  @override
  String get purposeMedical => 'طوارئ طبية';

  @override
  String get purposeFarming => 'زراعة / بيت زجاجي';

  @override
  String get purposeHome => 'تحسين المنزل';

  @override
  String get purposeStock => 'المخزون / البضائع';

  @override
  String get purposeLand => 'شراء أرض';

  @override
  String get purposeLivestock => 'المواشي';

  @override
  String get purposeEnergy => 'طاقة شمسية / طاقة';

  @override
  String get purposeVehicle => 'نقل / مركبة';

  @override
  String get purposeWater => 'المياه والصرف الصحي';

  @override
  String get purposeWedding => 'زفاف / مناسبة';

  @override
  String get purposeOther => 'أخرى';

  @override
  String get planMonthly => 'شهري';

  @override
  String get planWeekly => 'أسبوعي';

  @override
  String get planOneTime => 'دفعة واحدة';

  @override
  String get createForexRequestTitle => 'إنشاء طلب عملات';

  @override
  String get forexCurrencyHeld => 'العملة التي تمتلكها';

  @override
  String get forexCurrencyNeeded => 'العملة التي تحتاجها';

  @override
  String get forexAmountToExchange => 'المبلغ المراد تبادله';

  @override
  String get forexAmountHint => 'مثال: 100';

  @override
  String get forexPreferredRate => 'سعر الصرف المفضل';

  @override
  String get forexRateHint => 'مثال: 3700';

  @override
  String get forexSettlementPreference => 'تفضيل التسوية';

  @override
  String get selectSettlementHint => 'اختر التسوية';

  @override
  String get forexPublishBtn => 'نشر طلب العملات';

  @override
  String get kycGateForex => 'أكمل التحقق من الهوية KYC قبل نشر طلب العملات.';

  @override
  String get couldNotPublishForex => 'تعذر نشر طلب العملات هذا.';

  @override
  String get forexSettlementInPerson => 'شخصياً';

  @override
  String get forexSettlementMobileMoney => 'محفظة إلكترونية';

  @override
  String get forexSettlementBankTransfer => 'تحويل بنكي';

  @override
  String get forexSettlementOther => 'أخرى';

  @override
  String get forexRequestTitle => 'طلب عملات';

  @override
  String get myForexRequestsTitle => 'طلبات العملات الخاصة بي';

  @override
  String get noForexRequestsYet => 'لا توجد طلبات عملات حتى الآن.';

  @override
  String get listingDetailTitle => 'تفاصيل الإعلان';

  @override
  String get offersLabel => 'العروض';

  @override
  String get loanRequestTitle => 'طلب قرض';

  @override
  String get makeAnOffer => 'قدّم عرضاً';

  @override
  String get makeAnOfferToUnlock => 'قدّم عرضاً للاطلاع على كافة التفاصيل';

  @override
  String get onlyYourOfferVisible =>
      'يظهر عرضك فقط هنا. سجل العروض الكامل ظاهر للمقترض.';

  @override
  String get securedCollateralLabel => 'مضمون';

  @override
  String get noCollateralLabel => 'لا يوجد ضمان';

  @override
  String get hasCollateralLabel => 'يوجد ضمان';

  @override
  String get collateralLabel => 'الضمان';

  @override
  String get collateralPromptText => 'اختر ما إذا كان هذا الطلب مدعومًا بأصل.';

  @override
  String get collateralDetailsLabel => 'تفاصيل الضمان';

  @override
  String get collateralDetailsHint =>
      'مثل: سند ملكية، سيارة، إلكترونيات، معدات';

  @override
  String get collateralAssetRequired => 'صف أصل الضمان';

  @override
  String get collateralAssetDetailShort => 'أضف مزيدًا من التفاصيل';

  @override
  String collateralValueLabel(String currency) {
    return 'القيمة التقريبية ($currency)';
  }

  @override
  String get estimatedValueLabel => 'القيمة التقديرية';

  @override
  String get locationLabel => 'الموقع';

  @override
  String get offerSubmittedReviewNotice =>
      'تم إرسال العرض. يمكنك مراجعته أعلاه.';

  @override
  String offerCountdownLabel(String time) {
    return 'متبقٍ $time';
  }

  @override
  String get expiredLabel => 'منتهي';

  @override
  String get offerSentSuccessfully => 'تم إرسال العرض بنجاح.';

  @override
  String get interestRateLabel => 'معدل الفائدة (%)';

  @override
  String get latePaymentFeeLabel => 'رسوم التأخير (%)';

  @override
  String get repaymentScheduleLabel => 'جدول السداد';

  @override
  String get monthly => 'شهرياً';

  @override
  String get weekly => 'أسبوعياً';

  @override
  String get oneTimePayment => 'دفعة واحدة';

  @override
  String installmentAmountLabel(String currency) {
    return 'قيمة القسط ($currency)';
  }

  @override
  String get additionalExpectationsLabel => 'توقعات إضافية';

  @override
  String get optionalBorrowerNotesHint => 'ملاحظات اختيارية للمقترض';

  @override
  String get sendOffer => 'إرسال العرض';

  @override
  String get couldNotSendOffer => 'تعذّر إرسال العرض.';

  @override
  String get rateOfferedLabel => 'السعر المقترح';

  @override
  String get amountAvailableLabel => 'المبلغ المتاح';

  @override
  String get forexAmountToServe => 'المبلغ المراد تقديمه';

  @override
  String get forexServesLabel => 'يخدم';

  @override
  String get amountToExchangeOut => 'المبلغ المراد تحويله';

  @override
  String get settlementTermsLabel => 'شروط التسوية';

  @override
  String get activeListingLabel => 'طلب نشط';

  @override
  String get fundedLabel => 'ممول';

  @override
  String userVerificationStatus(String status) {
    return 'حالة تحقق المستخدم: $status';
  }

  @override
  String interestPercent(String value) {
    return 'فائدة $value%';
  }

  @override
  String get proposedRepaymentPlanLabel => 'خطة السداد المقترحة';

  @override
  String get yourOfferLabel => 'عرضك';

  @override
  String lenderNumberLabel(int number) {
    return 'المقرض #$number';
  }

  @override
  String lenderTextLabel(String id) {
    return 'المقرض #$id';
  }

  @override
  String get fullOfferLabel => 'عرض كامل';

  @override
  String partialOfferLabel(int coverage) {
    return 'جزئي · $coverage%';
  }

  @override
  String vsAskLabel(String value) {
    return '$value مقارنة بالطلب';
  }

  @override
  String get lenderNotesLabel => 'ملاحظات المقرض';

  @override
  String get acceptOfferLabel => 'قبول العرض';

  @override
  String get fullCoverageOfferLabel => 'عرض تغطية كاملة';

  @override
  String partialCoverageLabel(int coverage) {
    return 'تغطية جزئية · $coverage%';
  }

  @override
  String totalPayablePaymentsLabel(int periods) {
    return 'إجمالي السداد ($periods دفعات)';
  }

  @override
  String borrowingCostLabel(String amount) {
    return 'تكلفة الاقتراض: $amount';
  }

  @override
  String get flutterwaveCheckoutTitle => 'الدفع عبر فلوترفيلف';

  @override
  String get orderSummary => 'ملخص الطلب';

  @override
  String get paymentMethod => 'طريقة الدفع';

  @override
  String get mobileMoney => 'محفظة جوال (Mobile Money)';

  @override
  String get creditOrDebitCard => 'بطاقة ائتمان / مدى';

  @override
  String get phoneOrAccount => 'رقم الهاتف / الحساب';

  @override
  String get enterMobileNumber => 'أدخل رقم محفظة الجوال';

  @override
  String get payWithFlutterwave => 'ادفع بواسطة Flutterwave';

  @override
  String get processingPayment => 'جاري معالجة الدفع عبر Flutterwave…';

  @override
  String get paymentSuccessful => 'تم الدفع بنجاح!';

  @override
  String subscriptionActivated(Object plan) {
    return 'اشتراكك في باقة $plan أصبح نشطاً الآن.';
  }

  @override
  String get paymentFailed => 'فشلت عملية الدفع. يرجى المحاولة مرة أخرى.';

  @override
  String get paymentStep1 => 'التفاصيل';

  @override
  String get paymentStep2 => 'المعالجة';

  @override
  String get paymentStep3 => 'تم';

  @override
  String get paymentProcessingStep1 => 'الاتصال بـ Flutterwave…';

  @override
  String get paymentProcessingStep2 => 'التحقق من الدفع…';

  @override
  String get paymentProcessingStep3 => 'تفعيل الاشتراك…';

  @override
  String transactionRef(String ref) {
    return 'المرجع: $ref';
  }

  @override
  String get poweredByFlutterwave => 'مدعوم من Flutterwave';

  @override
  String enterMobileNumberForProvider(String provider) {
    return 'رقم هاتف $provider';
  }

  @override
  String mobileMoneyPromptHint(String provider) {
    return 'ستتلقى إشعارًا من $provider على هاتفك لتأكيد الدفع.';
  }

  @override
  String get prefilledFromAccount => 'تم التعبئة تلقائيًا من حسابك';

  @override
  String get editPhoneNumber => 'تعديل';

  @override
  String get lockPhoneNumber => 'قفل';

  @override
  String get liveCalcTitle => 'تفاصيل السداد';

  @override
  String get liveCalcLoanAmount => 'مبلغ القرض';

  @override
  String get liveCalcPlan => 'خطة السداد';

  @override
  String get liveCalcDuration => 'المدة';

  @override
  String get liveCalcInstallment => 'القسط لكل فترة';

  @override
  String get liveCalcTotalPayments => 'إجمالي المدفوعات';

  @override
  String get liveCalcTotalPayback => 'إجمالي السداد';

  @override
  String get liveCalcBorrowingCost => 'تكلفة الاقتراض';

  @override
  String get liveCalcNoData => 'أكمل الحقول أعلاه لعرض تفاصيل السداد.';

  @override
  String get freeTermsBanner =>
      'اتركه فارغًا — سيقترح المُقرضون شروطهم. ترقّ إلى Pro لاقتراح النسب.';

  @override
  String get offerReadOnlyNotice =>
      'راجع الشروط المقترحة من المُقرض أدناه. اقبل أو انتظر عرضًا أفضل.';

  @override
  String get sponsoredLabel => 'ممول';

  @override
  String get borrowerTermsMissing => '—';

  @override
  String get repaymentCalcFormula => 'القسط × عدد المدفوعات = إجمالي السداد';

  @override
  String liveCalcWeeklyNote(int months, int count) {
    return 'خطة أسبوعية: $months أشهر × 4 = $count دفعة';
  }

  @override
  String liveCalcMonthlyNote(int count) {
    return '$count دفعة شهرية';
  }

  @override
  String get liveCalcOneTimeNote => 'دفعة واحدة';

  @override
  String get kycGateTitle => 'تأكيد الهوية أولاً';

  @override
  String get kycGateBody =>
      'لإرسال طلبات القروض أو العملات الأجنبية والتواصل مع المُقرضين، يلزم إكمال التحقق من الهوية. يستغرق ذلك بضع دقائق فقط.';

  @override
  String get kycGatePendingTitle => 'التحقق قيد المراجعة';

  @override
  String get kycGatePendingBody =>
      'مستندات الهوية الخاصة بك قيد المراجعة حاليًا. سيتم إخطارك بمجرد الموافقة على حسابك.';

  @override
  String get kycGateRejectedTitle => 'تم رفض التحقق';

  @override
  String get kycGateRejectedBody =>
      'لم يتم تقديم الموافقة على مستندات KYC الخاصة بك. يُرجى إعادة التقديم بمستندات صالحة.';

  @override
  String get kycGateExpiredTitle => 'انتهت صلاحية التحقق';

  @override
  String get kycGateExpiredBody =>
      'انتهت صلاحية التحقق من الهوية الخاصة بك. يُرجى إعادة التقديم لمتابعة نشر الطلبات.';

  @override
  String get kycStep1 => 'قدّم بطاقة الهوية الوطنية أو جواز السفر';

  @override
  String get kycStep2 => 'انتظر المراجعة (عادةً خلال 24 ساعة)';

  @override
  String get kycStep3 => 'أنشئ طلباتك بمجرد الموافقة';

  @override
  String get kycGateCta => 'بدء التحقق';

  @override
  String get kycGateResubmitCta => 'إعادة تقديم التحقق';

  @override
  String get kycPageTitle => 'التحقق من الهوية';

  @override
  String get kycStatusApproved => 'تمت الموافقة على KYC';

  @override
  String get kycStatusApprovedDesc =>
      'تم التحقق من الهوية. يمكنك الآن إنشاء الإعلانات.';

  @override
  String get kycStatusPending => 'قيد المراجعة';

  @override
  String get kycStatusPendingDesc => 'تم تقديم المستندات. مراجعة المشرف جارية.';

  @override
  String get kycStatusRejected => 'مرفوض';

  @override
  String get kycStatusRejectedDesc =>
      'تم رفض الطلب. يُرجى إعادة الرفع وإعادة التقديم.';

  @override
  String get kycStatusExpired => 'منتهية الصلاحية';

  @override
  String get kycStatusExpiredDesc =>
      'انتهت صلاحية KYC الخاص بك. يُرجى إعادة التحقق.';

  @override
  String get kycStatusNotSubmitted => 'لم يُقدَّم';

  @override
  String get kycStatusNotSubmittedDesc =>
      'قدّم مستنداتك لفتح إمكانية إنشاء الإعلانات.';

  @override
  String get kycRejectionReason => 'سبب الرفض';

  @override
  String get kycIdentityVerified => 'تم التحقق من الهوية';

  @override
  String kycExpires(String date) {
    return 'ينتهي في $date';
  }

  @override
  String get kycPendingNotice =>
      'تم تقديم المستندات — مراجعة المشرف جارية. يستغرق هذا عادةً من 1 إلى 2 يوم عمل.';

  @override
  String get kycRequiredDocs => 'المستندات المطلوبة';

  @override
  String get kycRequiredDocsSubtitle =>
      'ارفع صوراً واضحة وجيدة الإضاءة. جميع المستندات مخزّنة بأمان.';

  @override
  String get kycDocNationalIdFront => 'بطاقة الهوية الوطنية — الوجه الأمامي';

  @override
  String get kycDocNationalIdFrontSubtitle =>
      'صورة واضحة للوجه الأمامي لبطاقة هويتك الوطنية الأوغندية';

  @override
  String get kycDocNationalIdBack => 'بطاقة الهوية الوطنية — الوجه الخلفي';

  @override
  String get kycDocNationalIdBackSubtitle =>
      'صورة واضحة للوجه الخلفي لبطاقة هويتك الوطنية';

  @override
  String get kycDocSelfie => 'صورة سيلفي مع الهوية';

  @override
  String get kycDocSelfieSubtitle => 'أمسك بطاقة هويتك الوطنية بجانب وجهك';

  @override
  String get kycDocUploadedTapReplace => 'تم الرفع — اضغط للاستبدال';

  @override
  String get kycDocUploadedUnderReview => 'تم الرفع — قيد المراجعة';

  @override
  String get kycPrivacyNote =>
      'لا تُعرض هويتك أبداً على المشاركين الآخرين في السوق. يراجع المستندات مشرفو Nipanze فقط.';

  @override
  String get kycSubmitForReview => 'إرسال للمراجعة';

  @override
  String get kycUploadAllDocs => 'ارفع الوثائق الثلاث لتفعيل التقديم.';

  @override
  String get kycChooseSource => 'اختر المصدر';

  @override
  String get kycSourceCamera => 'الكاميرا';

  @override
  String get kycSourceLibrary => 'مكتبة الصور';

  @override
  String get kycDismiss => 'تجاهل';

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
  String get privacyAndVisibility => 'الخصوصية والرؤية';

  @override
  String get blockedUsers => 'المستخدمون المحظورون';

  @override
  String get blockUser => 'حظر المستخدم';

  @override
  String get blockUserConfirmTitle => 'حظر هذا المستخدم؟';

  @override
  String get blockUserConfirmBody =>
      'لن يتمكنوا بعد الآن من رؤية طلبات القروض أو العملات المستقبلية الخاصة بك أو التفاعل معها.';

  @override
  String get block => 'حظر';

  @override
  String get unblock => 'إلغاء الحظر';

  @override
  String get unblockUserConfirmTitle => 'إلغاء حظر هذا المستخدم؟';

  @override
  String get unblockUserConfirmBody =>
      'ستنطبق قواعد رؤية السوق العادية مرة أخرى.';

  @override
  String get userBlocked => 'تم حظر المستخدم.';

  @override
  String get userUnblocked => 'تم إلغاء حظر المستخدم.';

  @override
  String get noBlockedUsers => 'لا يوجد مستخدمون محظورون';

  @override
  String get noBlockedUsersSubtitle => 'الأشخاص الذين تحظرهم سيظهرون هنا.';

  @override
  String blockedOnDate(String date) {
    return 'تم الحظر في $date';
  }
}
