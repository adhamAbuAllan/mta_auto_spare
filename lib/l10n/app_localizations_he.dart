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

  @override
  String get attachment => 'קובץ מצורף';

  @override
  String get attachedRequest => 'בקשה מצורפת';

  @override
  String get cancel => 'ביטול';

  @override
  String get copyMessage => 'העתק הודעה';

  @override
  String get deleteForAll => 'מחק לכולם';

  @override
  String get deleteMessage => 'מחק הודעה';

  @override
  String get deleteOnlyMe => 'מחק רק אצלי';

  @override
  String get deletedMessage => 'הודעה שנמחקה';

  @override
  String get discardVoiceMessage => 'בטל הודעה קולית';

  @override
  String get editMessage => 'ערוך הודעה';

  @override
  String get editMessageTitle => 'עריכת הודעה';

  @override
  String get edited => 'נערך';

  @override
  String fromPrice(String value) {
    return 'החל מ-$value';
  }

  @override
  String get messageCopied => 'ההודעה הועתקה.';

  @override
  String get messageCouldNotBeDeleted => 'לא ניתן למחוק את ההודעה.';

  @override
  String get messageCouldNotBeUpdated => 'לא ניתן לעדכן את ההודעה.';

  @override
  String get messageDeletedForEveryone => 'ההודעה נמחקה עבור כולם.';

  @override
  String get messageDeletedForYou => 'ההודעה נמחקה עבורך.';

  @override
  String get messageLabel => 'הודעה';

  @override
  String get messageUpdated => 'ההודעה עודכנה.';

  @override
  String get microphonePermissionRequiredForVoiceMessage =>
      'נדרשת הרשאת מיקרופון כדי להקליט הודעה קולית.';

  @override
  String get noMessagesYetMessage => 'התחל בברכה ופתח את השיחה.';

  @override
  String get noPriceRange => 'אין טווח מחירים';

  @override
  String get noVoiceMessageCaptured => 'לא נקלטה הודעה קולית.';

  @override
  String get pauseVoiceMessage => 'השהה הודעה קולית';

  @override
  String get photo => 'תמונה';

  @override
  String photosCount(int count) {
    return '$count תמונות';
  }

  @override
  String get playVoiceMessage => 'נגן הודעה קולית';

  @override
  String get preparingRecorder => 'מכין את המקליט...';

  @override
  String get recordVoiceMessage => 'הקלט הודעה קולית';

  @override
  String replyingTo(String name) {
    return 'משיב ל-$name';
  }

  @override
  String requestWithTitle(String title) {
    return 'בקשה: $title';
  }

  @override
  String get save => 'שמור';

  @override
  String get sendMessage => 'שלח הודעה';

  @override
  String get sendOrClearDraftBeforeVoiceMessage =>
      'שלח או נקה את הטיוטה הנוכחית לפני הקלטת הודעה קולית.';

  @override
  String get sending => 'שולח...';

  @override
  String get sendVoiceMessage => 'שלח הודעה קולית';

  @override
  String sentAttachmentsCount(int count) {
    return 'נשלחו $count קבצים מצורפים';
  }

  @override
  String get sharedRequest => 'שיתף בקשה';

  @override
  String get showOriginal => 'הצג מקור';

  @override
  String get showTranslation => 'הצג תרגום';

  @override
  String get typing => 'מקליד...';

  @override
  String get unableToPlayVoiceMessage => 'לא ניתן לנגן את ההודעה הקולית';

  @override
  String get unableToSeekVoiceMessage => 'לא ניתן לדלג בתוך ההודעה הקולית';

  @override
  String get updateYourMessage => 'עדכן את ההודעה שלך';

  @override
  String upToPrice(String value) {
    return 'עד $value';
  }

  @override
  String get uploadImages => 'העלה תמונות';

  @override
  String get voiceMessage => 'הודעה קולית';

  @override
  String get voiceMessageCouldNotBeSent => 'לא ניתן לשלוח את ההודעה הקולית.';

  @override
  String get voiceMessageDiscarded => 'ההודעה הקולית בוטלה.';

  @override
  String get voiceMessageDiscardFailed =>
      'לא ניתן היה לבטל את ההודעה הקולית בצורה תקינה.';

  @override
  String get voiceRecordingCouldNotStart =>
      'לא ניתן להתחיל הקלטה קולית במכשיר הזה.';

  @override
  String get writeAMessage => 'כתוב הודעה...';

  @override
  String get connecting => 'מתחבר...';

  @override
  String get liveUpdatesUnavailable => 'עדכונים חיים לא זמינים';

  @override
  String get reconnecting => 'מתחבר מחדש...';

  @override
  String get marketplaceUser => 'משתמש שוק';

  @override
  String get refreshRequests => 'רענן בקשות';

  @override
  String get browseRequestPostsFromOtherSellers =>
      'עיין בפוסטים של בקשות ממוכרים אחרים.';

  @override
  String get seeRequestPostsYouCreated => 'צפה בפוסטים של הבקשות שיצרת.';

  @override
  String get browseRequests => 'עיון בבקשות';

  @override
  String get myRequests => 'הבקשות שלי';

  @override
  String get noRequestsYet => 'אין בקשות עדיין';

  @override
  String get createFirstRequestPostMessage =>
      'צור את פוסט הבקשה הראשון שלך והוא יופיע כאן.';

  @override
  String get noSellerRequestsYet => 'אין עדיין בקשות ממוכרים';

  @override
  String get noSellerRequestsYetMessage =>
      'עדיין אין פוסטים של בקשות ממוכרים אחרים. משוך כדי לרענן מאוחר יותר.';

  @override
  String get createRequest => 'צור בקשה';

  @override
  String get deleteRequest => 'מחיקת בקשה';

  @override
  String deleteRequestConfirmation(String title) {
    return 'למחוק את \"$title\"? פוסט הבקשה הזה יוסר מהרשימה שלך.';
  }

  @override
  String get delete => 'מחק';

  @override
  String get edit => 'ערוך';

  @override
  String get deleting => 'מוחק...';

  @override
  String get chatSeller => 'שוחח עם המוכר';

  @override
  String get opening => 'פותח...';

  @override
  String get requestDeletedSuccessfully => 'הבקשה נמחקה בהצלחה.';

  @override
  String get couldNotDeleteRequest => 'לא ניתן למחוק את הבקשה.';

  @override
  String get couldNotOpenConversation => 'לא ניתן לפתוח את השיחה.';

  @override
  String get requestAttachedResendHint =>
      'הבקשה צורפה לעורך הצ\'אט כדי שתוכל לשלוח אותה שוב.';

  @override
  String get initialRequestCouldNotBeSentAutomatically =>
      'הצ\'אט נפתח, אך לא ניתן היה לשלוח את הבקשה הראשונית באופן אוטומטי.';

  @override
  String welcomeBackUser(String name) {
    return 'ברוך שובך, $name';
  }

  @override
  String get browse => 'עיון';

  @override
  String get mine => 'שלי';

  @override
  String get assigned => 'מוקצה';

  @override
  String get assignedRequests => 'בקשות מוקצות';

  @override
  String get allStatuses => 'כל המצבים';

  @override
  String get cityNotSet => 'העיר לא הוגדרה';

  @override
  String get thisRequestBelongsToYou => 'הבקשה הזו שייכת לך.';

  @override
  String get openChatWithSellerBehindRequest =>
      'פתח שיחה עם המוכר שמאחורי הבקשה הזו.';

  @override
  String get requestsYouCanManageNow => 'בקשות שאתה יכול לנהל כרגע.';

  @override
  String get noAssignedRequestsYet => 'עדיין אין בקשות מוקצות';

  @override
  String get noAssignedRequestsYetMessage =>
      'כשהבעלים יאשר את בקשת הגישה שלך, הבקשה תופיע כאן.';

  @override
  String get youCanManageThisRequestStatus => 'אתה יכול לנהל את מצב הבקשה הזו.';

  @override
  String get changeStatus => 'שנה מצב';

  @override
  String get requestStatusUpdated => 'מצב הבקשה עודכן.';

  @override
  String get couldNotUpdateRequestStatus => 'לא ניתן לעדכן את מצב הבקשה.';

  @override
  String get updatingStatus => 'מעדכן...';

  @override
  String get requestControl => 'בקרת בקשה';

  @override
  String get thisChatCanManageRequestStatus =>
      'הספק בשיחה זו יכול כעת לנהל את מצב הבקשה.';

  @override
  String get thisRequestIsAssignedToAnotherSupplier =>
      'הבקשה הזו מוקצה כרגע לספק אחר.';

  @override
  String get noAccessRequestForThisRequestYet =>
      'עדיין לא נשלחה בקשת גישה לבקשה זו.';

  @override
  String get youCanChangeThisRequestStatusNow =>
      'אתה יכול לשנות את מצב הבקשה כעת.';

  @override
  String get waitingForOwnerApproval => 'ממתין לאישור הבעלים לבקשת הגישה שלך.';

  @override
  String get ownerRejectedYourAccessRequest => 'הבעלים דחה את בקשת הגישה שלך.';

  @override
  String get askOwnerForStatusAccess => 'בקש מהבעלים הרשאה לנהל את מצב הבקשה.';

  @override
  String currentManager(String name) {
    return 'המנהל הנוכחי: $name';
  }

  @override
  String get approving => 'מאשר...';

  @override
  String get approveAccess => 'אשר גישה';

  @override
  String get rejectAccess => 'דחה גישה';

  @override
  String get sendingRequest => 'שולח...';

  @override
  String get requestAccess => 'בקש גישה';

  @override
  String get accessRequestPending => 'בקשת הגישה שלך ממתינה.';

  @override
  String get openAssignedRequestsToUpdateStatus =>
      'פתח בקשות מוקצות כדי לעדכן את המצב בכל עת.';

  @override
  String get accessRequestSent => 'בקשת הגישה נשלחה.';

  @override
  String get couldNotSendAccessRequest => 'לא ניתן לשלוח את בקשת הגישה.';

  @override
  String get accessRequestApproved => 'בקשת הגישה אושרה.';

  @override
  String get couldNotApproveAccessRequest => 'לא ניתן לאשר את בקשת הגישה.';

  @override
  String get accessRequestRejected => 'בקשת הגישה נדחתה.';

  @override
  String get couldNotRejectAccessRequest => 'לא ניתן לדחות את בקשת הגישה.';

  @override
  String get expandRequestControl => 'הצג את בקרות הבקשה';

  @override
  String get collapseRequestControl => 'הסתר את בקרות הבקשה';

  @override
  String get adminPanel => 'לוח בקרה';

  @override
  String get adminAccessRequired => 'רק חשבונות מנהל יכולים לפתוח את המסך הזה.';

  @override
  String get adminUsersTab => 'משתמשים';

  @override
  String get adminReportsTab => 'דיווחים';

  @override
  String get adminUsersCouldNotBeLoaded =>
      'לא ניתן לטעון כעת את רשימת המשתמשים.';

  @override
  String get adminReportsCouldNotBeLoaded => 'לא ניתן לטעון כעת את הדיווחים.';

  @override
  String get noUserReportsYet => 'אין עדיין דיווחי משתמשים.';

  @override
  String blockUserTitle(String name) {
    return 'חסום את $name';
  }

  @override
  String get blockUserAction => 'חסום משתמש';

  @override
  String get blockReasonLabel => 'סיבת החסימה';

  @override
  String get blockReasonHint => 'הוסף סיבה אופציונלית לפעולה זו.';

  @override
  String unblockUserTitle(String name) {
    return 'בטל חסימה של $name';
  }

  @override
  String unblockUserMessage(String name) {
    return 'לאפשר ל-$name לגשת שוב לאפליקציה?';
  }

  @override
  String get unblockUserAction => 'בטל חסימה';

  @override
  String get userBlocked => 'המשתמש נחסם.';

  @override
  String get userUnblocked => 'חסימת המשתמש בוטלה.';

  @override
  String get couldNotBlockUser => 'לא ניתן לחסום את המשתמש.';

  @override
  String get couldNotUnblockUser => 'לא ניתן לבטל את חסימת המשתמש.';

  @override
  String get reviewReportTitle => 'סקירת דיווח';

  @override
  String get reviewReportAction => 'סקירה';

  @override
  String get reportStatusLabel => 'סטטוס הדיווח';

  @override
  String get reportStatusOpen => 'פתוח';

  @override
  String get reportStatusReviewed => 'נבדק';

  @override
  String get reportStatusDismissed => 'נדחה';

  @override
  String get reportStatusActioned => 'טופל';

  @override
  String get reportUpdated => 'הדיווח עודכן.';

  @override
  String get couldNotUpdateReport => 'לא ניתן לעדכן את הדיווח.';

  @override
  String get adminNotesLabel => 'הערות מנהל';

  @override
  String get adminNotesHint => 'הוסף הערות לצוות הניהול.';

  @override
  String get userBlockedStatus => 'חסום';

  @override
  String get userActiveStatus => 'פעיל';

  @override
  String get adminCurrentAccount => 'זה החשבון הנוכחי שלך.';

  @override
  String get adminRole => 'מנהל';

  @override
  String reportCardTitle(String name) {
    return 'דיווח על $name';
  }

  @override
  String reportedByLabel(String name) {
    return 'דווח על ידי $name';
  }

  @override
  String reportCreatedAt(String time) {
    return 'נוצר $time';
  }

  @override
  String reportReviewedAt(String time) {
    return 'נבדק $time';
  }

  @override
  String get profileTitle => 'פרופיל';

  @override
  String get profileLoadError => 'לא ניתן לטעון כעת את הפרופיל.';

  @override
  String get contactDetails => 'פרטי קשר';

  @override
  String get phone => 'טלפון';

  @override
  String get quickActions => 'פעולות מהירות';

  @override
  String get quickActionsDescription =>
      'התחל שיחה ישירה או פתח WhatsApp עם מספר הטלפון של הספק.';

  @override
  String get openingChat => 'פותח צ\'אט...';

  @override
  String get chatAction => 'צ\'אט';

  @override
  String get openingWhatsApp => 'פותח WhatsApp...';

  @override
  String get whatsAppAction => 'WhatsApp';

  @override
  String get supplierCarsTitle => 'הרכבים שהספק הזה עובד איתם';

  @override
  String get supplierCarsDescription => 'אלו מותגי הרכב שנבחרו בפרופיל הספק.';

  @override
  String ratingLabel(String value) {
    return 'דירוג $value';
  }

  @override
  String joinedLabel(String time) {
    return 'הצטרף $time';
  }

  @override
  String get reportUserSectionTitle => 'דווח על משתמש';

  @override
  String get reportUserSectionBody =>
      'שלח דיווח בטיחות אם המשתמש הזה מנצל לרעה את הצ\'אט או את בקשות הגישה.';

  @override
  String get reportUserAction => 'דווח';

  @override
  String get sendingReport => 'שולח דיווח...';

  @override
  String reportUserDialogTitle(String name) {
    return 'דווח על $name';
  }

  @override
  String get reportReasonLabel => 'סיבה';

  @override
  String get reportDetailsLabel => 'פרטים';

  @override
  String get reportDetailsHint => 'הוסף כל מידע שיעזור למנהל לבדוק את הדיווח.';

  @override
  String get sendReport => 'שלח דיווח';

  @override
  String get userReportSubmitted => 'הדיווח נשלח.';

  @override
  String get couldNotSendUserReport => 'לא ניתן לשלוח את הדיווח.';

  @override
  String get reportReasonSpam => 'ספאם';

  @override
  String get reportReasonFraud => 'הונאה';

  @override
  String get reportReasonHarassment => 'הטרדה';

  @override
  String get reportReasonImpersonation => 'התחזות';

  @override
  String get reportReasonOther => 'אחר';

  @override
  String get couldNotOpenChatRightNow => 'לא ניתן לפתוח כעת את הצ\'אט.';

  @override
  String get whatsAppPhoneNotReady => 'מספר הטלפון הזה אינו מתאים ל-WhatsApp.';

  @override
  String get couldNotOpenWhatsApp => 'לא ניתן לפתוח כעת את WhatsApp.';

  @override
  String whatsAppGreeting(String name) {
    return 'שלום $name';
  }
}
