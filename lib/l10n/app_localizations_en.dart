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
  String get appTitle => 'MTA Auto Spare';

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
      'Sign in to browse seller requests and chat.';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get supplierRole => 'Supplier';

  @override
  String get suppliersCanPostRequests =>
      'Suppliers can post requests and buyers can start chats.';

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
}
