/// Satu baris inbox dari `GET /api/chat/conversations/`.
class Conversation {
  const Conversation({
    required this.id,
    required this.kind,
    required this.title,
    required this.initials,
    required this.preview,
    required this.lastAt,
    required this.unread,
    this.productTitle,
  });

  final int id;

  /// `product`, `order`, atau `support` (Gaia Care).
  final String kind;
  final String title;
  final String initials;
  final String preview;
  final DateTime lastAt;
  final int unread;
  final String? productTitle;

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    return Conversation(
      id: json['id'] as int,
      kind: json['kind'] as String? ?? 'product',
      title: json['title'] as String? ?? 'Chat',
      initials: json['initials'] as String? ?? '?',
      preview: json['preview'] as String? ?? '',
      lastAt: DateTime.tryParse(json['last_at'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      unread: (json['unread'] as num?)?.toInt() ?? 0,
      productTitle: product?['title'] as String?,
    );
  }
}

/// Satu pesan dari `GET /api/chat/conversations/<id>/messages/`.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.kind,
    required this.body,
    required this.mine,
    required this.read,
    required this.createdAt,
    this.sender,
    this.imageUrl,
    this.offerPrice,
    this.offerStatus,
    this.productTitle,
  });

  final int id;

  /// `text`, `image`, `offer`, `product`, atau `system`.
  final String kind;
  final String body;
  final bool mine;
  final bool read;
  final DateTime createdAt;
  final String? sender;
  final String? imageUrl;
  final int? offerPrice;
  final String? offerStatus;
  final String? productTitle;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    return ChatMessage(
      id: json['id'] as int,
      kind: json['kind'] as String? ?? 'text',
      body: json['body'] as String? ?? '',
      mine: json['mine'] as bool? ?? false,
      read: json['read'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal() ??
              DateTime.now(),
      sender: json['sender'] as String?,
      imageUrl: json['image'] as String?,
      offerPrice: (json['offer_price'] as num?)?.toInt(),
      offerStatus: json['offer_status'] as String?,
      productTitle: product?['title'] as String?,
    );
  }
}
