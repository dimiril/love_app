class MessageModel {
  final int id;
  final int categoryId;
  final bool isFavorite;
  final String content;
  final String author;
  final String? messageType;
  final DateTime? createdAt;

  MessageModel({
    required this.id,
    required this.categoryId,
    required this.isFavorite,
    required this.content,
    this.author = 'alweeeb',
    this.messageType,
    this.createdAt,
  });

  MessageModel copyWith({
    int? id,
    int? categoryId,
    bool? isFavorite,
    String? content,
    String? author,
    String? messageType,
    DateTime? createdAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      isFavorite: isFavorite ?? this.isFavorite,
      content: content ?? this.content,
      author: author ?? this.author,
      messageType: messageType ?? this.messageType,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] as int,
      categoryId: map['category_id'] as int,
      isFavorite: (map['is_favorite'] == 1 || map['is_favorite'] == true),
      content: map['content'] as String,
      author: map['author'] as String? ?? 'alweeeb',
      messageType: map['message_type'] as String?,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'is_favorite': isFavorite ? 1 : 0,
      'content': content,
      'author': author,
      'message_type': messageType,
      'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }
}
