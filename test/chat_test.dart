import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaia_mobile/models/chat.dart';
import 'package:gaia_mobile/pages/chat_page.dart';
import 'package:gaia_mobile/services/chat_api.dart';

class _FakeChatApi extends ChatApi {
  final sent = <String>[];

  @override
  Future<List<Conversation>> fetchConversations({
    String query = '',
    bool unreadOnly = false,
  }) async =>
      [
        Conversation(
          id: 1,
          kind: 'product',
          title: 'Studio Terra',
          initials: 'ST',
          preview: 'Halo, masih ada kok',
          lastAt: DateTime.now(),
          unread: 1,
          productTitle: 'The Everyday Tote',
        ),
      ];

  @override
  Future<List<ChatMessage>> fetchMessages(int conversationId,
          {int after = 0}) async =>
      [
        ChatMessage(
          id: 1,
          kind: 'text',
          body: 'Halo, masih ada kok',
          mine: false,
          read: true,
          createdAt: DateTime.now(),
          sender: 'Studio Terra',
        ),
      ];

  @override
  Future<ChatMessage> sendText(int conversationId, String body) async {
    sent.add(body);
    return ChatMessage(
      id: 2,
      kind: 'text',
      body: body,
      mine: true,
      read: false,
      createdAt: DateTime.now(),
    );
  }
}

class _GuestChatApi extends ChatApi {
  @override
  Future<List<Conversation>> fetchConversations({
    String query = '',
    bool unreadOnly = false,
  }) async =>
      throw const ChatAuthException();
}

void main() {
  testWidgets('inbox opens a conversation and sends a message', (tester) async {
    final api = _FakeChatApi();
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ChatPage(api: api))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Studio Terra'), findsOneWidget);
    expect(find.text('The Everyday Tote · Halo, masih ada kok'), findsOneWidget);

    await tester.tap(find.text('Studio Terra'));
    await tester.pumpAndSettle();
    expect(find.text('Halo, masih ada kok'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Bisa COD?');
    await tester.tap(find.byTooltip('Kirim'));
    await tester.pumpAndSettle();

    expect(api.sent, ['Bisa COD?']);
    expect(find.text('Bisa COD?'), findsOneWidget);
  });

  testWidgets('guest sees login prompt', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ChatPage(api: _GuestChatApi()))),
    );
    await tester.pumpAndSettle();
    expect(find.text('Belum masuk'), findsOneWidget);
  });
}
