// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String accountCreatedFor(String username) {
    return 'تم إنشاء الحساب للمستخدم $username';
  }

  @override
  String get accountRole => 'نوع الحساب';

  @override
  String get add => 'إضافة';

  @override
  String get allAvailableCarNamesAlreadySelected =>
      'تم اختيار جميع أسماء السيارات المتاحة.';

  @override
  String get appTitle => 'قطع غيار السيارات MTA';

  @override
  String get backend => 'الخادم';

  @override
  String get carCatalogCouldNotBeLoadedRightNow =>
      'تعذر تحميل دليل السيارات الآن.';

  @override
  String get carName => 'اسم السيارة';

  @override
  String get carsIHavePartsFor => 'السيارات التي أملك قطعًا لها';

  @override
  String get changeLanguage => 'تغيير اللغة';

  @override
  String get chats => 'الدردشات';

  @override
  String get chooseAUsername => 'اختر اسم مستخدم';

  @override
  String conversationNumber(int id) {
    return 'المحادثة رقم $id';
  }

  @override
  String get conversations => 'المحادثات';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get createNewAccount => 'إنشاء حساب جديد';

  @override
  String get creating => 'جارٍ الإنشاء...';

  @override
  String daysAgo(int count) {
    return 'منذ $count يوم';
  }

  @override
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get emailHint => 'name@example.com';

  @override
  String get enterAValidEmailAddress => 'أدخل بريدًا إلكترونيًا صالحًا';

  @override
  String get enterPassword => 'أدخل كلمة المرور';

  @override
  String get enterUsername => 'أدخل اسم المستخدم';

  @override
  String get enterYourEmail => 'أدخل بريدك الإلكتروني';

  @override
  String get enterYourFullName => 'أدخل اسمك الكامل';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get fullNameHint => 'أدخل اسمك الكامل';

  @override
  String hoursAgo(int count) {
    return 'منذ $count ساعة';
  }

  @override
  String get justNow => 'الآن';

  @override
  String get language => 'اللغة';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHebrew => 'עברית';

  @override
  String get languageSystemDefault => 'لغة الجهاز';

  @override
  String lastSeenOn(String time) {
    return 'آخر ظهور في $time';
  }

  @override
  String lastSeenRelative(String time) {
    return 'آخر ظهور $time';
  }

  @override
  String get loadMore => 'تحميل المزيد';

  @override
  String get loading => 'جارٍ التحميل...';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String minutesAgo(int count) {
    return 'منذ $count دقيقة';
  }

  @override
  String get newMessage => 'رسالة جديدة';

  @override
  String get noCarNamesSelectedYet => 'لم يتم اختيار أي سيارات بعد.';

  @override
  String get noConversationsYet => 'لا توجد محادثات بعد';

  @override
  String get noConversationsYetMessage => 'لم تبدأ أي محادثات بعد.';

  @override
  String get noMessagesYet => 'لا توجد رسائل بعد';

  @override
  String get offline => 'غير متصل';

  @override
  String get online => 'متصل';

  @override
  String get password => 'كلمة المرور';

  @override
  String get passwordHint => 'أدخل كلمة المرور';

  @override
  String get passwordMinHint => '6 أحرف على الأقل';

  @override
  String get pickTheCarNamesYouSupplyPartsFor =>
      'اختر أسماء السيارات التي توفّر لها قطع الغيار.';

  @override
  String get registerUsernameHint => 'اختر اسم مستخدم';

  @override
  String get remove => 'إزالة';

  @override
  String get requests => 'الطلبات';

  @override
  String get selectLanguage => 'اختر اللغة';

  @override
  String get setUpMarketplaceProfile => 'إعداد ملفك في السوق';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signingIn => 'جارٍ تسجيل الدخول...';

  @override
  String get signInToBrowseSellerRequests =>
      'سجّل الدخول لتصفح طلبات البائعين والدردشة.';

  @override
  String get somethingWentWrong => 'حدث خطأ ما';

  @override
  String get supplierRole => 'مورد';

  @override
  String get suppliersCanPostRequests =>
      'يمكن للمورّدين نشر الطلبات ويمكن للمشترين بدء المحادثات.';

  @override
  String get theCarCatalogCouldNotBeLoaded => 'تعذر تحميل دليل السيارات.';

  @override
  String get thisMessageWasDeleted => 'تم حذف هذه الرسالة';

  @override
  String get tryAgain => 'حاول مرة أخرى';

  @override
  String get useAtLeastSixCharacters => 'استخدم 6 أحرف على الأقل';

  @override
  String get username => 'اسم المستخدم';

  @override
  String get usernameHint => 'أدخل اسم المستخدم';

  @override
  String get userRole => 'مستخدم';
}
