import '../core/constants/api_urls.dart';
import 'base_service.dart';

class LikeService extends BaseService {
  Future<bool> toggleLike({
    required int userId,
    required int likeableId,
    required String likeableType,
  }) async {
    final response = await safePost(
      ApiUrls.likeToggle,
      data: {
        'user_id': userId,
        'likeable_id': likeableId,
        'likeable_type': likeableType,
      },
    );
    if (response == null) return false;
    return response.data['success'] == true;
  }
}
