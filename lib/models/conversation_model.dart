class ConversationModel {
  final int id;
  final int otherUserId;
  final String otherUserName;
  final String otherUserAvatar;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final bool isOnline;
  final DateTime? lastSeen; // ✅ الحقل الجديد لتوقيت آخر ظهور

  ConversationModel({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserAvatar,
    required this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
    this.lastSeen,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: int.parse(json['conversation_id'].toString()),
      otherUserId: int.parse(json['other_user_id'].toString()),
      otherUserName: json['other_user_name'] ?? '',
      otherUserAvatar: json['other_user_avatar'] ?? '',
      lastMessage: json['last_message'] ?? '',
      lastMessageTime: json['last_message_time'] != null && json['last_message_time'] != ''
          ? DateTime.parse(json['last_message_time'])
          : null,
      unreadCount: int.parse(json['unread_count']?.toString() ?? '0'),
      isOnline: json['is_online'] == 1 || json['is_online'] == true,
      // ✅ استقبال توقيت آخر ظهور من السيرفر
      lastSeen: json['last_seen'] != null && json['last_seen'] != ''
          ? DateTime.parse(json['last_seen'])
          : null,
    );
  }
}
