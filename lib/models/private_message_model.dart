class PrivateMessageModel {
  final int id;
  final int conversationId;
  final int senderId;
  final String message;
  final bool isSeen;
  final DateTime createdAt;

  PrivateMessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.message,
    this.isSeen = false,
    required this.createdAt,
  });

  factory PrivateMessageModel.fromJson(Map<String, dynamic> json) {
    return PrivateMessageModel(
      id: int.parse(json['id'].toString()),
      conversationId: int.parse(json['conversation_id'].toString()),
      senderId: int.parse(json['sender_id'].toString()),
      message: json['message'] ?? '',
      isSeen: json['is_seen'] == 1 || json['is_seen'] == true || json['is_seen'] == "1",
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
