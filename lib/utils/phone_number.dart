const supportedAuthCountryCodes = <String>{'970', '972'};
const supportedAuthCountryCodeLabel = '+970 or +972';
const authPhoneHintText = '+97...';

String normalizePhoneForAuth(String value) {
  final compact = value.trim().replaceAll(RegExp(r'[\s().-]'), '');
  if (compact.startsWith('+')) {
    return compact;
  }
  if (compact.startsWith('00')) {
    return '+${compact.substring(2)}';
  }

  final digitsOnly = compact.replaceAll(RegExp(r'\D'), '');
  if (digitsOnly.isEmpty) {
    return '';
  }
  return '+$digitsOnly';
}

bool isValidE164Phone(String value) {
  return RegExp(r'^\+[1-9]\d{8,15}$').hasMatch(value.trim());
}

bool isSupportedAuthPhone(String value) {
  final phone = value.trim();
  if (!isValidE164Phone(phone)) {
    return false;
  }
  final digitsOnly = phone.substring(1);
  return supportedAuthCountryCodes.any(digitsOnly.startsWith);
}

String? authPhoneInputError(String value) {
  final phone = normalizePhoneForAuth(value);
  if (phone.isEmpty) {
    return 'Enter your phone number.';
  }
  if (!isValidE164Phone(phone)) {
    return 'Enter a valid phone number in international format.';
  }
  if (!isSupportedAuthPhone(phone)) {
    return 'Use a $supportedAuthCountryCodeLabel phone number.';
  }
  return null;
}
