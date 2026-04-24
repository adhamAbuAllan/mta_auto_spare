import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mta_auto_spare/l10n/app_localizations.dart';
import 'package:mta_auto_spare/models/models.dart';
import 'package:mta_auto_spare/view/chat/widgets/message_bubble.dart';

void main() {
  testWidgets('swiping a message bubble to the right triggers reply', (
    tester,
  ) async {
    var replyCount = 0;

    await tester.pumpWidget(
      _buildTestApp(
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
      _buildTestApp(
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
      _buildTestApp(
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

  testWidgets('deleted messages render a deleted placeholder', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        home: Scaffold(
          body: Center(
            child: MessageBubble(
              message: _sampleMessage(isDeleted: true, text: ''),
              currentUserId: 1,
              isMine: true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('This message was deleted'), findsOneWidget);
    expect(find.text('Hello'), findsNothing);
  });

  testWidgets('edited messages show the edited label', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        home: Scaffold(
          body: Center(
            child: MessageBubble(
              message: _sampleMessage(
                editedAt: DateTime.parse('2026-03-31T18:05:00Z'),
              ),
              currentUserId: 1,
              isMine: true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Edited'), findsOneWidget);
  });

  testWidgets('translated messages can toggle back to the original text', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildTestApp(
        home: Scaffold(
          body: Center(
            child: MessageBubble(
              message: _sampleMessage(
                text: 'Need bumper',
                translatedText: 'احتاج صدام',
              ),
              currentUserId: 1,
              isMine: false,
            ),
          ),
        ),
      ),
    );

    expect(find.text('احتاج صدام'), findsOneWidget);
    expect(find.text('Need bumper'), findsNothing);
    expect(find.text('Show original'), findsOneWidget);

    await tester.tap(find.text('Show original'));
    await tester.pumpAndSettle();

    expect(find.text('Need bumper'), findsOneWidget);
    expect(find.text('Show translation'), findsOneWidget);
  });
}

Widget _buildTestApp({required Widget home}) {
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: home,
  );
}

MessageModel _sampleMessage({
  String text = 'Hello',
  String? translatedText,
  DateTime? editedAt,
  bool isDeleted = false,
}) {
  return MessageModel(
    id: 1,
    conversationId: 2,
    sender: const UserBrief(id: 2, name: 'Seller'),
    messageType: 'text',
    text: text,
    translatedText: translatedText,
    media: const [],
    clientTimestamp: DateTime.parse('2026-03-31T18:00:00Z'),
    serverTimestamp: DateTime.parse('2026-03-31T18:00:01Z'),
    editedAt: editedAt,
    isDeleted: isDeleted,
    statuses: const [],
  );
}
