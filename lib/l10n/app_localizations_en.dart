// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String accountCreatedFor(String username) {
    return 'Account created for $username';
  }

  @override
  String get accountRole => 'Account role';

  @override
  String get add => 'Add';

  @override
  String get allAvailableCarNamesAlreadySelected =>
      'All available car names are already selected.';

  @override
  String get appTitle => 'MTA';

  @override
  String get backend => 'Backend';

  @override
  String get carCatalogCouldNotBeLoadedRightNow =>
      'The car catalog could not be loaded right now.';

  @override
  String get carName => 'Car name';

  @override
  String get carsIHavePartsFor => 'Cars I have parts for';

  @override
  String get changeLanguage => 'Change language';

  @override
  String get chats => 'Chats';

  @override
  String get chooseAUsername => 'Choose a username';

  @override
  String conversationNumber(int id) {
    return 'Conversation #$id';
  }

  @override
  String get conversations => 'Conversations';

  @override
  String get createAccount => 'Create account';

  @override
  String get createNewAccount => 'Create new account';

  @override
  String get creating => 'Creating...';

  @override
  String daysAgo(int count) {
    return '$count days ago';
  }

  @override
  String get editProfile => 'Edit profile';

  @override
  String get profileCouldNotBeLoadedRightNow =>
      'Your profile could not be loaded right now.';

  @override
  String get keepYourProfileUpToDate => 'Keep your profile up to date';

  @override
  String get supplierProfileIntro =>
      'Update the details buyers see, tune chat notifications, and choose the car models you already stock parts for.';

  @override
  String get buyerProfileIntro =>
      'Update the details suppliers see and tune how chat notifications reach you.';

  @override
  String get email => 'Email';

  @override
  String get emailHint => 'name@example.com';

  @override
  String get enterAValidEmailAddress => 'Enter a valid email address';

  @override
  String get enterPassword => 'Enter password';

  @override
  String get enterUsername => 'Enter username';

  @override
  String get enterYourEmail => 'Enter your email';

  @override
  String get enterYourFullName => 'Enter your full name';

  @override
  String get fullName => 'Full name';

  @override
  String get fullNameHint => 'Enter your full name';

  @override
  String hoursAgo(int count) {
    return '$count hours ago';
  }

  @override
  String get justNow => 'Just now';

  @override
  String get language => 'Language';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHebrew => 'עברית';

  @override
  String get languageSystemDefault => 'System default';

  @override
  String lastSeenOn(String time) {
    return 'Last seen on $time';
  }

  @override
  String lastSeenRelative(String time) {
    return 'Last seen $time';
  }

  @override
  String get loadMore => 'Load more';

  @override
  String get loading => 'Loading...';

  @override
  String get logout => 'Logout';

  @override
  String minutesAgo(int count) {
    return '$count minutes ago';
  }

  @override
  String get newMessage => 'New message';

  @override
  String get noCarNamesSelectedYet => 'No car names selected yet.';

  @override
  String get noConversationsYet => 'No conversations yet';

  @override
  String get noConversationsYetMessage =>
      'You have not started any conversations yet.';

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get offline => 'Offline';

  @override
  String get online => 'Online';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => 'Enter password';

  @override
  String get passwordMinHint => 'At least 6 characters';

  @override
  String get pickTheCarNamesYouSupplyPartsFor =>
      'Pick the car names you supply parts for.';

  @override
  String get registerUsernameHint => 'Choose a username';

  @override
  String get remove => 'Remove';

  @override
  String get requests => 'Requests';

  @override
  String get selectLanguage => 'Select language';

  @override
  String get setUpMarketplaceProfile => 'Set up your marketplace profile';

  @override
  String get signIn => 'Sign in';

  @override
  String get signingIn => 'Signing in...';

  @override
  String get signInToBrowseSellerRequests =>
      'Sign in to browse customer requests and chat.';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get supplierRole => 'Supplier';

  @override
  String get suppliersCanPostRequests =>
      'Buyers can post requests and suppliers can start chats.';

  @override
  String get theCarCatalogCouldNotBeLoaded =>
      'The car catalog could not be loaded.';

  @override
  String get thisMessageWasDeleted => 'This message was deleted';

  @override
  String get tryAgain => 'Try again';

  @override
  String get useAtLeastSixCharacters => 'Use at least six characters';

  @override
  String get username => 'Username';

  @override
  String get usernameHint => 'Enter username';

  @override
  String get userRole => 'User';

  @override
  String get attachment => 'Attachment';

  @override
  String get attachedRequest => 'Attached request';

  @override
  String get cancel => 'Cancel';

  @override
  String get copyMessage => 'Copy message';

  @override
  String get deleteForAll => 'Delete for all';

  @override
  String get deleteMessage => 'Delete message';

  @override
  String get deleteOnlyMe => 'Delete only for me';

  @override
  String get deletedMessage => 'Deleted message';

  @override
  String get discardVoiceMessage => 'Discard voice message';

  @override
  String get editMessage => 'Edit message';

  @override
  String get editMessageTitle => 'Edit message';

  @override
  String get edited => 'Edited';

  @override
  String fromPrice(String value) {
    return 'From $value';
  }

  @override
  String get messageCopied => 'Message copied.';

  @override
  String get messageCouldNotBeDeleted => 'Message could not be deleted.';

  @override
  String get messageCouldNotBeUpdated => 'Message could not be updated.';

  @override
  String get messageDeletedForEveryone => 'Message deleted for everyone.';

  @override
  String get messageDeletedForYou => 'Message deleted for you.';

  @override
  String get messageLabel => 'Message';

  @override
  String get messageUpdated => 'Message updated.';

  @override
  String get microphonePermissionRequiredForVoiceMessage =>
      'Microphone permission is required to record a voice message.';

  @override
  String get noMessagesYetMessage => 'Say hello and start the conversation.';

  @override
  String get noPriceRange => 'No price range';

  @override
  String get noVoiceMessageCaptured => 'No voice message was captured.';

  @override
  String get pauseVoiceMessage => 'Pause voice message';

  @override
  String get photo => 'Photo';

  @override
  String photosCount(int count) {
    return '$count photos';
  }

  @override
  String get playVoiceMessage => 'Play voice message';

  @override
  String get preparingRecorder => 'Preparing recorder...';

  @override
  String get recordVoiceMessage => 'Record voice message';

  @override
  String replyingTo(String name) {
    return 'Replying to $name';
  }

  @override
  String requestWithTitle(String title) {
    return 'Request: $title';
  }

  @override
  String get save => 'Save';

  @override
  String get sendMessage => 'Send message';

  @override
  String get sendOrClearDraftBeforeVoiceMessage =>
      'Send or clear the current draft before recording a voice message.';

  @override
  String get sending => 'Sending...';

  @override
  String get sendVoiceMessage => 'Send voice message';

  @override
  String sentAttachmentsCount(int count) {
    return 'Sent $count attachment(s)';
  }

  @override
  String get sharedRequest => 'Shared a request';

  @override
  String get showOriginal => 'Show original';

  @override
  String get showTranslation => 'Show translation';

  @override
  String get typing => 'Typing...';

  @override
  String get unableToPlayVoiceMessage => 'Unable to play voice message';

  @override
  String get unableToSeekVoiceMessage => 'Unable to seek voice message';

  @override
  String get updateYourMessage => 'Update your message';

  @override
  String upToPrice(String value) {
    return 'Up to $value';
  }

  @override
  String get uploadImages => 'Upload images';

  @override
  String get voiceMessage => 'Voice message';

  @override
  String get voiceMessageCouldNotBeSent => 'Voice message could not be sent.';

  @override
  String get voiceMessageDiscarded => 'Voice message discarded.';

  @override
  String get voiceMessageDiscardFailed =>
      'Voice message could not be discarded cleanly.';

  @override
  String get voiceRecordingCouldNotStart =>
      'Voice recording could not start on this device.';

  @override
  String get writeAMessage => 'Write a message...';

  @override
  String get connecting => 'Connecting...';

  @override
  String get liveUpdatesUnavailable => 'Live updates unavailable';

  @override
  String get reconnecting => 'Reconnecting...';

  @override
  String get marketplaceUser => 'Marketplace user';

  @override
  String get refreshRequests => 'Refresh requests';

  @override
  String get browseRequestPostsFromOtherSellers =>
      'Browse request posts from other sellers.';

  @override
  String get seeRequestPostsYouCreated => 'See the request posts you created.';

  @override
  String get browseRequests => 'Browse Requests';

  @override
  String get myRequests => 'My Requests';

  @override
  String get noRequestsYet => 'No requests yet';

  @override
  String get createFirstRequestPostMessage =>
      'Create your first request post and it will show up here.';

  @override
  String get noSellerRequestsYet => 'No seller requests yet';

  @override
  String get noSellerRequestsYetMessage =>
      'There are no request posts from other sellers yet. Pull to refresh later.';

  @override
  String get createRequest => 'Create Request';

  @override
  String get deleteRequest => 'Delete Request';

  @override
  String deleteRequestConfirmation(String title) {
    return 'Delete \"$title\"? This request post will be removed from your list.';
  }

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get deleting => 'Deleting...';

  @override
  String get chat => 'Chat';

  @override
  String get opening => 'Opening...';

  @override
  String get requestDeletedSuccessfully => 'Request deleted successfully.';

  @override
  String get couldNotDeleteRequest => 'Could not delete the request.';

  @override
  String get couldNotOpenConversation => 'Could not open the conversation.';

  @override
  String get requestAttachedResendHint =>
      'The request is attached in the chat composer so you can resend it.';

  @override
  String get initialRequestCouldNotBeSentAutomatically =>
      'The chat opened, but the initial request could not be sent automatically.';

  @override
  String welcomeBackUser(String name) {
    return 'Welcome back, $name';
  }

  @override
  String get browse => 'Browse';

  @override
  String get mine => 'Mine';

  @override
  String get assigned => 'Assigned';

  @override
  String get assignedRequests => 'Assigned Requests';

  @override
  String get allStatuses => 'All Statuses';

  @override
  String get cityNotSet => 'City not set';

  @override
  String get thisRequestBelongsToYou => 'This request belongs to you.';

  @override
  String get openChatWithSellerBehindRequest =>
      'Open a chat with the seller behind this request.';

  @override
  String get requestsYouCanManageNow => 'Requests you can manage right now.';

  @override
  String get noAssignedRequestsYet => 'No assigned requests yet';

  @override
  String get noAssignedRequestsYetMessage =>
      'Once an owner approves your access, the request will appear here.';

  @override
  String get youCanManageThisRequestStatus =>
      'You can manage this request status.';

  @override
  String get changeStatus => 'Change Status';

  @override
  String get requestStatusUpdated => 'Request status updated.';

  @override
  String get couldNotUpdateRequestStatus =>
      'Could not update the request status.';

  @override
  String get updatingStatus => 'Updating...';

  @override
  String get requestControl => 'Request Control';

  @override
  String get thisChatCanManageRequestStatus =>
      'The supplier in this chat can manage this request status now.';

  @override
  String get thisRequestIsAssignedToAnotherSupplier =>
      'This request is currently assigned to another supplier.';

  @override
  String get noAccessRequestForThisRequestYet =>
      'No access request has been sent for this request yet.';

  @override
  String get youCanChangeThisRequestStatusNow =>
      'You can change this request status now.';

  @override
  String get waitingForOwnerApproval =>
      'Waiting for the owner to approve your access request.';

  @override
  String get ownerRejectedYourAccessRequest =>
      'The owner rejected your access request.';

  @override
  String get askOwnerForStatusAccess =>
      'Ask the owner for permission to manage this request status.';

  @override
  String currentManager(String name) {
    return 'Current manager: $name';
  }

  @override
  String get approving => 'Approving...';

  @override
  String get approveAccess => 'Approve Access';

  @override
  String get rejectAccess => 'Reject Access';

  @override
  String get sendingRequest => 'Sending...';

  @override
  String get requestAccess => 'Request Access';

  @override
  String get accessRequestPending => 'Your access request is pending.';

  @override
  String get openAssignedRequestsToUpdateStatus =>
      'Open Assigned Requests to update the status anytime.';

  @override
  String get accessRequestSent => 'Access request sent.';

  @override
  String get couldNotSendAccessRequest => 'Could not send the access request.';

  @override
  String get accessRequestApproved => 'Access request approved.';

  @override
  String get couldNotApproveAccessRequest =>
      'Could not approve the access request.';

  @override
  String get accessRequestRejected => 'Access request rejected.';

  @override
  String get couldNotRejectAccessRequest =>
      'Could not reject the access request.';

  @override
  String get expandRequestControl => 'Expand request controls';

  @override
  String get collapseRequestControl => 'Collapse request controls';

  @override
  String get adminPanel => 'Admin Panel';

  @override
  String get adminAccessRequired => 'Only admin accounts can open this panel.';

  @override
  String get adminUsersTab => 'Users';

  @override
  String get adminReportsTab => 'Reports';

  @override
  String get adminUsersCouldNotBeLoaded =>
      'The user list could not be loaded right now.';

  @override
  String get adminReportsCouldNotBeLoaded =>
      'The reports could not be loaded right now.';

  @override
  String get noUserReportsYet => 'No user reports yet.';

  @override
  String blockUserTitle(String name) {
    return 'Block $name';
  }

  @override
  String get blockUserAction => 'Block User';

  @override
  String get blockReasonLabel => 'Block reason';

  @override
  String get blockReasonHint => 'Add an optional reason for this action.';

  @override
  String unblockUserTitle(String name) {
    return 'Unblock $name';
  }

  @override
  String unblockUserMessage(String name) {
    return 'Allow $name to access the app again?';
  }

  @override
  String get unblockUserAction => 'Unblock User';

  @override
  String get userBlocked => 'User blocked.';

  @override
  String get userUnblocked => 'User unblocked.';

  @override
  String get couldNotBlockUser => 'Could not block the user.';

  @override
  String get couldNotUnblockUser => 'Could not unblock the user.';

  @override
  String get reviewReportTitle => 'Review Report';

  @override
  String get reviewReportAction => 'Review';

  @override
  String get reportStatusLabel => 'Report status';

  @override
  String get reportStatusOpen => 'Open';

  @override
  String get reportStatusReviewed => 'Reviewed';

  @override
  String get reportStatusDismissed => 'Dismissed';

  @override
  String get reportStatusActioned => 'Actioned';

  @override
  String get reportUpdated => 'Report updated.';

  @override
  String get couldNotUpdateReport => 'Could not update the report.';

  @override
  String get adminNotesLabel => 'Admin notes';

  @override
  String get adminNotesHint => 'Add review notes for the moderation team.';

  @override
  String get userBlockedStatus => 'Blocked';

  @override
  String get userActiveStatus => 'Active';

  @override
  String get adminCurrentAccount => 'This is your current account.';

  @override
  String get adminRole => 'Admin';

  @override
  String reportCardTitle(String name) {
    return 'Report about $name';
  }

  @override
  String reportedByLabel(String name) {
    return 'Reported by $name';
  }

  @override
  String reportCreatedAt(String time) {
    return 'Created $time';
  }

  @override
  String reportReviewedAt(String time) {
    return 'Reviewed $time';
  }

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileLoadError => 'This profile could not be loaded right now.';

  @override
  String get contactDetails => 'Contact Details';

  @override
  String get phone => 'Phone';

  @override
  String get cityLabel => 'City';

  @override
  String get filterByCarMake => 'Filter by car make';

  @override
  String get chatPushNotifications => 'Chat push notifications';

  @override
  String get chatPushNotificationsDescription =>
      'Receive a notification when someone sends a chat message.';

  @override
  String get showMessagePreview => 'Show message preview';

  @override
  String get showMessagePreviewDescription =>
      'Include part of the chat message inside notifications.';

  @override
  String get profileUpdatedSuccessfully => 'Profile updated successfully.';

  @override
  String get profilePhoto => 'Profile Photo';

  @override
  String get newPhotoReadyMessage =>
      'A new photo is ready. Save your profile to apply it.';

  @override
  String get choosePhotoForRequestsAndChats =>
      'Choose a photo so your name is easier to recognize in requests and chats.';

  @override
  String get chooseAnotherPhoto => 'Choose Another Photo';

  @override
  String get changePhoto => 'Change Photo';

  @override
  String get undoPhotoChange => 'Undo Photo Change';

  @override
  String get noCarModelsSelectedYetMessage =>
      'No car models selected yet. Pick the models you support from the catalog below.';

  @override
  String get deleteAccountTitle => 'Delete Account';

  @override
  String get deleteAccountPermanentMessage =>
      'This permanently deletes your account, your request posts, your chat history, and your registered devices. This action cannot be undone.';

  @override
  String get accountDeletedSuccessfully => 'Your account has been deleted.';

  @override
  String get accountCouldNotBeDeletedRightNow =>
      'Your account could not be deleted right now.';

  @override
  String get deleteAccountDangerDescription =>
      'Remove your profile and permanently delete the data that belongs to your account if you no longer want to use the app.';

  @override
  String get pleaseWait => 'Please wait...';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get quickActionsDescription =>
      'Start a direct conversation or open WhatsApp using the supplier phone number.';

  @override
  String get openingChat => 'Opening chat...';

  @override
  String get chatAction => 'Chat';

  @override
  String get openingWhatsApp => 'Opening WhatsApp...';

  @override
  String get whatsAppAction => 'WhatsApp';

  @override
  String get supplierCarsTitle => 'Cars This Supplier Works With';

  @override
  String get supplierCarsDescription =>
      'These are the car brands selected on the supplier profile.';

  @override
  String ratingLabel(String value) {
    return 'Rating $value';
  }

  @override
  String joinedLabel(String time) {
    return 'Joined $time';
  }

  @override
  String get reportUserSectionTitle => 'Report User';

  @override
  String get reportUserSectionBody =>
      'Send a safety report if this user is abusing chat or request access.';

  @override
  String get reportUserAction => 'Report User';

  @override
  String get sendingReport => 'Sending report...';

  @override
  String reportUserDialogTitle(String name) {
    return 'Report $name';
  }

  @override
  String get reportReasonLabel => 'Reason';

  @override
  String get reportDetailsLabel => 'Details';

  @override
  String get reportDetailsHint =>
      'Add any context that would help the admin review this report.';

  @override
  String get sendReport => 'Send Report';

  @override
  String get userReportSubmitted => 'Report sent.';

  @override
  String get couldNotSendUserReport => 'Could not send the report.';

  @override
  String get reportReasonSpam => 'Spam';

  @override
  String get reportReasonFraud => 'Fraud';

  @override
  String get reportReasonHarassment => 'Harassment';

  @override
  String get reportReasonImpersonation => 'Impersonation';

  @override
  String get reportReasonOther => 'Other';

  @override
  String get couldNotOpenChatRightNow => 'Could not open the chat right now.';

  @override
  String get whatsAppPhoneNotReady =>
      'This phone number is not ready for WhatsApp.';

  @override
  String get couldNotOpenWhatsApp => 'Could not open WhatsApp right now.';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get privacyPolicyDescription =>
      'Read how this app collects, uses, and protects your data.';

  @override
  String get openPrivacyPolicy => 'Open Privacy Policy';

  @override
  String get couldNotOpenPrivacyPolicy =>
      'The privacy policy could not be opened right now.';

  @override
  String get requestUpdatedSuccessfully => 'Request updated successfully.';

  @override
  String get requestCreatedSuccessfully => 'Request created successfully.';

  @override
  String get editRequestTitle => 'Edit Request';

  @override
  String get createRequestTitle => 'Create Request';

  @override
  String get updateYourRequest => 'Update your request';

  @override
  String get postNewRequest => 'Post a new request';

  @override
  String get editRequestDescription =>
      'Refresh the request details and the photos you want buyers to see.';

  @override
  String get createRequestDescription =>
      'Create a request that suppliers can browse and open chats from.';

  @override
  String get requestCreationBlocked => 'Request creation is blocked';

  @override
  String get currentStatus => 'Current status';

  @override
  String get initialStatus => 'Initial status';

  @override
  String currentStatusMessage(String status) {
    return 'This request is currently marked as \"$status\".';
  }

  @override
  String initialStatusMessage(String status) {
    return 'New requests will start as \"$status\".';
  }

  @override
  String get requestTitleLabel => 'Request title';

  @override
  String get requestTitleHint => 'Front bumper for Toyota Camry 2022';

  @override
  String get enterRequestTitle => 'Enter a request title.';

  @override
  String get requestDescriptionLabel => 'Description';

  @override
  String get requestDescriptionHint =>
      'Describe the condition, brand preference, or model details buyers should know.';

  @override
  String get addShortDescription => 'Add a short description.';

  @override
  String get carModelLabel => 'Car model';

  @override
  String get carModelDescription =>
      'Choose the exact car model this request is for so only matching suppliers get notified.';

  @override
  String get addCarManually => 'Add car manually';

  @override
  String get addCarManuallyDescription =>
      'Use this if you cannot find the make or model in the catalog yet.';

  @override
  String get carMakeLabel => 'Car make';

  @override
  String get carModelSearchLabel => 'Search car model';

  @override
  String get carModelSearchHint => 'Audi RS7';

  @override
  String get clearCarModelSearch => 'Clear search';

  @override
  String get carModelSearchFailed => 'Car model search failed. Try again.';

  @override
  String get noMatchingCarModelsFound => 'No matching car models found.';

  @override
  String get newCarMakeLabel => 'New car make';

  @override
  String get newCarMakeHint => 'Toyota';

  @override
  String get newCarModelLabel => 'New car model';

  @override
  String get newCarModelHint => 'Camry 2024';

  @override
  String get cityOptionalLabel => 'City (Optional)';

  @override
  String get cityOptionalHint => 'Riyadh';

  @override
  String get addPhotos => 'Add Photos';

  @override
  String get addMorePhotos => 'Add More Photos';

  @override
  String get minPriceLabel => 'Min price';

  @override
  String get maxPriceLabel => 'Max price';

  @override
  String get maxPriceMustBeGreaterThanMinPrice =>
      'Max price must be greater than min price.';

  @override
  String get saving => 'Saving...';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get enterValidNumber => 'Enter a valid number.';

  @override
  String get enterCarMake => 'Enter the car make.';

  @override
  String get enterCarModel => 'Enter the car model.';

  @override
  String get enterCarMakeAndModelBeforeSaving =>
      'Enter both the car make and model before saving this request.';

  @override
  String get chooseCarModelBeforeSaving =>
      'Choose a car model before saving this request.';

  @override
  String get viewMyRequests => 'View My Requests';

  @override
  String get viewRequest => 'View Request';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get appUpdateAvailableMessage =>
      'A new version of MTA is available. Update now to get the latest features and improvements.';

  @override
  String get updateNow => 'Update Now';

  @override
  String get later => 'Later';

  @override
  String get couldNotOpenAppStore =>
      'The app store could not be opened right now.';

  @override
  String whatsAppGreeting(String name) {
    return 'Hello $name';
  }
}
