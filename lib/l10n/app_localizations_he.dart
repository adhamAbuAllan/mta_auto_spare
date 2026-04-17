// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String accountCreatedFor(String username) {
    return 'החשבון נוצר עבור $username';
  }

  @override
  String get accountRole => 'סוג החשבון';

  @override
  String get add => 'הוסף';

  @override
  String get allAvailableCarNamesAlreadySelected =>
      'כל שמות הרכבים הזמינים כבר נבחרו.';

  @override
  String get appTitle => 'MTA חלקי חילוף לרכב';

  @override
  String get backend => 'שרת';

  @override
  String get carCatalogCouldNotBeLoadedRightNow =>
      'לא ניתן לטעון את קטלוג הרכבים כעת.';

  @override
  String get carName => 'שם הרכב';

  @override
  String get carsIHavePartsFor => 'הרכבים שיש לי עבורם חלקים';

  @override
  String get changeLanguage => 'שינוי שפה';

  @override
  String get chats => 'שיחות';

  @override
  String get chooseAUsername => 'בחר שם משתמש';

  @override
  String conversationNumber(int id) {
    return 'שיחה מספר $id';
  }

  @override
  String get conversations => 'שיחות';

  @override
  String get createAccount => 'יצירת חשבון';

  @override
  String get createNewAccount => 'יצירת חשבון חדש';

  @override
  String get creating => 'יוצר...';

  @override
  String daysAgo(int count) {
    return 'לפני $count ימים';
  }

  @override
  String get editProfile => 'עריכת פרופיל';

  @override
  String get email => 'אימייל';

  @override
  String get emailHint => 'name@example.com';

  @override
  String get enterAValidEmailAddress => 'הזן כתובת אימייל תקינה';

  @override
  String get enterPassword => 'הזן סיסמה';

  @override
  String get enterUsername => 'הזן שם משתמש';

  @override
  String get enterYourEmail => 'הזן את האימייל שלך';

  @override
  String get enterYourFullName => 'הזן את שמך המלא';

  @override
  String get fullName => 'שם מלא';

  @override
  String get fullNameHint => 'הזן את שמך המלא';

  @override
  String hoursAgo(int count) {
    return 'לפני $count שעות';
  }

  @override
  String get justNow => 'עכשיו';

  @override
  String get language => 'שפה';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHebrew => 'עברית';

  @override
  String get languageSystemDefault => 'שפת המכשיר';

  @override
  String lastSeenOn(String time) {
    return 'נראה לאחרונה בתאריך $time';
  }

  @override
  String lastSeenRelative(String time) {
    return 'נראה לאחרונה $time';
  }

  @override
  String get loadMore => 'טען עוד';

  @override
  String get loading => 'טוען...';

  @override
  String get logout => 'התנתקות';

  @override
  String minutesAgo(int count) {
    return 'לפני $count דקות';
  }

  @override
  String get newMessage => 'הודעה חדשה';

  @override
  String get noCarNamesSelectedYet => 'עדיין לא נבחרו רכבים.';

  @override
  String get noConversationsYet => 'אין שיחות עדיין';

  @override
  String get noConversationsYetMessage => 'עדיין לא התחלת שיחות.';

  @override
  String get noMessagesYet => 'אין הודעות עדיין';

  @override
  String get offline => 'לא מחובר';

  @override
  String get online => 'מחובר';

  @override
  String get password => 'סיסמה';

  @override
  String get passwordHint => 'הזן סיסמה';

  @override
  String get passwordMinHint => 'לפחות 6 תווים';

  @override
  String get pickTheCarNamesYouSupplyPartsFor =>
      'בחר את שמות הרכבים שעבורם אתה מספק חלקים.';

  @override
  String get registerUsernameHint => 'בחר שם משתמש';

  @override
  String get remove => 'הסר';

  @override
  String get requests => 'בקשות';

  @override
  String get selectLanguage => 'בחירת שפה';

  @override
  String get setUpMarketplaceProfile => 'הגדר את פרופיל השוק שלך';

  @override
  String get signIn => 'התחברות';

  @override
  String get signingIn => 'מתחבר...';

  @override
  String get signInToBrowseSellerRequests =>
      'התחבר כדי לעיין בבקשות ספקים ולשוחח.';

  @override
  String get somethingWentWrong => 'משהו השתבש';

  @override
  String get supplierRole => 'ספק';

  @override
  String get suppliersCanPostRequests =>
      'ספקים יכולים לפרסם בקשות וקונים יכולים להתחיל שיחות.';

  @override
  String get theCarCatalogCouldNotBeLoaded =>
      'לא ניתן היה לטעון את קטלוג הרכבים.';

  @override
  String get thisMessageWasDeleted => 'הודעה זו נמחקה';

  @override
  String get tryAgain => 'נסה שוב';

  @override
  String get useAtLeastSixCharacters => 'השתמש בלפחות 6 תווים';

  @override
  String get username => 'שם משתמש';

  @override
  String get usernameHint => 'הזן שם משתמש';

  @override
  String get userRole => 'משתמש';
}
