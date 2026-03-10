import 'dart:io';
import 'package:dio/dio.dart';
import '../core/constants/api_urls.dart';
import '../models/post_model.dart';
import 'base_service.dart';

class PostService extends BaseService {
  /// جلب كافة المنشورات العامة
  Future<List<PostModel>> fetchPosts({int page = 1, int? viewerId}) async {
    final response = await safeGet(
      ApiUrls.posts,
      queryParameters: {
        'page': page,
        if (viewerId != null) 'viewer_id': viewerId,
      },
    );

    if (response != null && response.data['status'] == 'success') {
      final List data = response.data['data'];
      return data.map((json) => PostModel.fromJson(json)).toList();
    }
    return [];
  }

  /// إضافة منشور جديد (نص + صورة اختيارية)
  Future<PostModel?> createPost({
    required int userId,
    required String content,
    File? image,
  }) async {
    final Map<String, dynamic> data = {
      'user_id': userId,
      'content': content,
    };

    if (image != null) {
      data['image'] = await MultipartFile.fromFile(
        image.path,
        filename: 'post_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
    }

    final response = await safePost(
      ApiUrls.createPost,
      data: FormData.fromMap(data),
    );

    if (response != null &&
        response.data['status'] == 'success') {
      print("Response Data: ${response.data}");
      return PostModel.fromJson(response.data['data']);
    }

    return null;
  }

  /// جلب منشورات مستخدم محدد
  Future<List<PostModel>> fetchUserPosts(int userId, {int page = 1}) async {
    final response = await safeGet(
      "${ApiUrls.userPosts}?user_id=$userId&page=$page",
    );

    if (response != null && response.data['status'] == 'success') {
      final List data = response.data['data'];
      return data.map((json) => PostModel.fromJson(json)).toList();
    }
    return [];
  }

  /// حذف منشور
  Future<bool> deletePost(int postId, int userId) async {
    final response = await safePost(
      "${ApiUrls.posts}/delete",
      data: {'post_id': postId, 'user_id': userId},
    );
    return response != null && response.data['status'] == 'success';
  }
}
