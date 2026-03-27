import '../../models/models.dart';

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
  final prefix = lastMessage.senderName.trim().isEmpty
      ? ''
      : '${lastMessage.senderName}: ';
  return '$prefix${lastMessage.text}'.trim();
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
