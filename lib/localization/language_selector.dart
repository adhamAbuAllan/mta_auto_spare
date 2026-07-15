import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_locale.dart';
import 'app_locale_notifier.dart';
import 'app_localizations_x.dart';

String localizedLanguageLabel(BuildContext context, AppLocaleMode mode) {
  final l10n = context.l10n;
  return switch (mode) {
    AppLocaleMode.system => l10n.languageSystemDefault,
    AppLocaleMode.en => l10n.languageEnglish,
    AppLocaleMode.ar => l10n.languageArabic,
    AppLocaleMode.he => l10n.languageHebrew,
    AppLocaleMode.ru => l10n.languageRussian,
  };
}

class AppLanguageMenuButton extends ConsumerWidget {
  const AppLanguageMenuButton({super.key, this.foregroundColor});

  final Color? foregroundColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appLocaleProvider);
    final resolvedForegroundColor =
        foregroundColor ?? Theme.of(context).colorScheme.onSurface;

    return PopupMenuButton<AppLocaleMode>(
      tooltip: context.l10n.changeLanguage,
      initialValue: mode,
      onSelected: (value) {
        ref.read(appLocaleProvider.notifier).setMode(value);
      },
      itemBuilder: (context) {
        return [
          for (final option in AppLocaleMode.values)
            PopupMenuItem<AppLocaleMode>(
              value: option,
              child: Row(
                children: [
                  Expanded(
                    child: Text(localizedLanguageLabel(context, option)),
                  ),
                  if (mode == option) const Icon(Icons.check_rounded, size: 18),
                ],
              ),
            ),
        ];
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.translate_rounded,
              size: 18,
              color: resolvedForegroundColor,
            ),
            const SizedBox(width: 8),
            Text(
              localizedLanguageLabel(context, mode),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: resolvedForegroundColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppLanguageSettingTile extends ConsumerWidget {
  const AppLanguageSettingTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appLocaleProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F8F7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD5E8E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.language,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<AppLocaleMode>(
            initialValue: mode,
            decoration: InputDecoration(labelText: context.l10n.selectLanguage),
            items: [
              for (final option in AppLocaleMode.values)
                DropdownMenuItem<AppLocaleMode>(
                  value: option,
                  child: Text(localizedLanguageLabel(context, option)),
                ),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }
              ref.read(appLocaleProvider.notifier).setMode(value);
            },
          ),
        ],
      ),
    );
  }
}
