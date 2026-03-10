import '../core/constants/api_urls.dart';
import '../models/user_model.dart';
import 'base_service.dart';

class BlockService extends BaseService {
  /// تنفيذ الحظر أو إلغاء الحظر بناءً على الحالة الحالية
  Future<bool> toggleBlock({
    required int blockerId, 
    required int blockedId, 
    required bool isCurrentlyBlocked
  }) async {
    // اختيار الرابط الصحيح بناءً على حالة الحظر الحالية
    final url = isCurrentlyBlocked ? ApiUrls.unblockUser : ApiUrls.blockUser;

    final response = await safePost(
      url,
      data: {
        'blocker_id': blockerId,
        'blocked_id': blockedId,
      },
    );

    return response != null && response.data['status'] == 'success';
  }

  /// جلب قائمة المستخدمين المحظورين مع الترقيم
  Future<List<UserModel>> fetchBlockedUsers({required int userId, int page = 1}) async {
    final response = await safeGet(
      ApiUrls.blockedList,
      queryParameters: {
        'user_id': userId,
        'page': page,
      },
    );

    if (response != null && response.data['status'] == 'success') {
      final List data = response.data['data'];
      return data.map((item) => UserModel.fromJson({
        'id': item['user_id'],
        'name': item['name'],
        'photo_url': item['photo_url'],
        'username': item['username'],
      })).toList();
    }
    return [];
  }

  /// جلب الـ IDs فقط (للفلترة السريعة في التطبيق)
  Future<List<int>> fetchBlockedIds(int userId) async {
    final response = await safeGet(
      ApiUrls.blockedList,
      queryParameters: {'user_id': userId},
    );

    if (response != null && response.data['status'] == 'success') {
      final List data = response.data['data'];
      return data.map((item) => int.parse(item['user_id'].toString())).toList();
    }
    return [];
  }
}
