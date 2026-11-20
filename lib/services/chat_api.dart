import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/chat.dart';

/// Dilempar kalau server menolak karena user belum login (401/403).
class ChatAuthException implements Exception {
  const ChatAuthException();

  @override
  String toString() => 'Masuk ke akun GAIA dulu untuk membuka chat.';
}

/// Akses endpoint Django REST Framework modul Chat (`/api/chat/`).
class ChatApi {
  ChatApi({http.Client? client, this.headers = const {}})
      : _client = client ?? http.Client();

  static const baseUrl = String.fromEnvironment(
    'GAIA_CHAT_API_URL',
    defaultValue: 'https://danar-iqbal-gaia.pws.cs.ui.ac.id/api/chat/',
  );

  final http.Client _client;

  /// Header tambahan (mis. cookie sesi) setelah modul Autentikasi tersambung.
  final Map<String, String> headers;

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(
        queryParameters: (query == null || query.isEmpty) ? null : query,
      );

  dynamic _decode(http.Response response, {int expected = 200}) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const ChatAuthException();
    }
    if (response.statusCode != expected) {
      throw Exception('Server mengembalikan status ${response.statusCode}.');
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  /// Inbox. [query] untuk pencarian, [unreadOnly] untuk filter belum dibaca.
  Future<List<Conversation>> fetchConversations({
    String query = '',
    bool unreadOnly = false,
  }) async {
    final response = await _client
        .get(
          _uri('conversations/', {
            if (query.isNotEmpty) 'q': query,
            if (unreadOnly) 'filter': 'unread',
          }),
          headers: headers,
        )
        .timeout(const Duration(seconds: 15));
    final rows = _decode(response) as List;
    return rows
        .map((row) => Conversation.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Pesan di satu chat. [after] = id pesan terakhir yang sudah dimiliki.
  Future<List<ChatMessage>> fetchMessages(int conversationId,
      {int after = 0}) async {
    final response = await _client
        .get(
          _uri('conversations/$conversationId/messages/',
              after > 0 ? {'after': '$after'} : null),
          headers: headers,
        )
        .timeout(const Duration(seconds: 15));
    final rows = _decode(response) as List;
    return rows
        .map((row) => ChatMessage.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Kirim pesan teks.
  Future<ChatMessage> sendText(int conversationId, String body) async {
    final response = await _client
        .post(
          _uri('conversations/$conversationId/messages/'),
          headers: {...headers, 'Content-Type': 'application/json'},
          body: jsonEncode({'kind': 'text', 'body': body}),
        )
        .timeout(const Duration(seconds: 15));
    return ChatMessage.fromJson(
        _decode(response, expected: 201) as Map<String, dynamic>);
  }
}
