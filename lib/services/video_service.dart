import 'dart:io';
import 'package:dio/dio.dart';
import '../core/constants/api_urls.dart';
import '../models/video_model.dart';
import 'base_service.dart';

class VideoService extends BaseService {

  Future<List<VideoModel>> fetchVideos({int page = 1, int perPage = 20, int? userId}) async {
    final response = await safeGet(
      ApiUrls.videos,
      queryParameters: {
        'page': page, 
        'per_page': perPage,
        if (userId != null) 'user_id': userId,
      },
    );
    if (response == null) return [];

    final data = response.data;
    if (data['status'] != 'success') return [];

    return (data['data'] as List).map((e) => VideoModel.fromJson(e)).toList();
  }

  /// ✅ جلب فيديوهات مستخدم محدد
  Future<List<VideoModel>> fetchUserVideos(int userId) async {
    final response = await safeGet(
      ApiUrls.userVideos,
      queryParameters: {'user_id': userId},
    );
    
    if (response == null) return [];

    final data = response.data;
    if (data['status'] != 'success' || data['data'] == null) return [];

    return (data['data'] as List).map((e) => VideoModel.fromJson(e)).toList();
  }

  Future<bool> incrementView(int videoId) async {
    final response = await safePost(
      '${ApiUrls.baseUrl}/videos/view-count',
      data: FormData.fromMap({'video_id': videoId}),
    );
    if (response == null) return false;
    return response.data['success'] == true;
  }

  Future uploadVideo({
    required int userId,
    required String title,
    required File videoFile,
    File? thumbnailFile,
  }) async {
    final Map<String, dynamic> data = {
      'user_id': userId,
      'title': title,
      'video': await MultipartFile.fromFile(
        videoFile.path,
        filename: videoFile.path.split('/').last,
      ),
    };

    if (thumbnailFile != null) {
      data['thumbnail'] = await MultipartFile.fromFile(
        thumbnailFile.path,
        filename: 'thumb_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
    }

    final formData = FormData.fromMap(data);

    final response = await safePost(
      ApiUrls.uploadVideo,
      data: formData,
    );

    if (response != null && response.data['status'] == 'success') {
      return response.data['status'];
    }
    return null;
  }
}
