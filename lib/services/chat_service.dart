import '../core/constants/api_urls.dart';
import '../models/conversation_model.dart';
import '../models/private_message_model.dart';
import 'base_service.dart';

class ChatService extends BaseService {
  /// جلب قائمة المحادثات للمستخدم
  Future<List<ConversationModel>> fetchConversations(int userId, {int page = 1}) async {
    final response = await safeGet(
      "${ApiUrls.conversations}/$userId",
      queryParameters: {'page': page},
    );

    if (response != null && response.data['status'] == 'success') {
      final List data = response.data['conversations'];
      return data.map((json) => ConversationModel.fromJson(json)).toList();
    }
    return [];
  }

  /// جلب الرسائل داخل محادثة معينة
  Future<List<PrivateMessageModel>> fetchMessages(int conversationId, {int page = 1}) async {
    final response = await safeGet(
      "${ApiUrls.chatMessages}/$conversationId",
      queryParameters: {'page': page},
    );

    if (response != null && response.data['status'] == 'success') {
      final List data = response.data['messages'];
      return data.map((json) => PrivateMessageModel.fromJson(json)).toList();
    }
    return [];
  }

  /// جلب معرف المحادثة بين مستخدمين
  Future<int?> getConversationId(int userId, int otherId) async {
    final response = await safeGet(
      "${ApiUrls.getChatId}/$userId/$otherId",
    );
    if (response != null && response.data['status'] == 'success') {
      return response.data['conversation_id'];
    }
    return null;
  }

  /// إرسال رسالة جديدة
  Future<bool> sendMessage({
    required int senderId,
    required int receiverId,
    required String message,
  }) async {
    final response = await safePost(
      ApiUrls.sendMessage,
      data: {
        'sender_id': senderId,
        'receiver_id': receiverId,
        'message': message,
      },
    );
    return response != null && response.data['status'] == 'success';
  }

  /// تحديث حالة الرسائل إلى "مقروءة"
  Future<void> markAsRead(int conversationId, int userId) async {
    await safePost(
      ApiUrls.markRead,
      data: {
        'conversation_id': conversationId,
        'user_id': userId,
      },
    );
  }

  /// ✅ حذف محادثة
  Future<bool> deleteConversation(int conversationId, int userId) async {
    final response = await safePost(
      '${ApiUrls.baseUrl}/messages/private/delete',
      data: {
        'conversation_id': conversationId,
        'user_id': userId,
      },
    );
    return response != null && response.data['status'] == 'success';
  }

  /// تحديث حالة المستخدم (Online/Offline)
  Future<void> updateUserStatus(int userId, bool isOnline) async {
    final url = isOnline ? "${ApiUrls.baseUrl}/messages/private/status/online/$userId" 
                         : "${ApiUrls.baseUrl}/messages/private/status/offline/$userId";
    await safePost(url);
  }
}
