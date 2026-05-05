import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_he.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('he'),
  ];

  /// No description provided for @accountCreatedFor.
  ///
  /// In en, this message translates to:
  /// **'Account created for {username}'**
  String accountCreatedFor(String username);

  /// No description provided for @accountRole.
  ///
  /// In en, this message translates to:
  /// **'Account role'**
  String get accountRole;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @allAvailableCarNamesAlreadySelected.
  ///
  /// In en, this message translates to:
  /// **'All available car names are already selected.'**
  String get allAvailableCarNamesAlreadySelected;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'MTA Auto Spare'**
  String get appTitle;

  /// No description provided for @backend.
  ///
  /// In en, this message translates to:
  /// **'Backend'**
  String get backend;

  /// No description provided for @carCatalogCouldNotBeLoadedRightNow.
  ///
  /// In en, this message translates to:
  /// **'The car catalog could not be loaded right now.'**
  String get carCatalogCouldNotBeLoadedRightNow;

  /// No description provided for @carName.
  ///
  /// In en, this message translates to:
  /// **'Car name'**
  String get carName;

  /// No description provided for @carsIHavePartsFor.
  ///
  /// In en, this message translates to:
  /// **'Cars I have parts for'**
  String get carsIHavePartsFor;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change language'**
  String get changeLanguage;

  /// No description provided for @chats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chats;

  /// No description provided for @chooseAUsername.
  ///
  /// In en, this message translates to:
  /// **'Choose a username'**
  String get chooseAUsername;

  /// No description provided for @conversationNumber.
  ///
  /// In en, this message translates to:
  /// **'Conversation #{id}'**
  String conversationNumber(int id);

  /// No description provided for @conversations.
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get conversations;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @createNewAccount.
  ///
  /// In en, this message translates to:
  /// **'Create new account'**
  String get createNewAccount;

  /// No description provided for @creating.
  ///
  /// In en, this message translates to:
  /// **'Creating...'**
  String get creating;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgo(int count);

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'name@example.com'**
  String get emailHint;

  /// No description provided for @enterAValidEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get enterAValidEmailAddress;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get enterPassword;

  /// No description provided for @enterUsername.
  ///
  /// In en, this message translates to:
  /// **'Enter username'**
  String get enterUsername;

  /// No description provided for @enterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterYourEmail;

  /// No description provided for @enterYourFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterYourFullName;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get fullNameHint;

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} hours ago'**
  String hoursAgo(int count);

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageHebrew.
  ///
  /// In en, this message translates to:
  /// **'עברית'**
  String get languageHebrew;

  /// No description provided for @languageSystemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystemDefault;

  /// No description provided for @lastSeenOn.
  ///
  /// In en, this message translates to:
  /// **'Last seen on {time}'**
  String lastSeenOn(String time);

  /// No description provided for @lastSeenRelative.
  ///
  /// In en, this message translates to:
  /// **'Last seen {time}'**
  String lastSeenRelative(String time);

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} minutes ago'**
  String minutesAgo(int count);

  /// No description provided for @newMessage.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get newMessage;

  /// No description provided for @noCarNamesSelectedYet.
  ///
  /// In en, this message translates to:
  /// **'No car names selected yet.'**
  String get noCarNamesSelectedYet;

  /// No description provided for @noConversationsYet.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get noConversationsYet;

  /// No description provided for @noConversationsYetMessage.
  ///
  /// In en, this message translates to:
  /// **'You have not started any conversations yet.'**
  String get noConversationsYetMessage;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get passwordHint;

  /// No description provided for @passwordMinHint.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get passwordMinHint;

  /// No description provided for @pickTheCarNamesYouSupplyPartsFor.
  ///
  /// In en, this message translates to:
  /// **'Pick the car names you supply parts for.'**
  String get pickTheCarNamesYouSupplyPartsFor;

  /// No description provided for @registerUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a username'**
  String get registerUsernameHint;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @requests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get requests;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select language'**
  String get selectLanguage;

  /// No description provided for @setUpMarketplaceProfile.
  ///
  /// In en, this message translates to:
  /// **'Set up your marketplace profile'**
  String get setUpMarketplaceProfile;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get signingIn;

  /// No description provided for @signInToBrowseSellerRequests.
  ///
  /// In en, this message translates to:
  /// **'Sign in to browse seller requests and chat.'**
  String get signInToBrowseSellerRequests;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @supplierRole.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get supplierRole;

  /// No description provided for @suppliersCanPostRequests.
  ///
  /// In en, this message translates to:
  /// **'Suppliers can post requests and buyers can start chats.'**
  String get suppliersCanPostRequests;

  /// No description provided for @theCarCatalogCouldNotBeLoaded.
  ///
  /// In en, this message translates to:
  /// **'The car catalog could not be loaded.'**
  String get theCarCatalogCouldNotBeLoaded;

  /// No description provided for @thisMessageWasDeleted.
  ///
  /// In en, this message translates to:
  /// **'This message was deleted'**
  String get thisMessageWasDeleted;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @useAtLeastSixCharacters.
  ///
  /// In en, this message translates to:
  /// **'Use at least six characters'**
  String get useAtLeastSixCharacters;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @usernameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter username'**
  String get usernameHint;

  /// No description provided for @userRole.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get userRole;

  /// No description provided for @attachment.
  ///
  /// In en, this message translates to:
  /// **'Attachment'**
  String get attachment;

  /// No description provided for @attachedRequest.
  ///
  /// In en, this message translates to:
  /// **'Attached request'**
  String get attachedRequest;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @copyMessage.
  ///
  /// In en, this message translates to:
  /// **'Copy message'**
  String get copyMessage;

  /// No description provided for @deleteForAll.
  ///
  /// In en, this message translates to:
  /// **'Delete for all'**
  String get deleteForAll;

  /// No description provided for @deleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete message'**
  String get deleteMessage;

  /// No description provided for @deleteOnlyMe.
  ///
  /// In en, this message translates to:
  /// **'Delete only for me'**
  String get deleteOnlyMe;

  /// No description provided for @deletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Deleted message'**
  String get deletedMessage;

  /// No description provided for @discardVoiceMessage.
  ///
  /// In en, this message translates to:
  /// **'Discard voice message'**
  String get discardVoiceMessage;

  /// No description provided for @editMessage.
  ///
  /// In en, this message translates to:
  /// **'Edit message'**
  String get editMessage;

  /// No description provided for @editMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit message'**
  String get editMessageTitle;

  /// No description provided for @edited.
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get edited;

  /// No description provided for @fromPrice.
  ///
  /// In en, this message translates to:
  /// **'From {value}'**
  String fromPrice(String value);

  /// No description provided for @messageCopied.
  ///
  /// In en, this message translates to:
  /// **'Message copied.'**
  String get messageCopied;

  /// No description provided for @messageCouldNotBeDeleted.
  ///
  /// In en, this message translates to:
  /// **'Message could not be deleted.'**
  String get messageCouldNotBeDeleted;

  /// No description provided for @messageCouldNotBeUpdated.
  ///
  /// In en, this message translates to:
  /// **'Message could not be updated.'**
  String get messageCouldNotBeUpdated;

  /// No description provided for @messageDeletedForEveryone.
  ///
  /// In en, this message translates to:
  /// **'Message deleted for everyone.'**
  String get messageDeletedForEveryone;

  /// No description provided for @messageDeletedForYou.
  ///
  /// In en, this message translates to:
  /// **'Message deleted for you.'**
  String get messageDeletedForYou;

  /// No description provided for @messageLabel.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get messageLabel;

  /// No description provided for @messageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Message updated.'**
  String get messageUpdated;

  /// No description provided for @microphonePermissionRequiredForVoiceMessage.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is required to record a voice message.'**
  String get microphonePermissionRequiredForVoiceMessage;

  /// No description provided for @noMessagesYetMessage.
  ///
  /// In en, this message translates to:
  /// **'Say hello and start the conversation.'**
  String get noMessagesYetMessage;

  /// No description provided for @noPriceRange.
  ///
  /// In en, this message translates to:
  /// **'No price range'**
  String get noPriceRange;

  /// No description provided for @noVoiceMessageCaptured.
  ///
  /// In en, this message translates to:
  /// **'No voice message was captured.'**
  String get noVoiceMessageCaptured;

  /// No description provided for @pauseVoiceMessage.
  ///
  /// In en, this message translates to:
  /// **'Pause voice message'**
  String get pauseVoiceMessage;

  /// No description provided for @photo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photo;

  /// No description provided for @photosCount.
  ///
  /// In en, this message translates to:
  /// **'{count} photos'**
  String photosCount(int count);

  /// No description provided for @playVoiceMessage.
  ///
  /// In en, this message translates to:
  /// **'Play voice message'**
  String get playVoiceMessage;

  /// No description provided for @preparingRecorder.
  ///
  /// In en, this message translates to:
  /// **'Preparing recorder...'**
  String get preparingRecorder;

  /// No description provided for @recordVoiceMessage.
  ///
  /// In en, this message translates to:
  /// **'Record voice message'**
  String get recordVoiceMessage;

  /// No description provided for @replyingTo.
  ///
  /// In en, this message translates to:
  /// **'Replying to {name}'**
  String replyingTo(String name);

  /// No description provided for @requestWithTitle.
  ///
  /// In en, this message translates to:
  /// **'Request: {title}'**
  String requestWithTitle(String title);

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get sendMessage;

  /// No description provided for @sendOrClearDraftBeforeVoiceMessage.
  ///
  /// In en, this message translates to:
  /// **'Send or clear the current draft before recording a voice message.'**
  String get sendOrClearDraftBeforeVoiceMessage;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get sending;

  /// No description provided for @sendVoiceMessage.
  ///
  /// In en, this message translates to:
  /// **'Send voice message'**
  String get sendVoiceMessage;

  /// No description provided for @sentAttachmentsCount.
  ///
  /// In en, this message translates to:
  /// **'Sent {count} attachment(s)'**
  String sentAttachmentsCount(int count);

  /// No description provided for @sharedRequest.
  ///
  /// In en, this message translates to:
  /// **'Shared a request'**
  String get sharedRequest;

  /// No description provided for @showOriginal.
  ///
  /// In en, this message translates to:
  /// **'Show original'**
  String get showOriginal;

  /// No description provided for @showTranslation.
  ///
  /// In en, this message translates to:
  /// **'Show translation'**
  String get showTranslation;

  /// No description provided for @typing.
  ///
  /// In en, this message translates to:
  /// **'Typing...'**
  String get typing;

  /// No description provided for @unableToPlayVoiceMessage.
  ///
  /// In en, this message translates to:
  /// **'Unable to play voice message'**
  String get unableToPlayVoiceMessage;

  /// No description provided for @unableToSeekVoiceMessage.
  ///
  /// In en, this message translates to:
  /// **'Unable to seek voice message'**
  String get unableToSeekVoiceMessage;

  /// No description provided for @updateYourMessage.
  ///
  /// In en, this message translates to:
  /// **'Update your message'**
  String get updateYourMessage;

  /// No description provided for @upToPrice.
  ///
  /// In en, this message translates to:
  /// **'Up to {value}'**
  String upToPrice(String value);

  /// No description provided for @uploadImages.
  ///
  /// In en, this message translates to:
  /// **'Upload images'**
  String get uploadImages;

  /// No description provided for @voiceMessage.
  ///
  /// In en, this message translates to:
  /// **'Voice message'**
  String get voiceMessage;

  /// No description provided for @voiceMessageCouldNotBeSent.
  ///
  /// In en, this message translates to:
  /// **'Voice message could not be sent.'**
  String get voiceMessageCouldNotBeSent;

  /// No description provided for @voiceMessageDiscarded.
  ///
  /// In en, this message translates to:
  /// **'Voice message discarded.'**
  String get voiceMessageDiscarded;

  /// No description provided for @voiceMessageDiscardFailed.
  ///
  /// In en, this message translates to:
  /// **'Voice message could not be discarded cleanly.'**
  String get voiceMessageDiscardFailed;

  /// No description provided for @voiceRecordingCouldNotStart.
  ///
  /// In en, this message translates to:
  /// **'Voice recording could not start on this device.'**
  String get voiceRecordingCouldNotStart;

  /// No description provided for @writeAMessage.
  ///
  /// In en, this message translates to:
  /// **'Write a message...'**
  String get writeAMessage;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get connecting;

  /// No description provided for @liveUpdatesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Live updates unavailable'**
  String get liveUpdatesUnavailable;

  /// No description provided for @reconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting...'**
  String get reconnecting;

  /// No description provided for @marketplaceUser.
  ///
  /// In en, this message translates to:
  /// **'Marketplace user'**
  String get marketplaceUser;

  /// No description provided for @refreshRequests.
  ///
  /// In en, this message translates to:
  /// **'Refresh requests'**
  String get refreshRequests;

  /// No description provided for @browseRequestPostsFromOtherSellers.
  ///
  /// In en, this message translates to:
  /// **'Browse request posts from other sellers.'**
  String get browseRequestPostsFromOtherSellers;

  /// No description provided for @seeRequestPostsYouCreated.
  ///
  /// In en, this message translates to:
  /// **'See the request posts you created.'**
  String get seeRequestPostsYouCreated;

  /// No description provided for @browseRequests.
  ///
  /// In en, this message translates to:
  /// **'Browse Requests'**
  String get browseRequests;

  /// No description provided for @myRequests.
  ///
  /// In en, this message translates to:
  /// **'My Requests'**
  String get myRequests;

  /// No description provided for @noRequestsYet.
  ///
  /// In en, this message translates to:
  /// **'No requests yet'**
  String get noRequestsYet;

  /// No description provided for @createFirstRequestPostMessage.
  ///
  /// In en, this message translates to:
  /// **'Create your first request post and it will show up here.'**
  String get createFirstRequestPostMessage;

  /// No description provided for @noSellerRequestsYet.
  ///
  /// In en, this message translates to:
  /// **'No seller requests yet'**
  String get noSellerRequestsYet;

  /// No description provided for @noSellerRequestsYetMessage.
  ///
  /// In en, this message translates to:
  /// **'There are no request posts from other sellers yet. Pull to refresh later.'**
  String get noSellerRequestsYetMessage;

  /// No description provided for @createRequest.
  ///
  /// In en, this message translates to:
  /// **'Create Request'**
  String get createRequest;

  /// No description provided for @deleteRequest.
  ///
  /// In en, this message translates to:
  /// **'Delete Request'**
  String get deleteRequest;

  /// No description provided for @deleteRequestConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\"? This request post will be removed from your list.'**
  String deleteRequestConfirmation(String title);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @deleting.
  ///
  /// In en, this message translates to:
  /// **'Deleting...'**
  String get deleting;

  /// No description provided for @chatSeller.
  ///
  /// In en, this message translates to:
  /// **'Chat Seller'**
  String get chatSeller;

  /// No description provided for @opening.
  ///
  /// In en, this message translates to:
  /// **'Opening...'**
  String get opening;

  /// No description provided for @requestDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Request deleted successfully.'**
  String get requestDeletedSuccessfully;

  /// No description provided for @couldNotDeleteRequest.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the request.'**
  String get couldNotDeleteRequest;

  /// No description provided for @couldNotOpenConversation.
  ///
  /// In en, this message translates to:
  /// **'Could not open the conversation.'**
  String get couldNotOpenConversation;

  /// No description provided for @requestAttachedResendHint.
  ///
  /// In en, this message translates to:
  /// **'The request is attached in the chat composer so you can resend it.'**
  String get requestAttachedResendHint;

  /// No description provided for @initialRequestCouldNotBeSentAutomatically.
  ///
  /// In en, this message translates to:
  /// **'The chat opened, but the initial request could not be sent automatically.'**
  String get initialRequestCouldNotBeSentAutomatically;

  /// No description provided for @welcomeBackUser.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}'**
  String welcomeBackUser(String name);

  /// No description provided for @browse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get browse;

  /// No description provided for @mine.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get mine;

  /// No description provided for @assigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get assigned;

  /// No description provided for @assignedRequests.
  ///
  /// In en, this message translates to:
  /// **'Assigned Requests'**
  String get assignedRequests;

  /// No description provided for @allStatuses.
  ///
  /// In en, this message translates to:
  /// **'All Statuses'**
  String get allStatuses;

  /// No description provided for @cityNotSet.
  ///
  /// In en, this message translates to:
  /// **'City not set'**
  String get cityNotSet;

  /// No description provided for @thisRequestBelongsToYou.
  ///
  /// In en, this message translates to:
  /// **'This request belongs to you.'**
  String get thisRequestBelongsToYou;

  /// No description provided for @openChatWithSellerBehindRequest.
  ///
  /// In en, this message translates to:
  /// **'Open a chat with the seller behind this request.'**
  String get openChatWithSellerBehindRequest;

  /// No description provided for @requestsYouCanManageNow.
  ///
  /// In en, this message translates to:
  /// **'Requests you can manage right now.'**
  String get requestsYouCanManageNow;

  /// No description provided for @noAssignedRequestsYet.
  ///
  /// In en, this message translates to:
  /// **'No assigned requests yet'**
  String get noAssignedRequestsYet;

  /// No description provided for @noAssignedRequestsYetMessage.
  ///
  /// In en, this message translates to:
  /// **'Once an owner approves your access, the request will appear here.'**
  String get noAssignedRequestsYetMessage;

  /// No description provided for @youCanManageThisRequestStatus.
  ///
  /// In en, this message translates to:
  /// **'You can manage this request status.'**
  String get youCanManageThisRequestStatus;

  /// No description provided for @changeStatus.
  ///
  /// In en, this message translates to:
  /// **'Change Status'**
  String get changeStatus;

  /// No description provided for @requestStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Request status updated.'**
  String get requestStatusUpdated;

  /// No description provided for @couldNotUpdateRequestStatus.
  ///
  /// In en, this message translates to:
  /// **'Could not update the request status.'**
  String get couldNotUpdateRequestStatus;

  /// No description provided for @updatingStatus.
  ///
  /// In en, this message translates to:
  /// **'Updating...'**
  String get updatingStatus;

  /// No description provided for @requestControl.
  ///
  /// In en, this message translates to:
  /// **'Request Control'**
  String get requestControl;

  /// No description provided for @thisChatCanManageRequestStatus.
  ///
  /// In en, this message translates to:
  /// **'The supplier in this chat can manage this request status now.'**
  String get thisChatCanManageRequestStatus;

  /// No description provided for @thisRequestIsAssignedToAnotherSupplier.
  ///
  /// In en, this message translates to:
  /// **'This request is currently assigned to another supplier.'**
  String get thisRequestIsAssignedToAnotherSupplier;

  /// No description provided for @noAccessRequestForThisRequestYet.
  ///
  /// In en, this message translates to:
  /// **'No access request has been sent for this request yet.'**
  String get noAccessRequestForThisRequestYet;

  /// No description provided for @youCanChangeThisRequestStatusNow.
  ///
  /// In en, this message translates to:
  /// **'You can change this request status now.'**
  String get youCanChangeThisRequestStatusNow;

  /// No description provided for @waitingForOwnerApproval.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the owner to approve your access request.'**
  String get waitingForOwnerApproval;

  /// No description provided for @ownerRejectedYourAccessRequest.
  ///
  /// In en, this message translates to:
  /// **'The owner rejected your access request.'**
  String get ownerRejectedYourAccessRequest;

  /// No description provided for @askOwnerForStatusAccess.
  ///
  /// In en, this message translates to:
  /// **'Ask the owner for permission to manage this request status.'**
  String get askOwnerForStatusAccess;

  /// No description provided for @currentManager.
  ///
  /// In en, this message translates to:
  /// **'Current manager: {name}'**
  String currentManager(String name);

  /// No description provided for @approving.
  ///
  /// In en, this message translates to:
  /// **'Approving...'**
  String get approving;

  /// No description provided for @approveAccess.
  ///
  /// In en, this message translates to:
  /// **'Approve Access'**
  String get approveAccess;

  /// No description provided for @rejectAccess.
  ///
  /// In en, this message translates to:
  /// **'Reject Access'**
  String get rejectAccess;

  /// No description provided for @sendingRequest.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get sendingRequest;

  /// No description provided for @requestAccess.
  ///
  /// In en, this message translates to:
  /// **'Request Access'**
  String get requestAccess;

  /// No description provided for @accessRequestPending.
  ///
  /// In en, this message translates to:
  /// **'Your access request is pending.'**
  String get accessRequestPending;

  /// No description provided for @openAssignedRequestsToUpdateStatus.
  ///
  /// In en, this message translates to:
  /// **'Open Assigned Requests to update the status anytime.'**
  String get openAssignedRequestsToUpdateStatus;

  /// No description provided for @accessRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Access request sent.'**
  String get accessRequestSent;

  /// No description provided for @couldNotSendAccessRequest.
  ///
  /// In en, this message translates to:
  /// **'Could not send the access request.'**
  String get couldNotSendAccessRequest;

  /// No description provided for @accessRequestApproved.
  ///
  /// In en, this message translates to:
  /// **'Access request approved.'**
  String get accessRequestApproved;

  /// No description provided for @couldNotApproveAccessRequest.
  ///
  /// In en, this message translates to:
  /// **'Could not approve the access request.'**
  String get couldNotApproveAccessRequest;

  /// No description provided for @accessRequestRejected.
  ///
  /// In en, this message translates to:
  /// **'Access request rejected.'**
  String get accessRequestRejected;

  /// No description provided for @couldNotRejectAccessRequest.
  ///
  /// In en, this message translates to:
  /// **'Could not reject the access request.'**
  String get couldNotRejectAccessRequest;

  /// No description provided for @expandRequestControl.
  ///
  /// In en, this message translates to:
  /// **'Expand request controls'**
  String get expandRequestControl;

  /// No description provided for @collapseRequestControl.
  ///
  /// In en, this message translates to:
  /// **'Collapse request controls'**
  String get collapseRequestControl;

  /// No description provided for @adminPanel.
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get adminPanel;

  /// No description provided for @adminAccessRequired.
  ///
  /// In en, this message translates to:
  /// **'Only admin accounts can open this panel.'**
  String get adminAccessRequired;

  /// No description provided for @adminUsersTab.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get adminUsersTab;

  /// No description provided for @adminReportsTab.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get adminReportsTab;

  /// No description provided for @adminUsersCouldNotBeLoaded.
  ///
  /// In en, this message translates to:
  /// **'The user list could not be loaded right now.'**
  String get adminUsersCouldNotBeLoaded;

  /// No description provided for @adminReportsCouldNotBeLoaded.
  ///
  /// In en, this message translates to:
  /// **'The reports could not be loaded right now.'**
  String get adminReportsCouldNotBeLoaded;

  /// No description provided for @noUserReportsYet.
  ///
  /// In en, this message translates to:
  /// **'No user reports yet.'**
  String get noUserReportsYet;

  /// No description provided for @blockUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Block {name}'**
  String blockUserTitle(String name);

  /// No description provided for @blockUserAction.
  ///
  /// In en, this message translates to:
  /// **'Block User'**
  String get blockUserAction;

  /// No description provided for @blockReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Block reason'**
  String get blockReasonLabel;

  /// No description provided for @blockReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Add an optional reason for this action.'**
  String get blockReasonHint;

  /// No description provided for @unblockUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Unblock {name}'**
  String unblockUserTitle(String name);

  /// No description provided for @unblockUserMessage.
  ///
  /// In en, this message translates to:
  /// **'Allow {name} to access the app again?'**
  String unblockUserMessage(String name);

  /// No description provided for @unblockUserAction.
  ///
  /// In en, this message translates to:
  /// **'Unblock User'**
  String get unblockUserAction;

  /// No description provided for @userBlocked.
  ///
  /// In en, this message translates to:
  /// **'User blocked.'**
  String get userBlocked;

  /// No description provided for @userUnblocked.
  ///
  /// In en, this message translates to:
  /// **'User unblocked.'**
  String get userUnblocked;

  /// No description provided for @couldNotBlockUser.
  ///
  /// In en, this message translates to:
  /// **'Could not block the user.'**
  String get couldNotBlockUser;

  /// No description provided for @couldNotUnblockUser.
  ///
  /// In en, this message translates to:
  /// **'Could not unblock the user.'**
  String get couldNotUnblockUser;

  /// No description provided for @reviewReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Review Report'**
  String get reviewReportTitle;

  /// No description provided for @reviewReportAction.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get reviewReportAction;

  /// No description provided for @reportStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Report status'**
  String get reportStatusLabel;

  /// No description provided for @reportStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get reportStatusOpen;

  /// No description provided for @reportStatusReviewed.
  ///
  /// In en, this message translates to:
  /// **'Reviewed'**
  String get reportStatusReviewed;

  /// No description provided for @reportStatusDismissed.
  ///
  /// In en, this message translates to:
  /// **'Dismissed'**
  String get reportStatusDismissed;

  /// No description provided for @reportStatusActioned.
  ///
  /// In en, this message translates to:
  /// **'Actioned'**
  String get reportStatusActioned;

  /// No description provided for @reportUpdated.
  ///
  /// In en, this message translates to:
  /// **'Report updated.'**
  String get reportUpdated;

  /// No description provided for @couldNotUpdateReport.
  ///
  /// In en, this message translates to:
  /// **'Could not update the report.'**
  String get couldNotUpdateReport;

  /// No description provided for @adminNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Admin notes'**
  String get adminNotesLabel;

  /// No description provided for @adminNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Add review notes for the moderation team.'**
  String get adminNotesHint;

  /// No description provided for @userBlockedStatus.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get userBlockedStatus;

  /// No description provided for @userActiveStatus.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get userActiveStatus;

  /// No description provided for @adminCurrentAccount.
  ///
  /// In en, this message translates to:
  /// **'This is your current account.'**
  String get adminCurrentAccount;

  /// No description provided for @adminRole.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminRole;

  /// No description provided for @reportCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Report about {name}'**
  String reportCardTitle(String name);

  /// No description provided for @reportedByLabel.
  ///
  /// In en, this message translates to:
  /// **'Reported by {name}'**
  String reportedByLabel(String name);

  /// No description provided for @reportCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Created {time}'**
  String reportCreatedAt(String time);

  /// No description provided for @reportReviewedAt.
  ///
  /// In en, this message translates to:
  /// **'Reviewed {time}'**
  String reportReviewedAt(String time);

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileLoadError.
  ///
  /// In en, this message translates to:
  /// **'This profile could not be loaded right now.'**
  String get profileLoadError;

  /// No description provided for @contactDetails.
  ///
  /// In en, this message translates to:
  /// **'Contact Details'**
  String get contactDetails;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @quickActionsDescription.
  ///
  /// In en, this message translates to:
  /// **'Start a direct conversation or open WhatsApp using the supplier phone number.'**
  String get quickActionsDescription;

  /// No description provided for @openingChat.
  ///
  /// In en, this message translates to:
  /// **'Opening chat...'**
  String get openingChat;

  /// No description provided for @chatAction.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatAction;

  /// No description provided for @openingWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Opening WhatsApp...'**
  String get openingWhatsApp;

  /// No description provided for @whatsAppAction.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsAppAction;

  /// No description provided for @supplierCarsTitle.
  ///
  /// In en, this message translates to:
  /// **'Cars This Supplier Works With'**
  String get supplierCarsTitle;

  /// No description provided for @supplierCarsDescription.
  ///
  /// In en, this message translates to:
  /// **'These are the car brands selected on the supplier profile.'**
  String get supplierCarsDescription;

  /// No description provided for @ratingLabel.
  ///
  /// In en, this message translates to:
  /// **'Rating {value}'**
  String ratingLabel(String value);

  /// No description provided for @joinedLabel.
  ///
  /// In en, this message translates to:
  /// **'Joined {time}'**
  String joinedLabel(String time);

  /// No description provided for @reportUserSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Report User'**
  String get reportUserSectionTitle;

  /// No description provided for @reportUserSectionBody.
  ///
  /// In en, this message translates to:
  /// **'Send a safety report if this user is abusing chat or request access.'**
  String get reportUserSectionBody;

  /// No description provided for @reportUserAction.
  ///
  /// In en, this message translates to:
  /// **'Report User'**
  String get reportUserAction;

  /// No description provided for @sendingReport.
  ///
  /// In en, this message translates to:
  /// **'Sending report...'**
  String get sendingReport;

  /// No description provided for @reportUserDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Report {name}'**
  String reportUserDialogTitle(String name);

  /// No description provided for @reportReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reportReasonLabel;

  /// No description provided for @reportDetailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get reportDetailsLabel;

  /// No description provided for @reportDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Add any context that would help the admin review this report.'**
  String get reportDetailsHint;

  /// No description provided for @sendReport.
  ///
  /// In en, this message translates to:
  /// **'Send Report'**
  String get sendReport;

  /// No description provided for @userReportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report sent.'**
  String get userReportSubmitted;

  /// No description provided for @couldNotSendUserReport.
  ///
  /// In en, this message translates to:
  /// **'Could not send the report.'**
  String get couldNotSendUserReport;

  /// No description provided for @reportReasonSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get reportReasonSpam;

  /// No description provided for @reportReasonFraud.
  ///
  /// In en, this message translates to:
  /// **'Fraud'**
  String get reportReasonFraud;

  /// No description provided for @reportReasonHarassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment'**
  String get reportReasonHarassment;

  /// No description provided for @reportReasonImpersonation.
  ///
  /// In en, this message translates to:
  /// **'Impersonation'**
  String get reportReasonImpersonation;

  /// No description provided for @reportReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reportReasonOther;

  /// No description provided for @couldNotOpenChatRightNow.
  ///
  /// In en, this message translates to:
  /// **'Could not open the chat right now.'**
  String get couldNotOpenChatRightNow;

  /// No description provided for @whatsAppPhoneNotReady.
  ///
  /// In en, this message translates to:
  /// **'This phone number is not ready for WhatsApp.'**
  String get whatsAppPhoneNotReady;

  /// No description provided for @couldNotOpenWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Could not open WhatsApp right now.'**
  String get couldNotOpenWhatsApp;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @privacyPolicyDescription.
  ///
  /// In en, this message translates to:
  /// **'Read how this app collects, uses, and protects your data.'**
  String get privacyPolicyDescription;

  /// No description provided for @openPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Open Privacy Policy'**
  String get openPrivacyPolicy;

  /// No description provided for @couldNotOpenPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'The privacy policy could not be opened right now.'**
  String get couldNotOpenPrivacyPolicy;

  /// No description provided for @whatsAppGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello {name}'**
  String whatsAppGreeting(String name);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'he'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'he':
      return AppLocalizationsHe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
