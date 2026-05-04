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

  @override
  String get attachment => 'مرفق';

  @override
  String get attachedRequest => 'طلب مرفق';

  @override
  String get cancel => 'إلغاء';

  @override
  String get copyMessage => 'نسخ الرسالة';

  @override
  String get deleteForAll => 'حذف للجميع';

  @override
  String get deleteMessage => 'حذف الرسالة';

  @override
  String get deleteOnlyMe => 'حذف لدي فقط';

  @override
  String get deletedMessage => 'رسالة محذوفة';

  @override
  String get discardVoiceMessage => 'تجاهل الرسالة الصوتية';

  @override
  String get editMessage => 'تعديل الرسالة';

  @override
  String get editMessageTitle => 'تعديل الرسالة';

  @override
  String get edited => 'تم التعديل';

  @override
  String fromPrice(String value) {
    return 'ابتداءً من $value';
  }

  @override
  String get messageCopied => 'تم نسخ الرسالة.';

  @override
  String get messageCouldNotBeDeleted => 'تعذر حذف الرسالة.';

  @override
  String get messageCouldNotBeUpdated => 'تعذر تحديث الرسالة.';

  @override
  String get messageDeletedForEveryone => 'تم حذف الرسالة للجميع.';

  @override
  String get messageDeletedForYou => 'تم حذف الرسالة لديك.';

  @override
  String get messageLabel => 'رسالة';

  @override
  String get messageUpdated => 'تم تحديث الرسالة.';

  @override
  String get microphonePermissionRequiredForVoiceMessage =>
      'يلزم إذن الميكروفون لتسجيل رسالة صوتية.';

  @override
  String get noMessagesYetMessage => 'ابدأ بالتحية وابدأ المحادثة.';

  @override
  String get noPriceRange => 'لا يوجد نطاق سعر';

  @override
  String get noVoiceMessageCaptured => 'لم يتم التقاط أي رسالة صوتية.';

  @override
  String get pauseVoiceMessage => 'إيقاف الرسالة الصوتية مؤقتًا';

  @override
  String get photo => 'صورة';

  @override
  String photosCount(int count) {
    return '$count صور';
  }

  @override
  String get playVoiceMessage => 'تشغيل الرسالة الصوتية';

  @override
  String get preparingRecorder => 'جارٍ تجهيز المسجل...';

  @override
  String get recordVoiceMessage => 'تسجيل رسالة صوتية';

  @override
  String replyingTo(String name) {
    return 'جارٍ الرد على $name';
  }

  @override
  String requestWithTitle(String title) {
    return 'الطلب: $title';
  }

  @override
  String get save => 'حفظ';

  @override
  String get sendMessage => 'إرسال الرسالة';

  @override
  String get sendOrClearDraftBeforeVoiceMessage =>
      'أرسل المسودة الحالية أو امسحها قبل تسجيل رسالة صوتية.';

  @override
  String get sending => 'جارٍ الإرسال...';

  @override
  String get sendVoiceMessage => 'إرسال الرسالة الصوتية';

  @override
  String sentAttachmentsCount(int count) {
    return 'تم إرسال $count مرفق';
  }

  @override
  String get sharedRequest => 'تمت مشاركة طلب';

  @override
  String get showOriginal => 'إظهار الأصل';

  @override
  String get showTranslation => 'إظهار الترجمة';

  @override
  String get typing => 'يكتب...';

  @override
  String get unableToPlayVoiceMessage => 'تعذر تشغيل الرسالة الصوتية';

  @override
  String get unableToSeekVoiceMessage => 'تعذر التقديم داخل الرسالة الصوتية';

  @override
  String get updateYourMessage => 'حدّث رسالتك';

  @override
  String upToPrice(String value) {
    return 'حتى $value';
  }

  @override
  String get uploadImages => 'رفع الصور';

  @override
  String get voiceMessage => 'رسالة صوتية';

  @override
  String get voiceMessageCouldNotBeSent => 'تعذر إرسال الرسالة الصوتية.';

  @override
  String get voiceMessageDiscarded => 'تم تجاهل الرسالة الصوتية.';

  @override
  String get voiceMessageDiscardFailed =>
      'تعذر تجاهل الرسالة الصوتية بشكل صحيح.';

  @override
  String get voiceRecordingCouldNotStart =>
      'تعذر بدء تسجيل الصوت على هذا الجهاز.';

  @override
  String get writeAMessage => 'اكتب رسالة...';

  @override
  String get connecting => 'جارٍ الاتصال...';

  @override
  String get liveUpdatesUnavailable => 'التحديثات المباشرة غير متاحة';

  @override
  String get reconnecting => 'جارٍ إعادة الاتصال...';

  @override
  String get marketplaceUser => 'مستخدم السوق';

  @override
  String get refreshRequests => 'تحديث الطلبات';

  @override
  String get browseRequestPostsFromOtherSellers =>
      'تصفح منشورات الطلبات من البائعين الآخرين.';

  @override
  String get seeRequestPostsYouCreated => 'شاهد منشورات الطلبات التي أنشأتها.';

  @override
  String get browseRequests => 'تصفح الطلبات';

  @override
  String get myRequests => 'طلباتي';

  @override
  String get noRequestsYet => 'لا توجد طلبات بعد';

  @override
  String get createFirstRequestPostMessage => 'أنشئ أول منشور طلب وسيظهر هنا.';

  @override
  String get noSellerRequestsYet => 'لا توجد طلبات بائعين بعد';

  @override
  String get noSellerRequestsYetMessage =>
      'لا توجد منشورات طلب من البائعين الآخرين بعد. اسحب للتحديث لاحقًا.';

  @override
  String get createRequest => 'إنشاء طلب';

  @override
  String get deleteRequest => 'حذف الطلب';

  @override
  String deleteRequestConfirmation(String title) {
    return 'حذف \"$title\"؟ ستتم إزالة منشور الطلب هذا من قائمتك.';
  }

  @override
  String get delete => 'حذف';

  @override
  String get edit => 'تعديل';

  @override
  String get deleting => 'جارٍ الحذف...';

  @override
  String get chatSeller => 'محادثة البائع';

  @override
  String get opening => 'جارٍ الفتح...';

  @override
  String get requestDeletedSuccessfully => 'تم حذف الطلب بنجاح.';

  @override
  String get couldNotDeleteRequest => 'تعذر حذف الطلب.';

  @override
  String get couldNotOpenConversation => 'تعذر فتح المحادثة.';

  @override
  String get requestAttachedResendHint =>
      'تم إرفاق الطلب في محرر الدردشة حتى تتمكن من إعادة إرساله.';

  @override
  String get initialRequestCouldNotBeSentAutomatically =>
      'تم فتح الدردشة، لكن تعذر إرسال الطلب الأول تلقائيًا.';

  @override
  String welcomeBackUser(String name) {
    return 'مرحبًا بعودتك، $name';
  }

  @override
  String get browse => 'تصفح';

  @override
  String get mine => 'طلباتي';

  @override
  String get assigned => 'مسندة';

  @override
  String get assignedRequests => 'الطلبات المسندة';

  @override
  String get allStatuses => 'كل الحالات';

  @override
  String get cityNotSet => 'المدينة غير محددة';

  @override
  String get thisRequestBelongsToYou => 'هذا الطلب يخصك.';

  @override
  String get openChatWithSellerBehindRequest =>
      'افتح محادثة مع البائع صاحب هذا الطلب.';

  @override
  String get requestsYouCanManageNow => 'الطلبات التي يمكنك إدارتها الآن.';

  @override
  String get noAssignedRequestsYet => 'لا توجد طلبات مسندة بعد';

  @override
  String get noAssignedRequestsYetMessage =>
      'عندما يوافق المالك على طلب الوصول سيظهر الطلب هنا.';

  @override
  String get youCanManageThisRequestStatus => 'يمكنك إدارة حالة هذا الطلب.';

  @override
  String get changeStatus => 'تغيير الحالة';

  @override
  String get requestStatusUpdated => 'تم تحديث حالة الطلب.';

  @override
  String get couldNotUpdateRequestStatus => 'تعذر تحديث حالة الطلب.';

  @override
  String get updatingStatus => 'جارٍ التحديث...';

  @override
  String get requestControl => 'التحكم في الطلب';

  @override
  String get thisChatCanManageRequestStatus =>
      'يمكن للمورد في هذه الدردشة إدارة حالة هذا الطلب الآن.';

  @override
  String get thisRequestIsAssignedToAnotherSupplier =>
      'هذا الطلب مسند حاليًا إلى مورد آخر.';

  @override
  String get noAccessRequestForThisRequestYet =>
      'لم يتم إرسال طلب وصول لهذا الطلب بعد.';

  @override
  String get youCanChangeThisRequestStatusNow =>
      'يمكنك تغيير حالة هذا الطلب الآن.';

  @override
  String get waitingForOwnerApproval =>
      'في انتظار موافقة المالك على طلب الوصول.';

  @override
  String get ownerRejectedYourAccessRequest => 'رفض المالك طلب وصولك.';

  @override
  String get askOwnerForStatusAccess =>
      'اطلب من المالك إذنًا لإدارة حالة هذا الطلب.';

  @override
  String currentManager(String name) {
    return 'المدير الحالي: $name';
  }

  @override
  String get approving => 'جارٍ الموافقة...';

  @override
  String get approveAccess => 'موافقة على الوصول';

  @override
  String get rejectAccess => 'رفض الوصول';

  @override
  String get sendingRequest => 'جارٍ الإرسال...';

  @override
  String get requestAccess => 'طلب الوصول';

  @override
  String get accessRequestPending => 'طلب الوصول الخاص بك قيد الانتظار.';

  @override
  String get openAssignedRequestsToUpdateStatus =>
      'افتح الطلبات المسندة لتحديث الحالة في أي وقت.';

  @override
  String get accessRequestSent => 'تم إرسال طلب الوصول.';

  @override
  String get couldNotSendAccessRequest => 'تعذر إرسال طلب الوصول.';

  @override
  String get accessRequestApproved => 'تمت الموافقة على طلب الوصول.';

  @override
  String get couldNotApproveAccessRequest => 'تعذرت الموافقة على طلب الوصول.';

  @override
  String get accessRequestRejected => 'تم رفض طلب الوصول.';

  @override
  String get couldNotRejectAccessRequest => 'تعذر رفض طلب الوصول.';

  @override
  String get expandRequestControl => 'إظهار أدوات التحكم بالطلب';

  @override
  String get collapseRequestControl => 'إخفاء أدوات التحكم بالطلب';

  @override
  String get adminPanel => 'لوحة المشرف';

  @override
  String get adminAccessRequired => 'يمكن فقط لحسابات المشرفين فتح هذه اللوحة.';

  @override
  String get adminUsersTab => 'المستخدمون';

  @override
  String get adminReportsTab => 'البلاغات';

  @override
  String get adminUsersCouldNotBeLoaded => 'تعذر تحميل قائمة المستخدمين الآن.';

  @override
  String get adminReportsCouldNotBeLoaded => 'تعذر تحميل البلاغات الآن.';

  @override
  String get noUserReportsYet => 'لا توجد بلاغات مستخدمين بعد.';

  @override
  String blockUserTitle(String name) {
    return 'حظر $name';
  }

  @override
  String get blockUserAction => 'حظر المستخدم';

  @override
  String get blockReasonLabel => 'سبب الحظر';

  @override
  String get blockReasonHint => 'أضف سببًا اختياريًا لهذا الإجراء.';

  @override
  String unblockUserTitle(String name) {
    return 'إلغاء حظر $name';
  }

  @override
  String unblockUserMessage(String name) {
    return 'السماح لـ $name بالوصول إلى التطبيق مرة أخرى؟';
  }

  @override
  String get unblockUserAction => 'إلغاء الحظر';

  @override
  String get userBlocked => 'تم حظر المستخدم.';

  @override
  String get userUnblocked => 'تم إلغاء حظر المستخدم.';

  @override
  String get couldNotBlockUser => 'تعذر حظر المستخدم.';

  @override
  String get couldNotUnblockUser => 'تعذر إلغاء حظر المستخدم.';

  @override
  String get reviewReportTitle => 'مراجعة البلاغ';

  @override
  String get reviewReportAction => 'مراجعة';

  @override
  String get reportStatusLabel => 'حالة البلاغ';

  @override
  String get reportStatusOpen => 'مفتوح';

  @override
  String get reportStatusReviewed => 'تمت مراجعته';

  @override
  String get reportStatusDismissed => 'تم تجاهله';

  @override
  String get reportStatusActioned => 'تم اتخاذ إجراء';

  @override
  String get reportUpdated => 'تم تحديث البلاغ.';

  @override
  String get couldNotUpdateReport => 'تعذر تحديث البلاغ.';

  @override
  String get adminNotesLabel => 'ملاحظات المشرف';

  @override
  String get adminNotesHint => 'أضف ملاحظات لمراجعة البلاغ.';

  @override
  String get userBlockedStatus => 'محظور';

  @override
  String get userActiveStatus => 'نشط';

  @override
  String get adminCurrentAccount => 'هذا هو حسابك الحالي.';

  @override
  String get adminRole => 'مشرف';

  @override
  String reportCardTitle(String name) {
    return 'بلاغ عن $name';
  }

  @override
  String reportedByLabel(String name) {
    return 'تم الإبلاغ بواسطة $name';
  }

  @override
  String reportCreatedAt(String time) {
    return 'أُنشئ $time';
  }

  @override
  String reportReviewedAt(String time) {
    return 'تمت مراجعته $time';
  }

  @override
  String get profileTitle => 'الملف الشخصي';

  @override
  String get profileLoadError => 'تعذر تحميل هذا الملف الشخصي الآن.';

  @override
  String get contactDetails => 'بيانات التواصل';

  @override
  String get phone => 'الهاتف';

  @override
  String get quickActions => 'إجراءات سريعة';

  @override
  String get quickActionsDescription =>
      'ابدأ محادثة مباشرة أو افتح واتساب باستخدام رقم هاتف المورد.';

  @override
  String get openingChat => 'جارٍ فتح المحادثة...';

  @override
  String get chatAction => 'محادثة';

  @override
  String get openingWhatsApp => 'جارٍ فتح واتساب...';

  @override
  String get whatsAppAction => 'واتساب';

  @override
  String get supplierCarsTitle => 'السيارات التي يعمل عليها هذا المورد';

  @override
  String get supplierCarsDescription =>
      'هذه هي علامات السيارات المحددة في ملف المورد.';

  @override
  String ratingLabel(String value) {
    return 'التقييم $value';
  }

  @override
  String joinedLabel(String time) {
    return 'انضم $time';
  }

  @override
  String get reportUserSectionTitle => 'الإبلاغ عن مستخدم';

  @override
  String get reportUserSectionBody =>
      'أرسل بلاغًا إذا كان هذا المستخدم يسيء استخدام الدردشة أو طلبات الوصول.';

  @override
  String get reportUserAction => 'إبلاغ';

  @override
  String get sendingReport => 'جارٍ إرسال البلاغ...';

  @override
  String reportUserDialogTitle(String name) {
    return 'إبلاغ عن $name';
  }

  @override
  String get reportReasonLabel => 'السبب';

  @override
  String get reportDetailsLabel => 'التفاصيل';

  @override
  String get reportDetailsHint =>
      'أضف أي معلومات تساعد المشرف على مراجعة البلاغ.';

  @override
  String get sendReport => 'إرسال البلاغ';

  @override
  String get userReportSubmitted => 'تم إرسال البلاغ.';

  @override
  String get couldNotSendUserReport => 'تعذر إرسال البلاغ.';

  @override
  String get reportReasonSpam => 'رسائل مزعجة';

  @override
  String get reportReasonFraud => 'احتيال';

  @override
  String get reportReasonHarassment => 'مضايقة';

  @override
  String get reportReasonImpersonation => 'انتحال صفة';

  @override
  String get reportReasonOther => 'أخرى';

  @override
  String get couldNotOpenChatRightNow => 'تعذر فتح المحادثة الآن.';

  @override
  String get whatsAppPhoneNotReady => 'رقم الهاتف هذا غير جاهز لواتساب.';

  @override
  String get couldNotOpenWhatsApp => 'تعذر فتح واتساب الآن.';

  @override
  String whatsAppGreeting(String name) {
    return 'مرحبًا $name';
  }
}
