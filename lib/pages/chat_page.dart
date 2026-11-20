import 'package:flutter/material.dart';

import '../models/chat.dart';
import '../services/chat_api.dart';
import 'chat_room_page.dart';

/// Inbox modul Chat: daftar percakapan user dari `/api/chat/conversations/`.
class ChatPage extends StatefulWidget {
  const ChatPage({super.key, this.api});

  final ChatApi? api;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ChatApi _api;
  late Future<List<Conversation>> _future;
  bool _unreadOnly = false;

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? ChatApi();
    _future = _api.fetchConversations();
  }

  Future<void> _reload() async {
    final request = _api.fetchConversations(unreadOnly: _unreadOnly);
    setState(() => _future = request);
    try {
      await request;
    } catch (_) {
      // FutureBuilder yang menampilkan error-nya.
    }
  }

  Future<void> _open(Conversation conversation) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatRoomPage(api: _api, conversation: conversation),
      ),
    );
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('Semua'),
                selected: !_unreadOnly,
                onSelected: (_) {
                  _unreadOnly = false;
                  _reload();
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Belum dibaca'),
                selected: _unreadOnly,
                onSelected: (_) {
                  _unreadOnly = true;
                  _reload();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Conversation>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.error is ChatAuthException) {
                return const _InfoState(
                  icon: Icons.lock_outline,
                  title: 'Belum masuk',
                  message:
                      'Masuk ke akun GAIA lewat tab Akun untuk melihat chat dengan seller dan Gaia Care.',
                );
              }
              if (snapshot.hasError) {
                return _InfoState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Chat belum bisa dimuat',
                  message: snapshot.error.toString(),
                  onRetry: _reload,
                );
              }
              final rows = snapshot.data ?? [];
              if (rows.isEmpty) {
                return _InfoState(
                  icon: Icons.chat_bubble_outline,
                  title: 'Belum ada percakapan',
                  message: _unreadOnly
                      ? 'Semua pesan sudah dibaca.'
                      : 'Mulai chat dari halaman detail produk.',
                  onRetry: _reload,
                );
              }
              return RefreshIndicator(
                onRefresh: _reload,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) => _ConversationTile(
                    conversation: rows[index],
                    onTap: () => _open(rows[index]),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation, required this.onTap});

  final Conversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = conversation.unread > 0;
    final subtitle = conversation.productTitle == null
        ? conversation.preview
        : '${conversation.productTitle} · ${conversation.preview}';
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: Colors.green.shade100,
        child: Text(conversation.initials),
      ),
      title: Text(
        conversation.title,
        style: TextStyle(fontWeight: unread ? FontWeight.bold : null),
      ),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(formatChatTime(conversation.lastAt),
              style: Theme.of(context).textTheme.bodySmall),
          if (unread) ...[
            const SizedBox(height: 4),
            Badge(label: Text('${conversation.unread}')),
          ],
        ],
      ),
    );
  }
}

class _InfoState extends StatelessWidget {
  const _InfoState({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: Colors.green),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(message, textAlign: TextAlign.center),
              if (onRetry != null) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Muat ulang'),
                ),
              ],
            ],
          ),
        ),
      );
}

/// Jam (HH:mm) kalau hari ini, selain itu tanggal (dd/mm).
String formatChatTime(DateTime time) {
  final now = DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  if (time.year == now.year && time.month == now.month && time.day == now.day) {
    return '${two(time.hour)}:${two(time.minute)}';
  }
  return '${two(time.day)}/${two(time.month)}';
}
