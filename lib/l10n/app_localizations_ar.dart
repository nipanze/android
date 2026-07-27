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
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String get identityVerification => 'التحقق من الهوية';

  @override
  String get security => 'الأمان';

  @override
  String get notifications => 'الإشعارات';

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
}
