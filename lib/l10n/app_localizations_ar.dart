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
  String get welcomeSubtitle => 'سوقك الموثوق مع مقدمي خدمات موثوقين.';

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
  String get navPositions => 'النشاط';

  @override
  String get navAccount => 'الحساب';

  @override
  String get marketplaceTitle => 'Nipanze';

  @override
  String listingsLive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count إعلان نشط',
      many: '$count إعلانًا نشطًا',
      few: '$count إعلانات نشطة',
      two: '$count إعلانان نشطان',
      one: '$count إعلان نشط',
      zero: '$count إعلان نشط',
    );
    return '$_temp0';
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
  String get listingExpiryTitle => 'انتهاء الإعلان';

  @override
  String get listingExpiryTooltip => 'عرض الوقت المتبقي';

  @override
  String listingRemainingDaysHours(int days, int hours) {
    return 'متبقي $days يوم و$hours ساعة';
  }

  @override
  String listingRemainingHoursMinutes(int hours, int minutes) {
    return 'متبقي $hours ساعة و$minutes دقيقة';
  }

  @override
  String listingRemainingMinutes(int minutes) {
    return 'متبقي $minutes دقيقة';
  }

  @override
  String listingRemainingSeconds(int seconds) {
    return 'متبقي $seconds ثانية';
  }

  @override
  String get openToOffers => 'مفتوح لتلقي العروض';

  @override
  String get marketplaceForYou => 'من أجلك';

  @override
  String get marketplaceAll => 'الكل';

  @override
  String get marketplaceLoan => 'قرض';

  @override
  String get marketplaceLoans => 'القروض';

  @override
  String get marketplaceForex => 'الفوركس';

  @override
  String get marketplaceNeeds => 'الاحتياجات';

  @override
  String get marketplaceNeeded => 'مطلوب';

  @override
  String get declareCapabilityToBidTitle => 'Service Capability Required';

  @override
  String get declareCapabilityToBidMessage =>
      'To submit an offer on this request, you must first declare that you offer services in this category.';

  @override
  String get declareServiceNow => 'Add Service & Continue';

  @override
  String get postServiceAction => 'قدّم خدمة';

  @override
  String get postServiceSubtitle =>
      'اعرض خدماتك وتواصل مع العملاء الباحثين عنها';

  @override
  String get viewDetails => 'عرض التفاصيل';

  @override
  String get proAdvancedFilters => 'فلاتر Pro المتقدمة';

  @override
  String get today => 'اليوم';

  @override
  String get weekAgo => 'منذ أسبوع واحد';

  @override
  String daysAgo(int count) {
    return 'منذ $count أيام';
  }

  @override
  String weeksAgo(int count) {
    return 'منذ $count أسابيع';
  }

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
  String get tryAgain => 'إعادة المحاولة';

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
  String get tabDeals => 'الصفقات';

  @override
  String get noDealsYet => 'لا توجد صفقات بعد';

  @override
  String get noDealsSubtitle =>
      'عند قبول عرض من قبلك أو من شريكك، ستظهر صفقاتك وعقودك النشطة هنا.';

  @override
  String get noOffersYet => 'لا توجد عروض بعد';

  @override
  String get noOffersSubtitle =>
      'العروض التي تضعها على إعلانات السوق ستظهر هنا.';

  @override
  String get browseMarketplaceBtn => 'تصفح';

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
  String get noRequests => 'لا توجد طلبات بعد';

  @override
  String get noRequestsSubtitle =>
      'انشر طلباً واستقبل عروضاً من مقدمي الخدمات القادرين على مساعدتك.';

  @override
  String get createRequest => 'إنشاء طلب';

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
  String get choosePhoto => 'اختر صورة';

  @override
  String get selectPhotoSource => 'حدد مكان اختيار صورة ملفك الشخصي';

  @override
  String get takePhoto => 'التقاط صورة';

  @override
  String get useCamera => 'استخدم الكاميرا الخاصة بك';

  @override
  String get chooseFromGallery => 'اختر من معرض الصور';

  @override
  String get pickExistingPhoto => 'اختر صورة حالية';

  @override
  String get removePhoto => 'إزالة الصورة';

  @override
  String get removePhotoSubtitle => 'حذف صورة الملف الشخصي الحالية';

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
  String get perMonth => 'شهر';

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
  String get needDetailTitle => 'تفاصيل الطلب';

  @override
  String get termLabel => 'المدة';

  @override
  String get loanTypeLabel => 'نوع القرض';

  @override
  String get aboutRequest => 'حول الطلب';

  @override
  String get notSpecified => 'غير محدد';

  @override
  String get verifiedRequester => 'مقدم طلب موثّق';

  @override
  String get timelineLabel => 'الجدول الزمني';

  @override
  String get trustLabel => 'الثقة';

  @override
  String get categoryDetailsLabel => 'تفاصيل الفئة';

  @override
  String get aboutNeedLabel => 'حول الحاجة';

  @override
  String get forexHoldLabel => 'لدي';

  @override
  String get forexNeedLabel => 'أحتاج';

  @override
  String get nearbyLabel => 'بالقرب';

  @override
  String get flexibleLabel => 'مرن';

  @override
  String offersCount(int count) {
    return '$count عروض';
  }

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
  String get totalAmountPayableLabel => 'المبلغ الإجمالي المستحق';

  @override
  String get totalInterestLabel => 'إجمالي الفائدة';

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
  String get providerVerificationRequiredTitle => 'يلزم التحقق من مقدم الخدمة';

  @override
  String get providerVerificationRequiredDesc =>
      'أكمل التحقق من مقدم الخدمة قبل تقديم الخدمات ضمن هذه الفئة.';

  @override
  String get identityVerificationRequiredTitle => 'يلزم التحقق من الهوية';

  @override
  String get identityVerificationRequiredDesc =>
      'تحقق من هويتك قبل النشر أو تقديم الخدمات على Nipanze.';

  @override
  String get startProviderVerificationBtn => 'بدء التحقق من مقدم الخدمة';

  @override
  String get verifyIdentityBtn => 'التحقق من الهوية';

  @override
  String get maybeLaterBtn => 'ربما لاحقًا';

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
  String get kycUploadAllDocs =>
      'ارفع صورة الملف الشخصي وجميع الوثائق المطلوبة لتفعيل التقديم.';

  @override
  String get kycChooseSource => 'اختر المصدر';

  @override
  String get kycSourceCamera => 'الكاميرا';

  @override
  String get kycSourceLibrary => 'مكتبة الصور';

  @override
  String get kycDismiss => 'تجاهل';

  @override
  String get referAndEarn => 'الإحالة والمكافأة';

  @override
  String get yourReferralCode => 'رمز الإحالة الخاص بك';

  @override
  String get enterCode => 'أدخل الرمز';

  @override
  String get shareLink => 'مشاركة الرابط';

  @override
  String get copyCode => 'نسخ الرمز';

  @override
  String get enterReferralCode => 'أدخل رمز الإحالة';

  @override
  String get referralCodeSubtitle =>
      'إذا قام صديق بدعوتك إلى Nipanze، أدخل رمز إحالة هنا أدناه.';

  @override
  String get referralCodeHint => 'مثال: JOHN1234';

  @override
  String get referralCodeLabel => 'رمز الإحالة';

  @override
  String get applyCode => 'تطبيق الرمز';

  @override
  String get totalReferrals => 'إجمالي الإحالات';

  @override
  String get registered => 'المسجلون';

  @override
  String get qualified => 'المؤهلون';

  @override
  String get pendingRewards => 'المكافآت المعلقة';

  @override
  String get availableRewards => 'المكافآت المتاحة';

  @override
  String get totalEarned => 'إجمالي ما تمكنا من كسبه';

  @override
  String get totalPaid => 'إجمالي ما تم دفعه';

  @override
  String get referralHistory => 'سجل الإحالات';

  @override
  String get noReferralsYet => 'لا توجد إحالات بعد';

  @override
  String get noReferralsSubtitle => 'ستظهر الإحالات المشتركة هنا بعد التسجيل.';

  @override
  String get referralCodeCopied => 'تم نسخ رمز الإحالة';

  @override
  String get referralCodeApplied => 'تم تطبيق رمز الإحالة بنجاح!';

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

  @override
  String get invitePeopleAndTrackRewards => 'دعوة الأشخاص ومتابعة المكافآت';

  @override
  String get codeGenerating => 'جاري إنشاء الرمز الخاص بك…';

  @override
  String get inviteEarnDescription =>
      'ادعُ الأشخاص إلى Nipanze واكسب المكافآت عند إكمالهم الإجراءات المطلوبة.';

  @override
  String get stepShare => 'مشاركة';

  @override
  String get stepSignUp => 'تسجيل';

  @override
  String get stepVerify => 'تحقق';

  @override
  String get stepQualify => 'تأهيل';

  @override
  String get stepEarn => 'كسب';

  @override
  String get registeredReferrals => 'الإحالات المسجلة';

  @override
  String get verifiedReferrals => 'الإحالات المؤكدة';

  @override
  String get qualifiedReferrals => 'الإحالات المؤهلة';

  @override
  String get notYetAvailable => 'غير متاح بعد';

  @override
  String get readyToClaim => 'جاهز للمطالبة';

  @override
  String get lifetimeRewards => 'مكافآت مدى الحياة';

  @override
  String get alreadyPaid => 'مدفوع بالفعل';

  @override
  String get qualifiedTooltip =>
      'الإحالة المؤهلة هي شخص قمت بدعوته وأكمل الإجراءات المطلوبة للحصول على المكافأة.';

  @override
  String get subscriptionCurrency => 'عملة الاشتراك';

  @override
  String subscriptionCurrencyDesc(
      String currency, String country, String dialCode) {
    return 'تم تعيين عملة الاشتراك الخاصة بك إلى $currency ($country) بناءً على رمز منطقتك ($dialCode).';
  }

  @override
  String get subscriptionCurrencyLocked =>
      'عملة الاشتراك مقفلة حسب منطقة رقم هاتفك لضمان توافق عمليات الدفع ولا يمكن تغييرها يدويًا.';

  @override
  String get understood => 'مفهوم';

  @override
  String get principalLossWarningTitle => 'تحذير من خسارة رأس المال';

  @override
  String get belowTargetReturnTitle => 'تحذير: العائد أقل من المستهدف';

  @override
  String get sendAnyway => 'إرسال العرض على أي حال';

  @override
  String get safetyToolkit => 'مجموعة أدوات السلامة';

  @override
  String get safetyTips => 'نصائح السلامة';

  @override
  String get reportListingOrUser => 'الإبلاغ عن إعلان أو مستخدم';

  @override
  String get supportAndHelp => 'الدعم والمساعدة';

  @override
  String get appLock => 'قفل التطبيق';

  @override
  String get appLockDescription =>
      'اطلب التعرف البيولوجي أو رمز الجهاز بعد التشغيل البارد أو خلال 30 ثانية في الخلفية.';

  @override
  String get unlockNipanze => 'فتح Nipanze';

  @override
  String get referralChecking => 'جارٍ التحقق من رمز الإحالة...';

  @override
  String get referralAccepted => 'تم قبول رمز الإحالة.';

  @override
  String get profilePicture => 'صورة الملف الشخصي';

  @override
  String get profilePictureKycNote =>
      'مطلوبة للتحقق من الهوية. ارفع صورة واضحة لنفسك.';

  @override
  String get affordabilityWarningTitle => 'قد يكون السداد منخفضًا جدًا';

  @override
  String affordabilityWarningBody(
      String currency, String total, String shortfall) {
    return 'إجمالي السداد الخاص بك البالغ $currency $total أقل بمقدار $currency $shortfall عن المبلغ المطلوب. يحتاج المقرضون إلى عائد — فكر في زيادة مبلغ القسط.';
  }

  @override
  String get affordabilityDialogTitle => 'النشر على أي حال؟';

  @override
  String get affordabilityDialogBody =>
      'تبدو شروط السداد الخاصة بك أقل مما يقبله معظم المقرضين. يمكنك النشر، ولكن قد لا تتلقى عروضًا. فكر في زيادة قسطك.';

  @override
  String paymentScheduleTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أقساط',
      one: 'قسط',
    );
    return 'جدول المدفوعات ($count $_temp0)';
  }

  @override
  String plusMoreCount(int count) {
    return '+$count أخرى';
  }

  @override
  String get quickTermGuideLabel => 'دليل الشروط السريع';

  @override
  String get termGuideLow => '💡 فائدة منخفضة';

  @override
  String get termGuideFair => '🤝 شروط عادلة';

  @override
  String get termGuideNegotiable => '📊 قابل للتفاوض';

  @override
  String get offerMeansForYou => 'ماذا يعني هذا العرض بالنسبة لك';

  @override
  String get totalRepayableLabel => 'إجمالي المبلغ المستحق للسداد';

  @override
  String get effectiveInterestLabel => 'الفائدة الفعلية';

  @override
  String get loanAmountLabel => 'مبلغ القرض';

  @override
  String get highEffectiveRateWarning =>
      'يحتوي هذا العرض على معدل فائدة فعلي مرتفع نسبيًا. فكر في التفاوض أو الانتظار للحصول على عرض أقل.';

  @override
  String get allowInstitutionMatchingLabel => 'السماح بالمطابقة المؤسسية';

  @override
  String get allowInstitutionMatchingSubtitle =>
      'اسمح للوكلاء المعتمدين من بنكك أو مؤسستك باكتشاف طلبات القروض الخاصة بك للحصول على عروض مخصصة.';

  @override
  String get filterInstitutionMatches => 'مطابقات المؤسسات';

  @override
  String get filterInstitutionMatchesSubtitle =>
      'طلبات القروض فقط للمقترضين الذين وافقوا على المطابقة مع مؤسستك.';

  @override
  String get filterInstitutionMatchesIneligible =>
      'حدد مؤسستك في الملف الشخصي ← البنك والمهنة لتفعيل هذا المرشح.';

  @override
  String get filterSmartMatchingSection => 'المطابقة الذكية';

  @override
  String get institutionTypeBank => 'بنك';

  @override
  String get institutionTypeSacco => 'جمعية ادخار وائتمان (SACCO)';

  @override
  String get institutionTypeMfi => 'مؤسسة تمويل أصغر (MFI)';

  @override
  String get institutionTypeCreditCompany => 'شركة ائتمان';

  @override
  String get institutionTypeForex => 'شركة صرافة (Forex)';

  @override
  String get institutionTypeCompany => 'شركة';

  @override
  String get contactDetailsTitle => 'تفاصيل الاتصال';

  @override
  String get dealAgreementCreated => 'تم إنشاء اتفاقية الصفقة';

  @override
  String get dealAgreementCreatedSubtitle =>
      'يمكنك الآن الاتصال بالطرف الآخر للمضي قدمًا في صفقتك.';

  @override
  String get contactTheOtherParty => 'الاتصال بالطرف الآخر';

  @override
  String get detailsOnlyVisibleToYou => 'هذه التفاصيل مرئية لك فقط.';

  @override
  String get contactInfoLocked => 'معلومات الاتصال مغلقة';

  @override
  String get contactInfoLockedSubtitle =>
      'قم بإلغاء قفل تفاصيل الاتصال بالطرف الآخر للاتصال به مباشرةً أو إرسال بريد إلكتروني أو عبر واتساب.';

  @override
  String get oneTimeUnlockFee => 'رسوم إلغاء القفل لمرة واحدة';

  @override
  String get revealsContactInfoNotice =>
      'يكشف معلومات الاتصال لهذه الصفقة فقط.';

  @override
  String get oppositePartyContact => 'جهات اتصال الطرف المقابل';

  @override
  String successfulDealsCount(int count) {
    return '$count تطابقات';
  }

  @override
  String reviewsCount(int count) {
    return '$count تقييمات';
  }

  @override
  String get emailAddressLabel => 'عنوان البريد الإلكتروني';

  @override
  String get whatsappLabel => 'واتساب';

  @override
  String get callAction => 'اتصال';

  @override
  String get emailAction => 'بريد إلكتروني';

  @override
  String get chatAction => 'محادثة';

  @override
  String get safetyFirstTitle => 'السلامة أولاً';

  @override
  String get safetyFirstDesc =>
      'تواصل بمسؤولية. Nipanze منصة غير احتجازية ولا تتوسط أو تضمن أي معاملة.';

  @override
  String get goToMyDeals => 'الانتقال إلى صفقاتي';

  @override
  String get backToActivity => 'العودة إلى النشاط';

  @override
  String get previewDeal => 'معاينة الصفقة';

  @override
  String get reachOutToLenderDirectly => 'تواصل مع المقرض مباشرة';

  @override
  String get reachOutToBorrowerDirectly => 'تواصل مع المقترض مباشرة';

  @override
  String get nipanzeDisclaimerCardText =>
      'لا تحتجز Nipanze الأموال ولا تتوسط في الصفقات.\nيرجى التأكد من التفاصيل قبل إرسال أي مبلغ.';

  @override
  String get phoneCopiedToClipboard => 'تم نسخ رقم الهاتف إلى الحافظة';

  @override
  String get emailCopiedToClipboard => 'تم نسخ البريد الإلكتروني إلى الحافظة';

  @override
  String get whatsappCopiedToClipboard => 'تم نسخ رقم الواتساب إلى الحافظة';

  @override
  String get notProvided => 'غير متوفر';

  @override
  String get viewOppositePartyContact => 'عرض جهات اتصال الطرف المقابل';

  @override
  String get tapToViewContactDetails =>
      'انقر لعرض تفاصيل الاتصال بالطرف المقابل.\nالشروط النهائية هي حصريًا بين المقترض والمقرض.';

  @override
  String get needsRequestTitle => 'طلب احتياجات';

  @override
  String get createNeedsRequestTitle => 'نشر طلب احتياجات';

  @override
  String get needsTitleLabel => 'عنوان الاحتياج';

  @override
  String get needsTitleHint => 'مثال: مجموعة طاقة شمسية لمتجري';

  @override
  String get needsCategoryLabel => 'الفئة';

  @override
  String get needsSpecificationLabel => 'المواصفات';

  @override
  String get needsSpecificationHint =>
      'صف ما تحتاجه والكمية والجودة وأي توقعات للتسليم.';

  @override
  String get needsSpecificationRequired => 'صف ما تحتاجه';

  @override
  String get needsSpecificationMinLength => 'استخدم 12 حرفاً على الأقل';

  @override
  String needsBudgetLabel(String currency) {
    return 'الميزانية ($currency)';
  }

  @override
  String get needsBudgetHint => 'مثال: 500000';

  @override
  String get needsBudgetHelper => 'أدخل 0 إذا كنت تريد عروض أسعار من المزودين.';

  @override
  String get needsLocationRequired => 'اختر موقعاً';

  @override
  String get needsCustomLocationLabel => 'أدخل موقعاً مخصصاً';

  @override
  String get needsCustomLocationHint =>
      'مثال: جينجا أو فورت بورتال أو منطقة محلية';

  @override
  String get needsUrgencyLabel => 'درجة الاستعجال';

  @override
  String get needsPublishBtn => 'نشر طلب الاحتياجات';

  @override
  String get needsPreviewBtn => 'معاينة الطلب';

  @override
  String get needsPreviewTitle => 'راجع طلبك';

  @override
  String get needsPreviewEdit => 'تعديل';

  @override
  String get needsRequestSubmittedContent =>
      'طلب الاحتياجات الخاص بك متاح الآن في السوق. يمكن للمزودين مراجعته والرد عليه.';

  @override
  String needsBudgetPreview(String currency, String amount) {
    return 'الميزانية: $currency $amount';
  }

  @override
  String get needsCategoryBusinessEquipment => 'معدات الأعمال';

  @override
  String get needsCategoryInventory => 'المخزون';

  @override
  String get needsCategoryAgriculture => 'الزراعة';

  @override
  String get needsCategoryEducation => 'التعليم';

  @override
  String get needsCategoryHealth => 'الصحة';

  @override
  String get needsCategoryHomeEnergy => 'المنزل والطاقة';

  @override
  String get needsCategoryCommunity => 'المجتمع';

  @override
  String get needsCategoryTechnology => 'التكنولوجيا';

  @override
  String get needsCategoryTransport => 'النقل';

  @override
  String get needsUrgencyUrgent => 'عاجل';

  @override
  String get needsUrgencyWithin30Days => 'خلال 30 يوماً';

  @override
  String get needsUrgencyThisMonth => 'هذا الشهر';

  @override
  String get needsUrgencyFlexible => 'مرن';

  @override
  String get needsCategoryTravelInternational => 'السفر والدولي';

  @override
  String get needsCategoryMachineryEquipment => 'الآلات والمعدات';

  @override
  String get needsCategoryProfessionalServices => 'الخدمات المهنية';

  @override
  String get needsCategoryTransportLogistics => 'النقل واللوجستيات';

  @override
  String get needsCategorySpecializedProducts => 'المنتجات المتخصصة والمشتريات';

  @override
  String get needsMakeOffer => 'تقديم عرض';

  @override
  String get needsProviderOffers => 'عروض المزودين';

  @override
  String get needsAcceptOffer => 'قبول العرض';

  @override
  String get providerServicesTitle => 'خدمات المزود';

  @override
  String get providerServicesSubtitle => 'أخبر الناس بما يمكنك مساعدتهم فيه.';

  @override
  String get financialServicesCategory => 'الخدمات المالية';

  @override
  String get financialServicesDesc =>
      'خدمات القروض، الفوركس، وكلاء البنوك، SACCO، التمويل الأصغر، والاستشارات المالية.';

  @override
  String get bankLoanAgentCapability => 'وكيل قروض بنكية';

  @override
  String get moneyLenderPrivateLenderCapability => 'مقرض أموال / مقرض خاص';

  @override
  String get financialAdvisoryCapability => 'الاستشارات المالية';

  @override
  String get forexCurrencyExchangeCapability => 'فوركس / تبادل العملات';

  @override
  String get loanServicesCapability => 'خدمات القروض';

  @override
  String get saccoMicrofinanceCapability => 'SACCO / خدمات التمويل الأصغر';

  @override
  String get otherFinancialServicesCapability => 'خدمات مالية أخرى';

  @override
  String get organisationOptional => 'مؤسستك (اختياري)';

  @override
  String get organisationSubtitle =>
      'أضف مؤسستك أو عملك التجاري أو منظمتك وصفتك ليعرف مقدمو الطلبات من تمثل.';

  @override
  String get organisationHint => 'مثال: Equity Bank, Hans Finance, ABC Forex';

  @override
  String get organisationLabel => 'المؤسسة / البنك / المنظمة';

  @override
  String get roleOptional => 'دورك (اختياري)';

  @override
  String get roleHint => 'مثال: مزود قروض مستقل، وكيل بنكي';

  @override
  String get showProfessionalTagProvider => 'إظهار العلامة المهنية';

  @override
  String get showProfessionalTagProviderSubtitle =>
      'عرض خدماتك ومؤسستك وصفة دورك على العروض.';

  @override
  String get allowInstitutionMatchingProvider => 'السماح بالمطابقة الذكية';

  @override
  String get allowInstitutionMatchingProviderSubtitle =>
      'دع الطلبات ذات الصلة تجد عروضك.';

  @override
  String get allowSmartMatchingProvider => 'السماح بالمطابقة الذكية';

  @override
  String get allowSmartMatchingProviderSubtitle =>
      'دع الطلبات ذات الصلة تجد عروضك.';

  @override
  String servicesCount(int count) {
    return '$count خدمة';
  }

  @override
  String get zeroServicesAdded => 'تمت إضافة 0 خدمة';

  @override
  String get addServices => 'إضافة خدمات';

  @override
  String get addService => 'إضافة خدمة';

  @override
  String get providerVerified => 'مزود موثق';

  @override
  String get selfDeclared => 'معلن ذاتياً';

  @override
  String get yourServices => 'خدماتك';

  @override
  String get yourServicesSubtitle => 'إدارة الخدمات التي تقدمها للآخرين';

  @override
  String get noServicesYet => 'لم يتم إضافة خدمات بعد';

  @override
  String get noServicesYetSubtitle =>
      'أضف ما يمكنك تقديمه لتلقي الفرص المطابقة وتقديم عروض على الاحتياجات.';

  @override
  String get chooseCategory => 'اختر الفئة';

  @override
  String get chooseCapabilities => 'اختر القدرات';

  @override
  String get marketingAndPromotion => 'التسويق والترويج';

  @override
  String get socialMediaMarketing => 'التسويق عبر وسائل التواصل الاجتماعي';

  @override
  String get tiktokPromotion => 'الترويج عبر TikTok';

  @override
  String get instagramPromotion => 'الترويج عبر Instagram';

  @override
  String get youtubePromotion => 'الترويج عبر YouTube';

  @override
  String get facebookPromotion => 'الترويج عبر Facebook';

  @override
  String get influencerMarketing => 'التسويق عبر المؤثرين';

  @override
  String get contentCreation => 'إنشاء المحتوى';

  @override
  String get productReviews => 'مراجعات المنتجات';

  @override
  String get eventPromotion => 'الترويج للفعاليات';

  @override
  String get whatsAppCommunityPromotion => 'الترويج عبر WhatsApp / المجتمعات';

  @override
  String get affiliateMarketing => 'التسويق بالعمولة';

  @override
  String get advertisingCampaigns => 'الحملات الإعلانية';

  @override
  String get brandPromotion => 'الترويج للعلامات التجارية';

  @override
  String get otherMarketingServices => 'خدمات تسويق أخرى';

  @override
  String get iHaveAnAudience => 'لدي جمهور';

  @override
  String get whereIsYourAudience => 'أين يوجد جمهورك؟';

  @override
  String get selectAudiencePlatforms => 'اختر كل ما ينطبق';

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
  String get audiencePlatformOther => 'أخرى';

  @override
  String get tellBusinessesAboutYourAudience => 'عرّف الشركات بجمهورك';

  @override
  String get audienceFollowersMembersCount => 'عدد المتابعين / الأعضاء';

  @override
  String get audienceMainLocation => 'الموقع الرئيسي للجمهور';

  @override
  String get audienceMainInterest => 'الاهتمام / الفئة الرئيسية للجمهور';

  @override
  String get declaredAudience => 'جمهور مُعلن';

  @override
  String get addSelected => 'إضافة المحدد';

  @override
  String get removeService => 'إزالة الخدمة';

  @override
  String get removeServiceConfirm =>
      'هل أنت متأكد من رغبتك في إزالة هذه الخدمة من ملفك الشخصي؟';

  @override
  String get providerOpportunitiesTitle => 'يبحث الناس عما تقدمه';

  @override
  String get workProfileTitle => 'ملف العمل';

  @override
  String get workProfileSubtitle =>
      'صف الوظائف التي تريدها بشكل منفصل عن الخدمات التي تقدمها.';

  @override
  String get workProfilesDisabled => 'ملفات العمل غير مفعلة بعد.';

  @override
  String get addWorkProfile => 'إضافة ملف عمل';

  @override
  String get noWorkProfilesYet =>
      'لا يوجد ملف عمل بعد. أضف واحدًا إذا أردت أن يفهم الناس العمل الذي أنت مؤهل له.';

  @override
  String get jobOpportunitiesUnavailable =>
      'مطابقة فرص العمل غير متاحة بعد. يتم حفظ ملفك للمطابقة لاحقًا ولا ينشئ شارة تحقق.';

  @override
  String get jobRole => 'دور العمل';

  @override
  String get workTypes => 'أنواع العمل';

  @override
  String get qualifications => 'المؤهلات';

  @override
  String get experience => 'الخبرة';

  @override
  String get availability => 'التوفر';

  @override
  String get fullTime => 'دوام كامل';

  @override
  String get partTime => 'دوام جزئي';

  @override
  String get contract => 'عقد';

  @override
  String get weekends => 'عطلات نهاية الأسبوع';

  @override
  String get preferredLocation => 'الموقع المفضل';

  @override
  String get flexible => 'مرن';

  @override
  String get onsite => 'في الموقع';

  @override
  String get remote => 'عن بُعد';

  @override
  String get hybrid => 'هجين';

  @override
  String get expectedPay => 'الأجر المتوقع';

  @override
  String get payOpen => 'الأجر مفتوح';

  @override
  String get per => 'لكل';

  @override
  String get perHour => 'ساعة';

  @override
  String get perDay => 'يوم';

  @override
  String get perWeek => 'أسبوع';

  @override
  String get perProject => 'مشروع';

  @override
  String get languages => 'اللغات';

  @override
  String get profileSummary => 'ملخص الملف';

  @override
  String get saveWorkProfile => 'حفظ ملف العمل';

  @override
  String get deactivateWorkProfile => 'تعطيل ملف العمل';

  @override
  String get deactivateWorkProfileConfirm =>
      'هذا يخفي ملف العمل ولكنه لا يزيل قدراتك الخدمية.';

  @override
  String get deactivate => 'تعطيل';

  @override
  String get inactive => 'غير نشط';

  @override
  String get edit => 'تعديل';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get requiredField => 'مطلوب';

  @override
  String get viewOpportunities => 'عرض الفرص';

  @override
  String get addYourServices => 'أضف خدماتك';

  @override
  String get canYouHelp => 'هل يمكنك مساعدة الناس في شيء ما؟';

  @override
  String get youDontProvideThisService => 'أنت لا تقدم هذه الخدمة بعد.';

  @override
  String addCapabilityAction(String capability) {
    return 'إضافة $capability';
  }

  @override
  String opportunitiesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فرصة',
      many: '$count فرصة',
      few: '$count فرص',
      two: 'فرصتان',
      one: 'فرصة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navPost => 'نشر';

  @override
  String get navActivity => 'النشاط';

  @override
  String get postChoiceTitle => 'ماذا تريد أن تنشر؟';

  @override
  String get postLoanAction => 'قرض';

  @override
  String get postLoanSubtitle => 'إنشاء طلب قرض';

  @override
  String get postForexAction => 'فوركس';

  @override
  String get postForexSubtitle => 'إنشاء طلب لتبادل العملات';

  @override
  String get postNeedAction => 'احتياج';

  @override
  String get postNeedSubtitle => 'إنشاء احتياج';

  @override
  String get forYouTitle => 'لك خصيصاً';

  @override
  String get peopleLookingForServices => 'يبحث الأشخاص عما تقدمه';

  @override
  String get addYourServicesPrompt => 'هل يمكنك مساعدة الناس في تقديم خدمة؟';

  @override
  String get whatCanYouHelpWith => 'بماذا يمكنك مساعدة الناس؟';

  @override
  String get whatCanYouHelpWithSubtitle =>
      'أخبرنا بما تقدمه وسنوصلك بالأشخاص الذين يبحثون عنه.';

  @override
  String get addYourServicesCta => 'أضف خدماتك';

  @override
  String get newCategoriesAvailable => 'فئات جديدة متاحة';

  @override
  String newCategoriesAvailableSubtitle(Object categories) {
    return 'أضفنا $categories. ربما لديك ما تقدمه ضمنها.';
  }

  @override
  String get exploreNewCategoriesCta => 'استكشف الفئات الجديدة';

  @override
  String matchingNeedsSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# طلب جديد يناسب خدماتك.',
      many: '# طلبًا جديدًا يناسب خدماتك.',
      few: '# طلبات جديدة تناسب خدماتك.',
      two: 'طلبان جديدان يناسبان خدماتك.',
      one: 'طلب جديد واحد يناسب خدماتك.',
    );
    return '$_temp0';
  }

  @override
  String get seeOpportunitiesCta => 'اطّلع على الفرص';

  @override
  String get discoveryQuestionTitle => 'سؤال سريع';

  @override
  String get discoveryBusinessTitle => 'هل تخطط لشيء في المستقبل؟';

  @override
  String get discoveryBusinessQuestion =>
      'هل ستحتاج قريبًا إلى معدات أو خدمات لوجستية أو مشتريات أو خدمات للأعمال؟';

  @override
  String get discoveryTravelQuestion =>
      'هل تخطط للسفر خلال الأشهر القليلة المقبلة؟';

  @override
  String get discoveryEducationQuestion =>
      'هل ستفيدك فرص التدريب الداخلي أو التطوير المهني؟';

  @override
  String get discoveryFinancialQuestion =>
      'هل تهتم بالقروض أو التمويل أو فرص الفوركس؟';

  @override
  String get discoveryEquipment => 'المعدات';

  @override
  String get discoveryLogistics => 'الخدمات اللوجستية';

  @override
  String get discoveryServices => 'الخدمات';

  @override
  String get discoveryProcurement => 'المشتريات';

  @override
  String get discoveryYes => 'نعم';

  @override
  String get discoveryLater => 'ربما لاحقًا';

  @override
  String get discoveryNotNow => 'ليس الآن';

  @override
  String get discoveryNo => 'لا';

  @override
  String get discoveryLoans => 'القروض';

  @override
  String get discoveryForex => 'الفوركس';

  @override
  String get discoveryBoth => 'كلاهما';

  @override
  String get discoveryTravelCta => 'استكشف خدمات السفر';

  @override
  String get discoveryEducationCta => 'استكشف فرص التعليم';

  @override
  String get discoveryBusinessCta => 'استكشف الفرص';

  @override
  String get discoveryFinancialCta => 'افتح السوق';

  @override
  String get discoveryOptionsTooltip => 'خيارات الاستكشاف';

  @override
  String get discoveryHideQuestion => 'إخفاء هذا السؤال';

  @override
  String get discoveryFewerQuestions => 'عرض أسئلة مشابهة أقل';

  @override
  String get discoverySkip => 'تخطي';

  @override
  String get discoveryExploreOpportunities => 'استكشف الفرص';

  @override
  String get savedPlansTitle => 'الخطط والاهتمامات';

  @override
  String get savedPlansEmptyTitle => 'لا توجد خطط محفوظة بعد';

  @override
  String get savedPlansEmptySubtitle =>
      'ستظهر هنا الخطط والاهتمامات الخاصة التي تحفظها من أسئلة الاستكشاف.';

  @override
  String get savedPlanActions => 'إجراءات الخطة';

  @override
  String get savedPlanEdit => 'تعديل';

  @override
  String get savedPlanDelete => 'حذف';

  @override
  String get savedPlanReminderSet => 'تم ضبط التذكير';

  @override
  String savedPlanUpdated(String date) {
    return 'تم التحديث $date';
  }

  @override
  String get savedPlanTravel => 'السفر';

  @override
  String get savedPlanEducationCareer => 'التعليم والمسار المهني';

  @override
  String get savedPlanBusiness => 'الأعمال';

  @override
  String get savedPlanFinancial => 'المالية';

  @override
  String get savedPlanGeneral => 'عام';

  @override
  String get savedPlanNoDetails => 'لم تتم إضافة تفاصيل';

  @override
  String get savedPlanDeleteTitle => 'حذف الخطة؟';

  @override
  String get savedPlanDeleteConfirmation =>
      'سيؤدي هذا إلى إزالة الخطة الخاصة المحفوظة من حسابك.';

  @override
  String get savedPlanCancel => 'إلغاء';

  @override
  String get savedPlanEditTitle => 'تعديل الخطة';

  @override
  String get savedPlanName => 'اسم الخطة';

  @override
  String get savedPlanDestination => 'الوجهة';

  @override
  String get savedPlanPreferredLocation => 'الموقع المفضل';

  @override
  String get savedPlanTimeframe => 'الإطار الزمني التقريبي';

  @override
  String get savedPlanAddDate => 'إضافة التاريخ المتوقع';

  @override
  String get savedPlanReminder => 'تذكير';

  @override
  String get savedPlanNoReminder => 'بدون تذكير';

  @override
  String get savedPlanOneWeekBefore => 'قبل أسبوع';

  @override
  String get savedPlanOneMonthBefore => 'قبل شهر';

  @override
  String get savedPlanSave => 'حفظ';

  @override
  String get savedPlanStartingLocation => 'موقع الانطلاق';

  @override
  String get savedPlanAssistanceNeeded => 'المساعدة المطلوبة';

  @override
  String get savedPlanWhatWouldHelp => 'ما الذي قد يفيدك؟';

  @override
  String postDurationActiveDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'نشط لمدة $days يوم.',
      many: 'نشط لمدة $days يوماً.',
      few: 'نشط لمدة $days أيام.',
      two: 'نشط لمدة يومين.',
      one: 'نشط لمدة يوم واحد.',
    );
    return '$_temp0';
  }

  @override
  String postDurationFullNotice(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'سيكون طلبك نشطاً لمدة $days يوم.',
      many: 'سيكون طلبك نشطاً لمدة $days يوماً.',
      few: 'سيكون طلبك نشطاً لمدة $days أيام.',
      two: 'سيكون طلبك نشطاً لمدة يومين.',
      one: 'سيكون طلبك نشطاً لمدة يوم واحد.',
    );
    return '$_temp0';
  }

  @override
  String get postDurationNotice =>
      'ستنتهي صلاحية طلبك تلقائياً بعد هذه الفترة.';

  @override
  String get nationalityUgandan => 'أوغندي';

  @override
  String get nationalityKenyan => 'كيني';

  @override
  String get nationalityTanzanian => 'تنزاني';

  @override
  String get nationalityRwandan => 'رواندي';

  @override
  String get nationalityNigerian => 'نيجيري';

  @override
  String get nationalitySouthAfrican => 'جنوب أفريقي';

  @override
  String get nationalityEgyptian => 'مصري';

  @override
  String get nationalityCongoleseDrc => 'كونغولي (جمهورية الكونغو الديمقراطية)';

  @override
  String get nationalityBurundian => 'بوروندي';

  @override
  String get nationalitySouthSudanese => 'جنوب سوداني';

  @override
  String get nationalitySomali => 'صومالي';

  @override
  String get iWantJobs => 'أرغب في العمل';

  @override
  String get iWantJobsSubtitle => 'إعداد ملف البحث عن عمل لهذه الفئة';

  @override
  String get searchCategories => 'البحث في الفئات';

  @override
  String get noMatchingJobOpportunities =>
      'لا توجد فرص عمل مطابقة متاحة حتى الآن. ستظهر الفرص هنا عند نشر أصحاب العمل للطلبات.';

  @override
  String get selectAtLeastOneRole => 'يرجى تحديد دور وظيفي واحد على الأقل';

  @override
  String qualificationsDeclared(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مؤهل معلن',
      many: '$count مؤهلاً معلناً',
      few: '$count مؤهلات معلنة',
      two: 'مؤهلان معلنان',
      one: 'مؤهل واحد معلن',
      zero: 'لا توجد مؤهلات معلنة',
    );
    return '$_temp0';
  }

  @override
  String rolesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count دور',
      many: '$count دوراً',
      few: '$count أدوار',
      two: 'دوران',
      one: 'دور واحد',
      zero: 'لا توجد أدوار',
    );
    return '$_temp0';
  }

  @override
  String get providerTypeChange => 'تغيير';

  @override
  String get providerIdentityRequiredInfo =>
      'أدخل الاسم المعروض وأكد صلاحية التمثيل للمتابعة.';

  @override
  String get providerIdentitySwitchSuccess => 'تم تبديل هوية مقدم الخدمة.';

  @override
  String get providerIdentityCurrent => 'الحالي';

  @override
  String get providerIdentityDisplayHeading => 'كيف تريد أن تظهر؟';

  @override
  String get providerIdentityDisplayName => 'الاسم المعروض';

  @override
  String get providerIdentityCompanyName => 'اسم الشركة أو النشاط التجاري';

  @override
  String get providerIdentityCompanyOnly => 'اسم الشركة';

  @override
  String get providerIdentityCompanyRepresentative => 'شركة مع ممثل';

  @override
  String get providerIdentityRepresentativeName => 'اسم الممثل';

  @override
  String get providerIdentityAuthority => 'لدي صلاحية تمثيل هذا النشاط التجاري';

  @override
  String providerIdentityRepresentedBy(String name) {
    return 'يمثله $name';
  }

  @override
  String providerIdentitySwitchTitle(String identity) {
    return 'التبديل إلى $identity؟';
  }

  @override
  String get providerIdentitySwitchBody =>
      'سيغيّر هذا القسم الحالي فقط. ستبقى أقسامك الأخرى كما هي.';

  @override
  String get providerIdentityDataKept =>
      'ستبقى معلومات خدماتك محفوظة. لن يُحذف شيء.';

  @override
  String providerIdentityOldServicesInactive(String identity) {
    return 'ستصبح خدمات $identity هنا غير نشطة ويمكن استعادتها.';
  }

  @override
  String providerIdentityNewOffers(String identity) {
    return 'ستستخدم العروض الجديدة هوية $identity.';
  }

  @override
  String get providerIdentityVerificationReset =>
      'قد تتغير متطلبات التحقق. لا ينتقل التحقق إلى الهوية الجديدة.';

  @override
  String get providerIdentityHistoryKept =>
      'تبقى الصفقات المقبولة والمراجعات والسجل والأدوار الشخصية كما هي.';

  @override
  String providerIdentityPendingOffers(int count) {
    return 'لديك $count عروض معلقة. ستبقى كما أُرسلت ويمكنك سحبها بنفسك.';
  }

  @override
  String get providerIdentityReviewTitle => 'راجع التبديل';

  @override
  String get providerIdentityCategory => 'الفئة';

  @override
  String get providerIdentityNewIdentity => 'الهوية الجديدة';

  @override
  String get providerIdentityPublicName => 'الاسم العام';

  @override
  String get providerIdentityReused =>
      'المعلومات المعاد استخدامها من إعدادك الحالي';

  @override
  String get providerIdentityNeedsAttention => 'يتطلب الانتباه';

  @override
  String get providerIdentityCompanyVerificationStatus =>
      'تحقق الشركة منفصل ولا ينتقل إلى الهوية الأخرى.';

  @override
  String get providerIdentityNoActiveWarning =>
      'لن تكون هناك خدمات نشطة في هذه الفئة بعد التبديل.';

  @override
  String get providerIdentityConfirm => 'تأكيد التبديل';

  @override
  String get providerTypeWhatWeOffer => 'ما نقدمه';

  @override
  String get providerTypeWhatRoles => 'ما الأدوار التي تقوم بها؟';

  @override
  String get providerTypeStepOneOfThree => 'الخطوة 1 من 3';

  @override
  String get providerTypePickRoles =>
      'اختر كل الأدوار المناسبة لك. يمكنك إضافة المزيد لاحقًا.';

  @override
  String get providerTypeNextKind => 'التالي: اختر تخصصك';

  @override
  String providerTypeSaveServicesCount(Object count) {
    return 'حفظ الخدمات $count';
  }

  @override
  String get providerTypeSelectService => 'اختر خدمة واحدة على الأقل';

  @override
  String get providerTypeHiddenCompanyOnly => 'مخفي: يُعرض بصفة شركة فقط';

  @override
  String get providerTypeOfferingAs => 'تقدم بصفتك';

  @override
  String get providerTypeOffering => 'تقدم في هذه الفئة';

  @override
  String get providerTypeTitle => 'من الذي يقدم الخدمة؟';

  @override
  String get providerTypeSubtitle =>
      'يوضح هذا للناس ما إذا كانوا سيتعاملون معك أو مع شركتك. يمكنك تحديد ذلك بشكل مختلف لكل فئة.';

  @override
  String get providerTypeIndividual => 'فرد';

  @override
  String get providerTypeIndividualDesc =>
      'أقدم مهاراتي الشخصية مباشرةً للعملاء بصفتي مستقلاً أو عاملاً.';

  @override
  String get providerTypeCompany => 'شركة / مؤسسة';

  @override
  String get providerTypeCompanyDesc => 'شركة أو وكالة أو فريق أو مؤسسة مسجلة.';

  @override
  String get providerTypeNotVerification =>
      'هذا الاختيار لا يعني التحقق من هويتك. التحقق منفصل ولا يُطلب إلا عندما تتطلبه خدمة معينة.';

  @override
  String get providerTypeChooseOne => 'اختر خياراً واحداً للمتابعة';

  @override
  String get providerTypeJobsPersonalNote => 'ملفات العمل شخصية وتُحفظ باسمك.';

  @override
  String get providerTypeStepOneOfTwo => 'الخطوة 1 من 2';

  @override
  String get providerTypeCompanyServicesHint =>
      'حدد كل الخدمات التي تقدمها شركتك.';

  @override
  String get providerTypeCompanyRolesHint => 'الأدوار اختيارية';

  @override
  String get providerTypeCompanyRolesSubtitle =>
      'حدد الأدوار التي تعمل بها. ملفات الوظائف شخصية ومحفوظة باسمك. يمكنك إضافة الآلات والمؤهلات لاحقًا.';

  @override
  String providerTypeCompanySelectionCount(int services, int roles) {
    String _temp0 = intl.Intl.pluralLogic(
      services,
      locale: localeName,
      other: '$services خدمة',
      many: '$services خدمة',
      few: '$services خدمات',
      two: 'خدمتان',
      one: 'خدمة واحدة',
      zero: 'لا توجد خدمات',
    );
    String _temp1 = intl.Intl.pluralLogic(
      roles,
      locale: localeName,
      other: '$roles دور',
      many: '$roles دورًا',
      few: '$roles أدوار',
      two: 'دوران',
      one: 'دور واحد',
      zero: 'لا توجد أدوار',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get companyStepTwoOfTwo => 'الخطوة 2 من 2';

  @override
  String get companyDetailsTitle => 'أخبرنا عن شركتك';

  @override
  String get companyDetailsSubtitle =>
      'كل المعلومات اختيارية. هذه التفاصيل خاصة بك وبمسؤولي نيبانزي فقط.';

  @override
  String get companyName => 'اسم الشركة أو النشاط التجاري';

  @override
  String get companyRegistrationNumber => 'رقم التسجيل';

  @override
  String get companyRegistrationPrivate => 'مرئي لك ولمسؤولي نيبانزي فقط.';

  @override
  String get companyTeamSize => 'حجم الفريق';

  @override
  String get companyYearsInBusiness => 'سنوات العمل';

  @override
  String get companyServiceAreas => 'أين تعمل؟';

  @override
  String get companyServiceAreasHint =>
      'المنطقة أو المدينة فقط. لن يظهر عنوانك الدقيق. افصل المناطق بفواصل.';

  @override
  String get companyProofTitle => 'إثبات شارة التحقق';

  @override
  String get companyProofIntro =>
      'يراجع نيبانزي المستندات. رفع الملفات وحده لا يمنحك التحقق.';

  @override
  String get companyNoEvidenceRequirements =>
      'لا توجد مستندات مطلوبة لهذه الخدمات حاليًا.';

  @override
  String get companyProofNote =>
      'يمكنك الحفظ الآن وإضافة الإثبات لاحقًا. JPG أو PNG أو PDF، بحد أقصى 5 ميغابايت لكل ملف.';

  @override
  String get companyEvidenceNotAdded => 'لم تتم الإضافة';

  @override
  String get companyEvidenceUploaded => 'تم الرفع';

  @override
  String get companyEvidenceUnderReview => 'قيد المراجعة';

  @override
  String get companyEvidenceRejected => 'مرفوض';

  @override
  String get companyEvidenceExpired => 'منتهي الصلاحية';

  @override
  String get companyEvidenceApproved => 'تمت الموافقة';

  @override
  String get companyEvidenceAdd => 'إضافة إثبات';

  @override
  String get companyEvidenceReplace => 'استبدال';

  @override
  String get companyEvidenceReadError =>
      'تعذرت قراءة الملف المحدد. جرّب ملفًا آخر.';

  @override
  String get companyEvidenceTooLarge => 'اختر ملفًا لا يتجاوز 5 ميغابايت.';

  @override
  String get companyEvidenceUnsupported => 'اختر ملف JPG أو PNG أو PDF.';

  @override
  String get companySave => 'حفظ ملف الشركة';

  @override
  String companySelectionCount(int services, int roles) {
    String _temp0 = intl.Intl.pluralLogic(
      services,
      locale: localeName,
      other: '$services خدمة',
      many: '$services خدمة',
      few: '$services خدمات',
      two: 'خدمتان',
      one: 'خدمة واحدة',
      zero: 'لا توجد خدمات',
    );
    String _temp1 = intl.Intl.pluralLogic(
      roles,
      locale: localeName,
      other: '$roles دور',
      many: '$roles دورًا',
      few: '$roles أدوار',
      two: 'دوران',
      one: 'دور واحد',
      zero: 'لا توجد أدوار',
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
  String get companyYearsUnderOne => 'أقل من 1';

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
    return '$selected من $total';
  }

  @override
  String get companyPersonalProfile => 'ملف شخصي';

  @override
  String get providerTypeJobNeedsDetails =>
      'أضف الآلات والمؤهلات لتظهر لك فرص مناسبة.';

  @override
  String get providerTypeNextCompanyDetails => 'التالي: تفاصيل الشركة';

  @override
  String providerSummaryAll(int count) {
    return 'الكل $count';
  }

  @override
  String providerSummaryServices(int count) {
    return 'الخدمات $count';
  }

  @override
  String providerSummaryJobs(int count) {
    return 'الوظائف $count';
  }

  @override
  String get companyProfileSaved => 'تم حفظ ملف الشركة.';

  @override
  String get providerEvidenceTab => 'أدلة مقدمي الخدمات';

  @override
  String get providerEvidenceHeader => 'أدلة قدرات مقدمي الخدمات قيد المراجعة';

  @override
  String get providerEvidenceEmpty =>
      'لا توجد أدلة لمقدمي الخدمات بانتظار المراجعة.';

  @override
  String get providerEvidenceCapabilities => 'قدرات';

  @override
  String get providerEvidenceOpenFile => 'فتح ملف الإثبات المشترك';

  @override
  String get providerEvidenceCompanyDetails => 'تفاصيل الشركة (للمسؤولين فقط)';

  @override
  String get providerEvidenceApprove => 'الموافقة على هذه القدرة';

  @override
  String get providerEvidenceReject => 'رفض';

  @override
  String get providerEvidenceRejectReason => 'رفض الإثبات';

  @override
  String get providerEvidenceReason => 'سبب الرفض';

  @override
  String get providerEvidenceReviewSaved => 'تم حفظ مراجعة الإثبات.';

  @override
  String get providerCapabilityActive => 'نشط';

  @override
  String get providerCapabilityInactive => 'غير نشط';

  @override
  String get providerCapabilityPendingReview => 'قيد المراجعة';

  @override
  String get providerCapabilityRejected => 'مرفوض';

  @override
  String get providerPolicyNoProof => 'لا يلزم إثبات';

  @override
  String get providerPolicyProofLater => 'يمكنك إضافة الإثبات لاحقاً';

  @override
  String get providerPolicyProofRequired => 'يلزم الإثبات قبل التفعيل';

  @override
  String get providerPolicyNeedsProofTag => 'يتطلب إثباتاً';

  @override
  String get providerPolicyUploadDocuments => 'إرسال المستندات';

  @override
  String get providerEvidenceNoRequirements =>
      'لم يتم تحديد إثبات لهذه الخدمة.';

  @override
  String get providerEvidenceSubmitted => 'تم إرسال الإثبات للمراجعة.';

  @override
  String get companyVerificationTitle => 'التحقق من الشركة';

  @override
  String get companyVerificationIntro =>
      'اختياري. أرسل مستنداً واحداً أو كليهما لمراجعة يدوية من Nipanze.';

  @override
  String get companyVerificationRegistration => 'شهادة تسجيل النشاط التجاري';

  @override
  String get companyVerificationLicence => 'التراخيص أو مستندات التفويض';

  @override
  String get companyVerificationNotSubmitted => 'لم يُرسل';

  @override
  String get companyVerificationPending => 'قيد المراجعة';

  @override
  String get companyVerificationVerified => 'تم التحقق';

  @override
  String get companyVerificationRejected => 'مرفوض';

  @override
  String get companyVerificationSeparateNote =>
      'شهادة التسجيل لا تسمح بالخدمات المنظمة. يتم التحقق من كل خدمة على حدة.';

  @override
  String get companyVerificationFileHint =>
      'JPG أو PNG أو PDF، بحد أقصى 5 ميغابايت لكل ملف. يمكنك الحفظ وإضافة الإثبات لاحقاً.';

  @override
  String get companyVerificationUpload => 'إرسال مستند';

  @override
  String get companyVerificationUploaded => 'تم إرسال المستند';

  @override
  String get providerTypeEditCompanyDetails => 'تعديل تفاصيل الشركة';

  @override
  String get providerTypeOtherGroup => 'أخرى';

  @override
  String get providerTypeNoRolesConfigured =>
      'لا توجد أدوار وظيفية محددة لهذه الفئة حتى الآن.';

  @override
  String get providerNoJobRolesAdded => 'لم تتم إضافة أدوار وظيفية';

  @override
  String get providerAvailableForJobs => 'متاح للوظائف';

  @override
  String providerOpenJobsMatch(int count) {
    return 'توجد $count وظائف مناسبة';
  }

  @override
  String get companyLeaveTitle => 'هل تريد مغادرة إعداد الشركة؟';

  @override
  String get companyLeaveSelectionsMessage =>
      'لم يتم حفظ الخدمات والأدوار التي اخترتها.';

  @override
  String get companyLeaveDetailsMessage =>
      'لم يتم حفظ تفاصيل الشركة واختياراتك.';

  @override
  String get companyLeaveKeepEditing => 'متابعة التعديل';

  @override
  String get companyLeaveDiscard => 'تجاهل التغييرات';
}
