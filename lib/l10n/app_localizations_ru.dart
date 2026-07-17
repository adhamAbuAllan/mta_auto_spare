// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String accountCreatedFor(String username) {
    return 'Аккаунт создан для $username';
  }

  @override
  String get accountRole => 'Роль аккаунта';

  @override
  String get add => 'Добавить';

  @override
  String get allAvailableCarNamesAlreadySelected =>
      'Все доступные названия автомобилей уже выбраны.';

  @override
  String get appTitle => 'МТА Автозапчасти';

  @override
  String get backend => 'Бэкэнд';

  @override
  String get carCatalogCouldNotBeLoadedRightNow =>
      'Не удалось загрузить каталог автомобилей.';

  @override
  String get carName => 'Название автомобиля';

  @override
  String get carsIHavePartsFor =>
      'Автомобили, для которых я поставляю запчасти';

  @override
  String get changeLanguage => 'Изменить язык';

  @override
  String get chats => 'Чаты';

  @override
  String get chooseAUsername => 'Выберите имя пользователя';

  @override
  String conversationNumber(int id) {
    return 'Разговор #$id';
  }

  @override
  String get conversations => 'Разговоры';

  @override
  String get createAccount => 'Создать учетную запись';

  @override
  String get createNewAccount => 'Создать новую учетную запись';

  @override
  String get creating => 'Создание...';

  @override
  String daysAgo(int count) {
    return '$count дней назад';
  }

  @override
  String get editProfile => 'Редактировать профиль';

  @override
  String get profileCouldNotBeLoadedRightNow =>
      'Ваш профиль не может быть загружен прямо сейчас.';

  @override
  String get keepYourProfileUpToDate =>
      'Поддерживайте свой профиль в актуальном состоянии';

  @override
  String get supplierProfileIntro =>
      'Обновляйте сведения, которые видят клиенты, управляйте уведомлениями в чате и выбирайте автомобили, для которых вы можете поставлять запчасти.';

  @override
  String get buyerProfileIntro =>
      'Обновите сведения, которые поставщики видят, когда вы создаете запросы или общаетесь с ними.';

  @override
  String get email => 'электронная почта';

  @override
  String get emailHint => 'имя@example.com';

  @override
  String get enterAValidEmailAddress =>
      'Введите действительный адрес электронной почты';

  @override
  String get enterPassword => 'Введите пароль';

  @override
  String get enterUsername => 'Введите имя пользователя';

  @override
  String get enterYourEmail => 'Введите адрес электронной почты';

  @override
  String get enterYourFullName => 'Введите свое полное имя';

  @override
  String get fullName => 'Полное имя';

  @override
  String get fullNameHint => 'Введите свое полное имя';

  @override
  String hoursAgo(int count) {
    return '$count часов назад';
  }

  @override
  String get justNow => 'только что';

  @override
  String get language => 'Язык';

  @override
  String get languageArabic => 'عربية';

  @override
  String get languageEnglish => 'английский';

  @override
  String get languageHebrew => 'עברית';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageSystemDefault => 'Система по умолчанию';

  @override
  String lastSeenOn(String time) {
    return 'Последний раз видели на $time';
  }

  @override
  String lastSeenRelative(String time) {
    return 'Последний раз был на связи $time';
  }

  @override
  String get loadMore => 'Загрузить больше';

  @override
  String get loading => 'Загрузка...';

  @override
  String get logout => 'Выход из системы';

  @override
  String minutesAgo(int count) {
    return '$count минут назад';
  }

  @override
  String get newMessage => 'Новое сообщение';

  @override
  String get noCarNamesSelectedYet => 'Названия автомобилей пока не выбраны.';

  @override
  String get noConversationsYet => 'Пока нет разговоров';

  @override
  String get noConversationsYetMessage =>
      'Вы еще не начали ни одного разговора.';

  @override
  String get noMessagesYet => 'Сообщений пока нет';

  @override
  String get offline => 'Оффлайн';

  @override
  String get online => 'Онлайн';

  @override
  String get password => 'Пароль';

  @override
  String get passwordHint => 'Введите пароль';

  @override
  String get passwordMinHint => 'Минимум 6 символов';

  @override
  String get pickTheCarNamesYouSupplyPartsFor =>
      'Выберите автомобили, которые вы поддерживаете. Мы используем это, чтобы уведомлять вас о соответствующих запросах на запасные части.';

  @override
  String get registerUsernameHint => 'Выберите имя пользователя';

  @override
  String get remove => 'Удалить';

  @override
  String get requests => 'Запросы';

  @override
  String get selectLanguage => 'Выберите язык';

  @override
  String get setUpMarketplaceProfile =>
      'Настройте свой профиль на торговой площадке';

  @override
  String get signIn => 'Войти';

  @override
  String get signingIn => 'Вход в систему...';

  @override
  String get signInToBrowseSellerRequests =>
      'Войдите, чтобы запросить запасные части, пообщаться с поставщиками и управлять своими предложениями.';

  @override
  String get somethingWentWrong => 'Что-то пошло не так';

  @override
  String get supplierRole => 'Поставщик';

  @override
  String get suppliersCanPostRequests =>
      'Клиенты запрашивают запасные части. Поставщики выбирают поддерживаемые автомобили и получают соответствующие возможности.';

  @override
  String get theCarCatalogCouldNotBeLoaded =>
      'Не удалось загрузить каталог автомобилей.';

  @override
  String get thisMessageWasDeleted => 'Это сообщение было удалено';

  @override
  String get tryAgain => 'Попробуйте еще раз';

  @override
  String get useAtLeastSixCharacters => 'Используйте не менее шести символов';

  @override
  String get username => 'Имя пользователя';

  @override
  String get usernameHint => 'Введите имя пользователя';

  @override
  String get userRole => 'Клиент';

  @override
  String get attachment => 'Приложение';

  @override
  String get attachedRequest => 'Прикрепленный запрос';

  @override
  String get cancel => 'Отмена';

  @override
  String get copyMessage => 'Копировать сообщение';

  @override
  String get deleteForAll => 'Удалить для всех';

  @override
  String get deleteMessage => 'Удалить сообщение';

  @override
  String get deleteOnlyMe => 'Удалить только для меня';

  @override
  String get deletedMessage => 'Удаленное сообщение';

  @override
  String get discardVoiceMessage => 'Отменить голосовое сообщение';

  @override
  String get editMessage => 'Редактировать сообщение';

  @override
  String get editMessageTitle => 'Редактировать сообщение';

  @override
  String get edited => 'Отредактировано';

  @override
  String fromPrice(String value) {
    return 'От $value';
  }

  @override
  String get messageCopied => 'Сообщение скопировано.';

  @override
  String get messageCouldNotBeDeleted => 'Сообщение не удалось удалить.';

  @override
  String get messageCouldNotBeUpdated => 'Сообщение не удалось обновить.';

  @override
  String get messageDeletedForEveryone => 'Сообщение удалено для всех.';

  @override
  String get messageDeletedForYou => 'Сообщение удалено для вас.';

  @override
  String get messageLabel => 'Сообщение';

  @override
  String get messageUpdated => 'Сообщение обновлено.';

  @override
  String get microphonePermissionRequiredForVoiceMessage =>
      'Для записи голосового сообщения требуется разрешение микрофона.';

  @override
  String get noMessagesYetMessage => 'Поздоровайтесь и начните разговор.';

  @override
  String get noPriceRange => 'Нет ценового диапазона';

  @override
  String get noVoiceMessageCaptured =>
      'Ни одно голосовое сообщение не было записано.';

  @override
  String get pauseVoiceMessage => 'Приостановить голосовое сообщение';

  @override
  String get photo => 'Фото';

  @override
  String photosCount(int count) {
    return '$count фотографии';
  }

  @override
  String get playVoiceMessage => 'Воспроизвести голосовое сообщение';

  @override
  String get preparingRecorder => 'Готовим магнитолу...';

  @override
  String get recordVoiceMessage => 'Записать голосовое сообщение';

  @override
  String replyingTo(String name) {
    return 'Ответ на $name';
  }

  @override
  String requestWithTitle(String title) {
    return 'Запрос: $title';
  }

  @override
  String get save => 'Сохранить';

  @override
  String get sendMessage => 'Отправить сообщение';

  @override
  String get sendOrClearDraftBeforeVoiceMessage =>
      'Отправьте или очистите текущий черновик перед записью голосового сообщения.';

  @override
  String get sending => 'Отправка...';

  @override
  String get sendVoiceMessage => 'Отправить голосовое сообщение';

  @override
  String sentAttachmentsCount(int count) {
    return 'Отправлены вложения $count.';
  }

  @override
  String get sharedRequest => 'Поделился запросом';

  @override
  String get showOriginal => 'Показать оригинал';

  @override
  String get showTranslation => 'Показать перевод';

  @override
  String get realTimeTranslationFeatureAnnouncement =>
      'Новая функция: теперь доступен перевод в реальном времени. Сообщения автоматически переводятся между участниками чата, использующими разные языки.';

  @override
  String get typing => 'Ввод...';

  @override
  String get unableToPlayVoiceMessage =>
      'Невозможно воспроизвести голосовое сообщение';

  @override
  String get unableToSeekVoiceMessage => 'Невозможно найти голосовое сообщение';

  @override
  String get updateYourMessage => 'Обновите свое сообщение';

  @override
  String upToPrice(String value) {
    return 'До $value';
  }

  @override
  String get uploadImages => 'Загрузить изображения';

  @override
  String get voiceMessage => 'Голосовое сообщение';

  @override
  String get voiceMessageCouldNotBeSent =>
      'Голосовое сообщение не может быть отправлено.';

  @override
  String get voiceMessageDiscarded => 'Голосовое сообщение удалено.';

  @override
  String get voiceMessageDiscardFailed =>
      'Голосовое сообщение не удалось полностью удалить.';

  @override
  String get voiceRecordingCouldNotStart =>
      'Не удалось начать запись голоса на этом устройстве.';

  @override
  String get writeAMessage => 'Напишите сообщение...';

  @override
  String get connecting => 'Подключение...';

  @override
  String get liveUpdatesUnavailable => 'Оперативные обновления недоступны.';

  @override
  String get reconnecting => 'Повторное подключение...';

  @override
  String get marketplaceUser => 'Пользователь торговой площадки';

  @override
  String get refreshRequests => 'Обновить запросы';

  @override
  String get browseRequestPostsFromOtherSellers =>
      'Просмотрите открытые запросы на запасные части от клиентов.';

  @override
  String get seeRequestPostsYouCreated =>
      'Просмотрите созданные вами запросы на запасные части.';

  @override
  String get browseRequests => 'Открытые запросы';

  @override
  String get myRequests => 'Мои запросы';

  @override
  String get noRequestsYet => 'Запросов пока нет';

  @override
  String get createFirstRequestPostMessage =>
      'Создайте свой первый запрос на запасные части, и поставщики смогут связаться с вами.';

  @override
  String get noSellerRequestsYet => 'Открытых запросов пока нет';

  @override
  String get noSellerRequestsYetMessage =>
      'На данный момент открытых заявок на запасные части нет. Потяните, чтобы обновить позже.';

  @override
  String get createRequest => 'Создать запрос';

  @override
  String get deleteRequest => 'Удалить запрос';

  @override
  String deleteRequestConfirmation(String title) {
    return 'Удалить \"$title\"? Этот пост-запрос будет удален из вашего списка.';
  }

  @override
  String get delete => 'Удалить';

  @override
  String get edit => 'Редактировать';

  @override
  String get deleting => 'Удаление...';

  @override
  String get chat => 'Чат с клиентом';

  @override
  String get opening => 'Открытие...';

  @override
  String get requestDeletedSuccessfully => 'Запрос успешно удален.';

  @override
  String get couldNotDeleteRequest => 'Не удалось удалить запрос.';

  @override
  String get couldNotOpenConversation => 'Не удалось открыть разговор.';

  @override
  String get requestAttachedResendHint =>
      'Запрос прикрепляется в композиторе чата, поэтому вы можете отправить его повторно.';

  @override
  String get initialRequestCouldNotBeSentAutomatically =>
      'Чат открылся, но первоначальный запрос не удалось отправить автоматически.';

  @override
  String welcomeBackUser(String name) {
    return 'С возвращением, $name';
  }

  @override
  String get browse => 'Обзор';

  @override
  String get mine => 'Мой';

  @override
  String get assigned => 'Назначено';

  @override
  String get assignedRequests => 'Обработка запросов';

  @override
  String get allStatuses => 'Все статусы';

  @override
  String get cityNotSet => 'Город не установлен';

  @override
  String get thisRequestBelongsToYou =>
      'Ваш запрос открыт для предложений поставщиков.';

  @override
  String get openChatWithSellerBehindRequest =>
      'Пообщайтесь с клиентом и предложите эту запчасть.';

  @override
  String get requestsYouCanManageNow =>
      'Запросы клиентов, принятые вами для обработки.';

  @override
  String get noAssignedRequestsYet => 'Принятых запросов пока нет';

  @override
  String get noAssignedRequestsYetMessage =>
      'Когда клиент согласится обработать запрос, он появится здесь.';

  @override
  String get youCanManageThisRequestStatus =>
      'Клиент принял вас для обработки этого запроса.';

  @override
  String get changeStatus => 'Изменить статус';

  @override
  String get requestStatusUpdated => 'Статус запроса обновлен.';

  @override
  String get couldNotUpdateRequestStatus =>
      'Не удалось обновить статус запроса.';

  @override
  String get updatingStatus => 'Обновление...';

  @override
  String get requestControl => 'Приемка поставщика';

  @override
  String get thisChatCanManageRequestStatus =>
      'Вы приняли этого поставщика. Запрос больше не является публичным.';

  @override
  String get thisRequestIsAssignedToAnotherSupplier =>
      'Этот запрос уже обрабатывается другим поставщиком.';

  @override
  String get noAccessRequestForThisRequestYet =>
      'Ни один поставщик еще не обратился с просьбой обработать этот запрос.';

  @override
  String get youCanChangeThisRequestStatusNow =>
      'Клиент принял вас. Теперь вы можете управлять этим запросом.';

  @override
  String get waitingForOwnerApproval => 'Ждем, пока клиент вас примет.';

  @override
  String get ownerRejectedYourAccessRequest => 'Клиент отклонил этот запрос.';

  @override
  String get askOwnerForStatusAccess =>
      'Хотите обработать этот запрос? Попросите клиента принять вас.';

  @override
  String currentManager(String name) {
    return 'Принятый поставщик: $name';
  }

  @override
  String get approving => 'Одобрение...';

  @override
  String get approveAccess => 'Принять поставщика';

  @override
  String get rejectAccess => 'Снижение';

  @override
  String get sendingRequest => 'Отправка...';

  @override
  String get requestAccess => 'Попросите клиента принять вас';

  @override
  String get accessRequestPending => 'Ждем одобрения клиента.';

  @override
  String get openAssignedRequestsToUpdateStatus =>
      'Откройте обработку запросов, чтобы обновить статус в любое время.';

  @override
  String get accessRequestSent => 'Запрос отправлен заказчику.';

  @override
  String get couldNotSendAccessRequest =>
      'Не удалось задать вопрос клиенту прямо сейчас.';

  @override
  String get accessRequestApproved => 'Поставщик принял.';

  @override
  String get couldNotApproveAccessRequest => 'Не удалось принять поставщика.';

  @override
  String get accessRequestRejected => 'Поставщик отказался.';

  @override
  String get couldNotRejectAccessRequest => 'Не удалось отклонить поставщика.';

  @override
  String get expandRequestControl => 'Показать согласие поставщика';

  @override
  String get collapseRequestControl => 'Скрыть приемку поставщика';

  @override
  String get adminPanel => 'Панель администратора';

  @override
  String get adminAccessRequired =>
      'Только учетные записи администратора могут открыть эту панель.';

  @override
  String get adminUsersTab => 'Пользователи';

  @override
  String get adminReportsTab => 'Отчеты';

  @override
  String get adminUsersCouldNotBeLoaded =>
      'Список пользователей не может быть загружен прямо сейчас.';

  @override
  String get adminReportsCouldNotBeLoaded =>
      'Не удалось загрузить отчеты прямо сейчас.';

  @override
  String get noUserReportsYet => 'Пользовательских отчетов пока нет.';

  @override
  String blockUserTitle(String name) {
    return 'Блок $name';
  }

  @override
  String get blockUserAction => 'Заблокировать пользователя';

  @override
  String get blockReasonLabel => 'Причина блокировки';

  @override
  String get blockReasonHint =>
      'Добавьте необязательную причину этого действия.';

  @override
  String unblockUserTitle(String name) {
    return 'Разблокировать $name';
  }

  @override
  String unblockUserMessage(String name) {
    return 'Разрешить $name снова получить доступ к приложению?';
  }

  @override
  String get unblockUserAction => 'Разблокировать пользователя';

  @override
  String get userBlocked => 'Пользователь заблокирован.';

  @override
  String get userUnblocked => 'Пользователь разблокирован.';

  @override
  String get couldNotBlockUser => 'Не удалось заблокировать пользователя.';

  @override
  String get couldNotUnblockUser => 'Не удалось разблокировать пользователя.';

  @override
  String get reviewReportTitle => 'Обзор отчета';

  @override
  String get reviewReportAction => 'Обзор';

  @override
  String get reportStatusLabel => 'Статус отчета';

  @override
  String get reportStatusOpen => 'Открыть';

  @override
  String get reportStatusReviewed => 'Рассмотрено';

  @override
  String get reportStatusDismissed => 'Уволен';

  @override
  String get reportStatusActioned => 'Выполнено';

  @override
  String get reportUpdated => 'Отчет обновлен.';

  @override
  String get couldNotUpdateReport => 'Не удалось обновить отчет.';

  @override
  String get adminNotesLabel => 'Заметки администратора';

  @override
  String get adminNotesHint =>
      'Добавьте примечания к обзору для команды модераторов.';

  @override
  String get userBlockedStatus => 'Заблокировано';

  @override
  String get userActiveStatus => 'Активный';

  @override
  String get adminCurrentAccount => 'Это ваш текущий аккаунт.';

  @override
  String get adminRole => 'Админ';

  @override
  String reportCardTitle(String name) {
    return 'Отчет о $name';
  }

  @override
  String reportedByLabel(String name) {
    return 'Об этом сообщил $name.';
  }

  @override
  String reportCreatedAt(String time) {
    return 'Создано $time';
  }

  @override
  String reportReviewedAt(String time) {
    return 'Отзыв оставлен $time';
  }

  @override
  String get profileTitle => 'Профиль';

  @override
  String get profileLoadError =>
      'Этот профиль не может быть загружен прямо сейчас.';

  @override
  String get contactDetails => 'Контактная информация';

  @override
  String get accountActions => 'Действия с аккаунтом';

  @override
  String get logoutDescription =>
      'Выйдите из этого устройства. Вы можете войти снова, используя свой телефон и пароль.';

  @override
  String get phone => 'Телефон';

  @override
  String get cityLabel => 'Город';

  @override
  String get filterByCarMake => 'Фильтровать по марке автомобиля';

  @override
  String get chatPushNotifications => 'Push-уведомления в чате';

  @override
  String get chatPushNotificationsDescription =>
      'Получайте уведомление, когда кто-то отправляет сообщение в чат.';

  @override
  String get showMessagePreview =>
      'Показать предварительный просмотр сообщения';

  @override
  String get showMessagePreviewDescription =>
      'Включите часть сообщения чата в уведомления.';

  @override
  String get profileUpdatedSuccessfully => 'Профиль успешно обновлен.';

  @override
  String get profilePhoto => 'Фото профиля';

  @override
  String get newPhotoReadyMessage =>
      'Новое фото готово. Сохраните свой профиль, чтобы применить его.';

  @override
  String get choosePhotoForRequestsAndChats =>
      'Выбирайте фото, чтобы ваше имя было легче узнать в запросах и чатах.';

  @override
  String get chooseAnotherPhoto => 'Выбрать другое фото';

  @override
  String get changePhoto => 'Изменить фото';

  @override
  String get undoPhotoChange => 'Отменить изменение фотографии';

  @override
  String get noCarModelsSelectedYetMessage =>
      'Модели автомобилей пока не выбраны. Выберите модели, которые вы поддерживаете, из каталога ниже.';

  @override
  String get deleteAccountTitle => 'Удалить аккаунт';

  @override
  String get deleteAccountPermanentMessage =>
      'При этом ваша учетная запись, ваши сообщения с запросами, история чата и зарегистрированные устройства будут удалены без возможности восстановления. Это действие невозможно отменить.';

  @override
  String get accountDeletedSuccessfully => 'Ваш аккаунт был удален.';

  @override
  String get accountCouldNotBeDeletedRightNow =>
      'Ваш аккаунт не может быть удален прямо сейчас.';

  @override
  String get deleteAccountDangerDescription =>
      'Удалите свой профиль и навсегда удалите данные, принадлежащие вашей учетной записи, если вы больше не хотите использовать приложение.';

  @override
  String get pleaseWait => 'Пожалуйста, подождите...';

  @override
  String get quickActions => 'Быстрые действия';

  @override
  String get quickActionsDescription =>
      'Начните прямой разговор или откройте WhatsApp, используя номер телефона поставщика.';

  @override
  String get openingChat => 'Открытие чата...';

  @override
  String get chatAction => 'Чат';

  @override
  String get openingWhatsApp => 'Открываю WhatsApp...';

  @override
  String get whatsAppAction => 'WhatsApp';

  @override
  String get supplierCarsTitle =>
      'Автомобили, которые поддерживает этот поставщик';

  @override
  String get supplierCarsDescription =>
      'Этот поставщик получает соответствующие запросы на эти марки автомобилей.';

  @override
  String ratingLabel(String value) {
    return 'Рейтинг';
  }

  @override
  String joinedLabel(String time) {
    return 'Присоединился к $time';
  }

  @override
  String get reportUserSectionTitle => 'Пожаловаться на аккаунт';

  @override
  String get reportUserSectionBody =>
      'Отправьте отчет о безопасности, если этот аккаунт злоупотребляет чатом или приемом поставщика.';

  @override
  String get reportUserAction => 'Пожаловаться на аккаунт';

  @override
  String get sendingReport => 'Отправка отчета...';

  @override
  String reportUserDialogTitle(String name) {
    return 'Отчет $name';
  }

  @override
  String get reportReasonLabel => 'Причина';

  @override
  String get reportDetailsLabel => 'Подробности';

  @override
  String get reportDetailsHint =>
      'Добавьте любой контекст, который поможет администратору просмотреть этот отчет.';

  @override
  String get sendReport => 'Отправить отчет';

  @override
  String get userReportSubmitted => 'Отчет отправлен.';

  @override
  String get couldNotSendUserReport => 'Не удалось отправить отчет.';

  @override
  String get reportReasonSpam => 'Спам';

  @override
  String get reportReasonFraud => 'Мошенничество';

  @override
  String get reportReasonHarassment => 'Преследование';

  @override
  String get reportReasonImpersonation => 'Олицетворение';

  @override
  String get reportReasonOther => 'Другое';

  @override
  String get couldNotOpenChatRightNow => 'Не удалось открыть чат прямо сейчас.';

  @override
  String get whatsAppPhoneNotReady =>
      'Этот номер телефона не готов к использованию WhatsApp.';

  @override
  String get couldNotOpenWhatsApp =>
      'Не удалось открыть WhatsApp прямо сейчас.';

  @override
  String get privacyPolicy => 'Политика конфиденциальности';

  @override
  String get privacyPolicyDescription =>
      'Узнайте, как это приложение собирает, использует и защищает ваши данные.';

  @override
  String get openPrivacyPolicy => 'Открыть политику конфиденциальности';

  @override
  String get couldNotOpenPrivacyPolicy =>
      'Политику конфиденциальности не удалось открыть прямо сейчас.';

  @override
  String get requestUpdatedSuccessfully => 'Запрос успешно обновлен.';

  @override
  String get requestCreatedSuccessfully => 'Запрос успешно создан.';

  @override
  String get editRequestTitle => 'Редактировать запрос';

  @override
  String get createRequestTitle => 'Создать запрос';

  @override
  String get updateYourRequest => 'Обновите свой запрос';

  @override
  String get postNewRequest => 'Запросить запасную часть';

  @override
  String get editRequestDescription =>
      'Обновите сведения о запросе и фотографии, которые вы хотите видеть поставщикам.';

  @override
  String get createRequestDescription =>
      'Сообщите поставщикам, какая запчасть вам нужна. Подходящие поставщики будут уведомлены и смогут связаться с вами в чате.';

  @override
  String get requestExpiresAfter48Hours =>
      'Этот запрос будет автоматически удален серверной частью через 48 часов после его создания.';

  @override
  String get requestCreationBlocked => 'Создание запроса заблокировано';

  @override
  String get currentStatus => 'Текущий статус';

  @override
  String get initialStatus => 'Исходный статус';

  @override
  String currentStatusMessage(String status) {
    return 'В настоящее время этот запрос помечен как «$status».';
  }

  @override
  String initialStatusMessage(String status) {
    return 'Новые запросы будут начинаться как «$status».';
  }

  @override
  String get requestTitleLabel => 'Какая запчасть вам нужна?';

  @override
  String get requestTitleHint => 'Бампер передний на Тойоту Камри 2022 г.в.';

  @override
  String get enterRequestTitle => 'Введите заголовок запроса.';

  @override
  String get requestDescriptionLabel => 'Описание';

  @override
  String get requestDescriptionHint =>
      'Опишите состояние, предпочтения бренда или детали модели, которые поставщики должны знать.';

  @override
  String get addShortDescription => 'Добавьте краткое описание.';

  @override
  String get carModelLabel => 'Модель автомобиля';

  @override
  String get carModelDescription =>
      'Выберите точную модель автомобиля, для которой предназначен этот запрос, чтобы уведомления получали только подходящие поставщики.';

  @override
  String get addCarManually => 'Добавить машину вручную';

  @override
  String get addCarManuallyDescription =>
      'Используйте это, если вы еще не можете найти марку или модель в каталоге.';

  @override
  String get carMakeLabel => 'Марка автомобиля';

  @override
  String get carModelSearchLabel => 'Поиск модели автомобиля';

  @override
  String get carModelSearchHint => 'Ауди РС7';

  @override
  String get clearCarModelSearch => 'Очистить поиск';

  @override
  String get carModelSearchFailed =>
      'Поиск модели автомобиля не удался. Попробуйте еще раз.';

  @override
  String get noMatchingCarModelsFound =>
      'Подходящих моделей автомобилей не найдено.';

  @override
  String get newCarMakeLabel => 'Новая марка автомобиля';

  @override
  String get newCarMakeHint => 'Тойота';

  @override
  String get newCarModelLabel => 'Новая модель автомобиля';

  @override
  String get newCarModelHint => 'Камри 2024';

  @override
  String get cityOptionalLabel => 'Город (необязательно)';

  @override
  String get cityOptionalHint => 'Эр-Рияд';

  @override
  String get addPhotos => 'Добавить фотографии';

  @override
  String get addMorePhotos => 'Добавить больше фотографий';

  @override
  String get minPriceLabel => 'Минимальная цена';

  @override
  String get maxPriceLabel => 'Максимальная цена';

  @override
  String get maxPriceMustBeGreaterThanMinPrice =>
      'Максимальная цена должна быть больше минимальной.';

  @override
  String get saving => 'Сохранение...';

  @override
  String get saveChanges => 'Сохранить изменения';

  @override
  String get enterValidNumber => 'Введите действительный номер.';

  @override
  String get enterCarMake => 'Введите марку автомобиля.';

  @override
  String get enterCarModel => 'Введите модель автомобиля.';

  @override
  String get enterCarMakeAndModelBeforeSaving =>
      'Прежде чем сохранить этот запрос, введите марку и модель автомобиля.';

  @override
  String get chooseCarModelBeforeSaving =>
      'Прежде чем сохранить запрос, выберите модель автомобиля.';

  @override
  String get viewMyRequests => 'Посмотреть мои запросы';

  @override
  String get viewRequest => 'Посмотреть запрос';

  @override
  String get dismiss => 'Уволить';

  @override
  String get appUpdateAvailableMessage =>
      'Обновите приложение прямо сейчас и наслаждайтесь новейшими функциями и улучшениями.';

  @override
  String get updateNow => 'Обновить сейчас';

  @override
  String get later => 'Позже';

  @override
  String get couldNotOpenAppStore =>
      'Магазин приложений сейчас открыть невозможно.';

  @override
  String whatsAppGreeting(String name) {
    return 'Привет $name';
  }

  @override
  String get forgotPassword => 'Забыли пароль?';

  @override
  String get resetPasswordTitle => 'Сбросить пароль';

  @override
  String get passwordResetIntro =>
      'Введите свой номер телефона, чтобы получить SMS-код.';

  @override
  String get newPassword => 'Новый пароль';

  @override
  String get confirmNewPassword => 'Подтвердите новый пароль';

  @override
  String get passwordsDoNotMatch => 'Пароли не совпадают.';

  @override
  String get sendingSms => 'Отправка СМС...';

  @override
  String get sendSmsCode => 'Отправить СМС-код';

  @override
  String get smsCode => 'СМС-код';

  @override
  String get changingPassword => 'Изменение пароля...';

  @override
  String get verifyAndChangePassword => 'Подтвердите и измените пароль';

  @override
  String resendInSeconds(int count) {
    return 'Отправить повторно через $count с.';
  }

  @override
  String get resendCode => 'Отправить код повторно';

  @override
  String get sendingNewVerificationCode =>
      'Отправка нового кода подтверждения...';

  @override
  String sendingVerificationCodeToPhone(String phone) {
    return 'Отправка кода подтверждения на $phone...';
  }

  @override
  String get phoneVerifiedAutomaticallyChangingPassword =>
      'Телефон подтвержден автоматически. Изменение пароля...';

  @override
  String get checkPhoneNumberAndTryAgain =>
      'Проверьте номер телефона и повторите попытку.';

  @override
  String enterSmsCodeSentToPhone(String phone) {
    return 'Введите код SMS, отправленный на $phone.';
  }

  @override
  String get automaticVerificationTimedOutEnterSmsCode =>
      'Время автоматической проверки истекло. Введите СМС-код.';

  @override
  String get phoneVerificationCouldNotStart =>
      'Не удалось начать проверку телефона.';

  @override
  String get waitForSmsCodeFirst => 'Сначала дождитесь SMS-кода.';

  @override
  String get enterSixDigitSmsCode => 'Введите шестизначный SMS-код.';

  @override
  String get passwordChangedSignInAgain => 'Пароль изменен. Войдите снова.';

  @override
  String get passwordResetFailedTryCodeAgain =>
      'Сбросить пароль не удалось. Попробуйте ввести код еще раз.';

  @override
  String get firebaseSmsBlocked =>
      'Firebase блокирует этот SMS-запрос. Убедитесь, что для этого региона включен вход в систему с помощью телефона.';

  @override
  String get validPhoneNumberError =>
      'Введите действительный номер телефона +970 или +972.';

  @override
  String get tooManySmsAttempts =>
      'Слишком много попыток отправки SMS. Подождите, прежде чем запрашивать другой код.';

  @override
  String get smsCodeIncorrect => 'SMS-код неправильный.';

  @override
  String get smsCodeExpired =>
      'Срок действия SMS-кода истек. Запросите новый код.';

  @override
  String get firebaseNetworkError =>
      'Нет подключения к Интернету. Проверьте подключение и повторите попытку.';

  @override
  String firebasePhoneVerificationFailed(String code, String message) {
    return 'Не удалось подтвердить телефон Firebase ($code): $message.';
  }

  @override
  String get phoneVerificationFailed => 'Проверка телефона не удалась.';
}
