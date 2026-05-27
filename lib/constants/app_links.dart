import 'api_constants.dart';

abstract final class AppLinks {
  static final Uri privacyPolicy = Uri.parse(
    ApiConstants.ngrok,
  ).resolve('/privacy-policy/');
}
