import '../../models/models.dart';
import '../common_widgets/time_formatter.dart';

String conversationDisplayName(
  ConversationListItem conversation,
  int currentUserId,
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
  return 'Conversation #${conversation.id}';
}

String conversationPreview(ConversationListItem conversation) {
  final lastMessage = conversation.lastMessage;
  if (lastMessage == null) {
    return 'No messages yet';
  }
  if (lastMessage.isDeleted) {
    return 'This message was deleted';
  }
  return lastMessage.text.trim().isEmpty
      ? 'New message'
      : lastMessage.text.trim();
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
}) {
  if (isOnline) {
    return 'Online';
  }
  if (lastSeenAt == null) {
    return 'Offline';
  }

  final localValue = lastSeenAt.toLocal();
  final difference = DateTime.now().difference(localValue);
  if (difference.inDays >= 3) {
    return 'Last seen ${localValue.day}/${localValue.month}/${localValue.year}';
  }
  return 'Last seen ${formatRelativeTime(localValue)}';
}
