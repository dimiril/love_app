import '../core/constants/api_urls.dart';
import '../models/comment_model.dart';
import 'base_service.dart';

class CommentService extends BaseService {
  /// ✅ جلب التعليقات (GET)
  Future<List<CommentModel>> fetchComments({required int targetId, required String type, int page = 1}) async {
    final response = await safeGet(
      ApiUrls.comments,
      queryParameters: {
        'id': targetId,
        'type': type,
        'page': page,
      },
    );

    if (response != null && response.data['status'] == 'success') {
      final List? data = response.data['comments']; 
      if (data == null) return [];
      return data.map((json) => CommentModel.fromJson(json)).toList();
    }
    return [];
  }

  Future<CommentModel?> addComment({
    required int userId,
    required int targetId,
    required String type,
    required String comment,
    int? parentId,
  }) async {
    final response = await safePost(
      ApiUrls.comments,
      data: {
        'user_id': userId,
        'commentable_id': targetId,   // 👈 تم التغيير ليتطابق مع PHP
        'commentable_type': type,     // 👈 تم التغيير ليتطابق مع PHP
        'comment': comment,
        if (parentId != null) 'parent_id': parentId,
      },
    );

    if (response != null && response.data['status'] == 'success') {
      // السيرفر يرجع التعليق في مفتاح 'comment'
      return CommentModel.fromJson(response.data['comment']);
    }
    return null;
  }

  Future<bool> deleteComment(int commentId, int userId) async {
    try {
      final response = await safePost(
        "${ApiUrls.comments}/delete",
        data: {
          'comment_id': commentId,
          'user_id': userId
        },
      );

      // في CI4 respondDeleted قد يعيد 200 مع status success
      return response != null &&
          (response.data['status'] == 'success' || response.statusCode == 200);
    } catch (e) {
      return false;
    }
  }
}
