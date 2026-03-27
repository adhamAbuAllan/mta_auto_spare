String formatRelativeTime(DateTime? value) {
  if (value == null) {
    return 'Just now';
  }

  final now = DateTime.now();
  final difference = now.difference(value.toLocal());

  if (difference.inSeconds < 60) {
    return 'Just now';
  }
  if (difference.inMinutes < 60) {
    final minutes = difference.inMinutes;
    return '$minutes minute${minutes == 1 ? '' : 's'} ago';
  }
  if (difference.inHours < 24) {
    final hours = difference.inHours;
    return '$hours hour${hours == 1 ? '' : 's'} ago';
  }
  if (difference.inDays < 7) {
    final days = difference.inDays;
    return '$days day${days == 1 ? '' : 's'} ago';
  }

  return '${value.day}/${value.month}/${value.year}';
}
