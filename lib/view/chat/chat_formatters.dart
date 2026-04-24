import 'package:mta_auto_spare/l10n/app_localizations.dart';

import '../../models/models.dart';
import '../common_widgets/time_formatter.dart';

String conversationDisplayName(
  ConversationListItem conversation,
  int currentUserId,
  AppLocalizations l10n,
) {
  final others = conversation.participants
      .where((participant) => participant.user.id != currentUserId)
      .map((participant) => participant.user.name)
      .where((name) => name.trim().isNotEmpty)
      .toList(growable: false);

  if (others.isNotEmpty) {
    return others.join(', ');
  }
  if (conversation.title.trim().isNotEmpty) {
    return conversation.title;
  }
  return l10n.conversationNumber(conversation.id);
}

String conversationPreview(
  ConversationListItem conversation,
  AppLocalizations l10n,
) {
  final lastMessage = conversation.lastMessage;
  if (lastMessage == null) {
    return l10n.noMessagesYet;
  }
  if (lastMessage.isDeleted) {
    return l10n.thisMessageWasDeleted;
  }

  final translatedPreview = lastMessage.displayText.trim();
  if (translatedPreview.isNotEmpty) {
    return translatedPreview;
  }

  switch (lastMessage.messageType) {
    case 'product':
      final title = lastMessage.product?.displayTitle.trim();
      if (title != null && title.isNotEmpty) {
        return l10n.requestWithTitle(title);
      }
      return l10n.sharedRequest;
    case 'media':
      return l10n.newMessage;
    default:
      return l10n.newMessage;
  }
}

ConversationParticipantRead? otherParticipant(
  ConversationListItem conversation,
  int currentUserId,
) {
  for (final participant in conversation.participants) {
    if (participant.user.id != currentUserId) {
      return participant;
    }
  }
  return null;
}

String conversationPresenceLabel({
  required bool isOnline,
  DateTime? lastSeenAt,
  required AppLocalizations l10n,
}) {
  if (isOnline) {
    return l10n.online;
  }
  if (lastSeenAt == null) {
    return l10n.offline;
  }

  final localValue = lastSeenAt.toLocal();
  final difference = DateTime.now().difference(localValue);
  if (difference.inDays >= 3) {
    return l10n.lastSeenOn(formatRelativeTime(localValue, l10n));
  }
  return l10n.lastSeenRelative(formatRelativeTime(localValue, l10n));
}
