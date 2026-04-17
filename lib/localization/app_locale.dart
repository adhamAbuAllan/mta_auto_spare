import 'dart:ui';

const appLocalePreferenceKey = 'app_locale_mode';

enum AppLocaleMode {
  system,
  en,
  ar,
  he;

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('ar'),
    Locale('he'),
  ];

  Locale? get locale => switch (this) {
    AppLocaleMode.system => null,
    AppLocaleMode.en => const Locale('en'),
    AppLocaleMode.ar => const Locale('ar'),
    AppLocaleMode.he => const Locale('he'),
  };

  String get storageValue => switch (this) {
    AppLocaleMode.system => 'system',
    AppLocaleMode.en => 'en',
    AppLocaleMode.ar => 'ar',
    AppLocaleMode.he => 'he',
  };

  static AppLocaleMode fromStorage(String? rawValue) {
    return switch ((rawValue ?? '').trim().toLowerCase()) {
      'en' => AppLocaleMode.en,
      'ar' => AppLocaleMode.ar,
      'he' => AppLocaleMode.he,
      'system' => AppLocaleMode.system,
      _ => AppLocaleMode.system,
    };
  }
}

Locale currentDeviceLocale() => PlatformDispatcher.instance.locale;

Locale resolveSupportedLocale({
  Locale? preferredLocale,
  List<Locale>? preferredLocales,
}) {
  final candidates = <Locale>[
    ?preferredLocale,
    ...?preferredLocales,
  ];
  for (final candidate in candidates) {
    final normalizedCode = candidate.languageCode.toLowerCase();
    for (final supportedLocale in AppLocaleMode.supportedLocales) {
      if (supportedLocale.languageCode == normalizedCode) {
        return supportedLocale;
      }
    }
  }
  return AppLocaleMode.supportedLocales.first;
}

Locale resolveEffectiveAppLocale({
  required AppLocaleMode mode,
  Locale? deviceLocale,
  List<Locale>? deviceLocales,
}) {
  final overrideLocale = mode.locale;
  if (overrideLocale != null) {
    return overrideLocale;
  }
  return resolveSupportedLocale(
    preferredLocale: deviceLocale,
    preferredLocales: deviceLocales,
  );
}
