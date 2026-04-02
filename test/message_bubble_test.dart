import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mta_auto_spare/models/models.dart';
import 'package:mta_auto_spare/view/chat/widgets/message_bubble.dart';

void main() {
  testWidgets('swiping a message bubble to the right triggers reply', (
    tester,
  ) async {
    var replyCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: MessageBubble(
              message: _sampleMessage(),
              currentUserId: 1,
              isMine: false,
              onReply: () => replyCount += 1,
            ),
          ),
        ),
      ),
    );

    await tester.drag(find.text('Hello'), const Offset(90, 0));
    await tester.pumpAndSettle();

    expect(replyCount, 1);
  });

  testWidgets('a short swipe does not trigger reply', (tester) async {
    var replyCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: MessageBubble(
              message: _sampleMessage(),
              currentUserId: 1,
              isMine: false,
              onReply: () => replyCount += 1,
            ),
          ),
        ),
      ),
    );

    await tester.drag(find.text('Hello'), const Offset(20, 0));
    await tester.pumpAndSettle();

    expect(replyCount, 0);
  });

  testWidgets('long press no longer triggers reply', (tester) async {
    var replyCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: MessageBubble(
              message: _sampleMessage(),
              currentUserId: 1,
              isMine: false,
              onReply: () => replyCount += 1,
            ),
          ),
        ),
      ),
    );

    await tester.longPress(find.text('Hello'));
    await tester.pumpAndSettle();

    expect(replyCount, 0);
  });
}

MessageModel _sampleMessage() {
  return MessageModel(
    id: 1,
    conversationId: 2,
    sender: const UserBrief(id: 2, name: 'Seller'),
    messageType: 'text',
    text: 'Hello',
    media: const [],
    clientTimestamp: DateTime.parse('2026-03-31T18:00:00Z'),
    serverTimestamp: DateTime.parse('2026-03-31T18:00:01Z'),
    statuses: const [],
  );
}
