import '../core/constants/api_urls.dart';
import '../models/private_message_model.dart';
import 'base_service.dart';

class PrivateMessageService extends BaseService {
  /// جلب الرسائل (الواردة أو الصادرة)
  Future<List<PrivateMessageModel>> fetchMessages({
    required int userId,
    required String folder, // 'inbox' or 'sent'
    int page = 1,
  }) async {
    final response = await safeGet(
      '${ApiUrls.baseUrl}/messages/private',
      queryParameters: {
        'user_id': userId,
        'folder': folder,
        'page': page,
      },
    );

    if (response != null && response.data['status'] == 'success') {
      final List data = response.data['data'];
      return data.map((m) => PrivateMessageModel.fromJson(m)).toList();
    }
    return [];
  }

  /// إرسال رسالة جديدة
  Future<bool> sendMessage({
    required int senderId,
    required int receiverId,
    String? subject,
    required String content,
  }) async {
    final response = await safePost(
      '${ApiUrls.baseUrl}/messages/private/send',
      data: {
        'sender_id': senderId,
        'receiver_id': receiverId,
        'subject': subject,
        'content': content,
      },
    );
    return response != null && response.data['status'] == 'success';
  }

  /// وضع علامة "مقروء" على الرسالة
  Future<void> markAsRead(int messageId) async {
    await safePost('${ApiUrls.baseUrl}/messages/private/read', data: {'id': messageId});
  }
}
