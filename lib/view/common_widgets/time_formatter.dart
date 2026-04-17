import 'package:intl/intl.dart';
import 'package:mta_auto_spare/l10n/app_localizations.dart';

String formatRelativeTime(DateTime? value, AppLocalizations l10n) {
  if (value == null) {
    return l10n.justNow;
  }

  final now = DateTime.now();
  final difference = now.difference(value.toLocal());

  if (difference.inSeconds < 60) {
    return l10n.justNow;
  }
  if (difference.inMinutes < 60) {
    return l10n.minutesAgo(difference.inMinutes);
  }
  if (difference.inHours < 24) {
    return l10n.hoursAgo(difference.inHours);
  }
  if (difference.inDays < 7) {
    return l10n.daysAgo(difference.inDays);
  }

  return DateFormat.yMd(l10n.localeName).format(value.toLocal());
}
