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
  String get appTitle => 'MTA';

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
  String get profileCouldNotBeLoadedRightNow =>
      'לא ניתן לטעון את הפרופיל שלך כרגע.';

  @override
  String get keepYourProfileUpToDate => 'שמור על הפרופיל שלך מעודכן';

  @override
  String get supplierProfileIntro =>
      'עדכן את הפרטים שהקונים רואים, כוון את התראות הצ\'אט ובחר את דגמי הרכב שיש לך עבורם כבר חלקים במלאי.';

  @override
  String get buyerProfileIntro =>
      'עדכן את הפרטים שהספקים רואים והגדר כיצד התראות הצ\'אט יגיעו אליך.';

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
      'התחבר כדי לעיין בבקשות לקוחות ולשוחח.';

  @override
  String get somethingWentWrong => 'משהו השתבש';

  @override
  String get supplierRole => 'ספק';

  @override
  String get suppliersCanPostRequests =>
      'קונים יכולים לפרסם בקשות וספקים יכולים להתחיל שיחות.';

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
  String get chat => 'שוחח';

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
  String get cityLabel => 'עיר';

  @override
  String get filterByCarMake => 'סנן לפי יצרן';

  @override
  String get chatPushNotifications => 'התראות צ\'אט';

  @override
  String get chatPushNotificationsDescription =>
      'קבל התראה כשמישהו שולח הודעת צ\'אט.';

  @override
  String get showMessagePreview => 'הצג תצוגת מסר';

  @override
  String get showMessagePreviewDescription =>
      'כולל חלק מהודעת הצ\'אט בתוך ההתראה.';

  @override
  String get profileUpdatedSuccessfully => 'הפרופיל עודכן בהצלחה.';

  @override
  String get profilePhoto => 'תמונת פרופיל';

  @override
  String get newPhotoReadyMessage =>
      'תמונה חדשה מוכנה. שמור את הפרופיל כדי להחיל אותה.';

  @override
  String get choosePhotoForRequestsAndChats =>
      'בחר תמונה כדי שיהיה קל יותר לזהות אותך בבקשות ובצ\'אט.';

  @override
  String get chooseAnotherPhoto => 'בחר תמונה אחרת';

  @override
  String get changePhoto => 'שנה תמונה';

  @override
  String get undoPhotoChange => 'בטל את שינוי התמונה';

  @override
  String get noCarModelsSelectedYetMessage =>
      'עדיין לא נבחרו דגמים. בחר את הדגמים שאתה תומך בהם מהקטלוג שלמטה.';

  @override
  String get deleteAccountTitle => 'מחק חשבון';

  @override
  String get deleteAccountPermanentMessage =>
      'פעולה זו תמחק לצמיתות את החשבון שלך, הבקשות, היסטוריית הצ\'אט והמכשירים הרשומים. אי אפשר לבטל את הפעולה.';

  @override
  String get accountDeletedSuccessfully => 'החשבון שלך נמחק.';

  @override
  String get accountCouldNotBeDeletedRightNow =>
      'לא ניתן למחוק את החשבון שלך כרגע.';

  @override
  String get deleteAccountDangerDescription =>
      'הסר את הפרופיל שלך ומחק לצמיתות את המידע השייך לחשבון אם אינך רוצה להשתמש באפליקציה.';

  @override
  String get pleaseWait => 'אנא המתן...';

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
  String get privacyPolicy => 'מדיניות פרטיות';

  @override
  String get privacyPolicyDescription =>
      'קרא כיצד האפליקציה אוספת, משתמשת ומגנה על הנתונים שלך.';

  @override
  String get openPrivacyPolicy => 'פתח את מדיניות הפרטיות';

  @override
  String get couldNotOpenPrivacyPolicy =>
      'לא ניתן לפתוח כעת את מדיניות הפרטיות.';

  @override
  String get requestUpdatedSuccessfully => 'הבקשה עודכנה בהצלחה.';

  @override
  String get requestCreatedSuccessfully => 'הבקשה נוצרה בהצלחה.';

  @override
  String get editRequestTitle => 'עריכת בקשה';

  @override
  String get createRequestTitle => 'צור בקשה';

  @override
  String get updateYourRequest => 'עדכן את הבקשה שלך';

  @override
  String get postNewRequest => 'פרסם בקשה חדשה';

  @override
  String get editRequestDescription =>
      'רענן את פרטי הבקשה ואת התמונות שאתה רוצה שקונים יראו.';

  @override
  String get createRequestDescription =>
      'צור בקשה שספקים יוכלו לעיין בה ולפתוח ממנה שיחות.';

  @override
  String get requestCreationBlocked => 'יצירת הבקשה חסומה';

  @override
  String get currentStatus => 'מצב נוכחי';

  @override
  String get initialStatus => 'מצב ראשוני';

  @override
  String currentStatusMessage(String status) {
    return 'הבקשה הזו מסומנת כעת כ-\"$status\".';
  }

  @override
  String initialStatusMessage(String status) {
    return 'בקשות חדשות יתחילו במצב \"$status\".';
  }

  @override
  String get requestTitleLabel => 'כותרת הבקשה';

  @override
  String get requestTitleHint => 'פגוש קדמי ל-Toyota Camry 2022';

  @override
  String get enterRequestTitle => 'הזן כותרת לבקשה.';

  @override
  String get requestDescriptionLabel => 'תיאור';

  @override
  String get requestDescriptionHint =>
      'תאר את המצב, המותג המועדף או פרטי הדגם שקונים צריכים לדעת.';

  @override
  String get addShortDescription => 'הוסף תיאור קצר.';

  @override
  String get carModelLabel => 'דגם רכב';

  @override
  String get carModelDescription =>
      'בחר את דגם הרכב המדויק של בקשה זו כדי שרק ספקים מתאימים יקבלו התראה.';

  @override
  String get addCarManually => 'הוסף רכב ידנית';

  @override
  String get addCarManuallyDescription =>
      'השתמש בזה אם אין את היצרן או הדגם בקטלוג.';

  @override
  String get carMakeLabel => 'יצרן רכב';

  @override
  String get carModelSearchLabel => 'חפש דגם רכב';

  @override
  String get carModelSearchHint => 'Audi RS7';

  @override
  String get clearCarModelSearch => 'נקה חיפוש';

  @override
  String get carModelSearchFailed => 'החיפוש אחר דגם הרכב נכשל. נסה שוב.';

  @override
  String get noMatchingCarModelsFound => 'לא נמצאו דגמי רכב מתאימים.';

  @override
  String get newCarMakeLabel => 'יצרן רכב חדש';

  @override
  String get newCarMakeHint => 'Toyota';

  @override
  String get newCarModelLabel => 'דגם רכב חדש';

  @override
  String get newCarModelHint => 'Camry 2024';

  @override
  String get cityOptionalLabel => 'עיר (אופציונלי)';

  @override
  String get cityOptionalHint => 'ריאד';

  @override
  String get addPhotos => 'הוסף תמונות';

  @override
  String get addMorePhotos => 'הוסף עוד תמונות';

  @override
  String get minPriceLabel => 'מחיר מינימלי';

  @override
  String get maxPriceLabel => 'מחיר מקסימלי';

  @override
  String get maxPriceMustBeGreaterThanMinPrice =>
      'המחיר המקסימלי חייב להיות גבוה יותר מהמחיר המינימלי.';

  @override
  String get saving => 'שומר...';

  @override
  String get saveChanges => 'שמור שינויים';

  @override
  String get enterValidNumber => 'הזן מספר תקין.';

  @override
  String get enterCarMake => 'הזן את יצרן הרכב.';

  @override
  String get enterCarModel => 'הזן את דגם הרכב.';

  @override
  String get enterCarMakeAndModelBeforeSaving =>
      'הזן גם את יצרן הרכב וגם את הדגם לפני שמירת הבקשה.';

  @override
  String get chooseCarModelBeforeSaving => 'בחר דגם רכב לפני שמירת הבקשה.';

  @override
  String get viewMyRequests => 'צפה בבקשות שלי';

  @override
  String get viewRequest => 'צפה בבקשה';

  @override
  String get dismiss => 'סגור';

  @override
  String get appUpdateAvailableMessage =>
      'גרסה חדשה של MTA זמינה. עדכן כעת כדי לקבל את התכונות והשיפורים החדשים.';

  @override
  String get updateNow => 'עדכן כעת';

  @override
  String get later => 'מאוחר יותר';

  @override
  String get couldNotOpenAppStore => 'לא ניתן לפתוח כעת את חנות האפליקציות.';

  @override
  String whatsAppGreeting(String name) {
    return 'שלום $name';
  }
}
