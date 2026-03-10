import 'package:flutter/foundation.dart';
import '../core/constants/api_urls.dart';
import 'base_service.dart';

class FollowService extends BaseService {
  Future<String?> toggleFollow({
    required int userId,
    required int followingId,
  }) async {
    try {
      final response = await safePost(
        ApiUrls.followUser,
        data: {
          'user_id': userId,
          'following_id': followingId,
        },
      );

      if (response == null) return null;
      final data = response.data;
      if (data is Map && data['status'] == 'success') {
        return data['action'];
      }
      return null;
    } catch (e) {
      debugPrint("Toggle Follow Error: $e");
      return null;
    }
  }
}
