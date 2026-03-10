import 'package:flutter/foundation.dart';
import '../models/video_model.dart';
import '../models/post_model.dart';
import '../services/like_service.dart';
import '../utils/shared_pref.dart';

class LikeProvider with ChangeNotifier {
  final LikeService _service = LikeService();

  final Set<String> _likedVideoIds = {};
  final Set<String> _likedPostIds = {};

  LikeProvider() {
    _loadFromStorage();
  }

  void _loadFromStorage() {
    final videos = SharedPref.getStringList('liked_videos') ?? [];
    final posts = SharedPref.getStringList('liked_posts') ?? [];

    _likedVideoIds.addAll(videos);
    _likedPostIds.addAll(posts);
    notifyListeners();
  }

  Future<void> _saveToStorage() async {
    await SharedPref.setStringList('liked_videos', _likedVideoIds.toList());
    await SharedPref.setStringList('liked_posts', _likedPostIds.toList());
  }

  bool isVideoLiked(String id) => _likedVideoIds.contains(id);
  bool isPostLiked(int id) => _likedPostIds.contains(id.toString());

  Future<void> toggleVideoLike(int userId, VideoModel video) async {
    final String id = video.id;
    final bool wasLiked = _likedVideoIds.contains(id);

    _handleOptimisticUpdate(video, id, wasLiked, _likedVideoIds);

    try {
      final success = await _service.toggleLike(
        userId: userId,
        likeableId: int.parse(id),
        likeableType: 'video',
      );
      if (!success) _rollback(video, id, wasLiked, _likedVideoIds);
    } catch (_) {
      _rollback(video, id, wasLiked, _likedVideoIds);
    }
  }

  Future<void> togglePostLike(int userId, PostModel post) async {
    final String id = post.id.toString();
    final bool wasLiked = _likedPostIds.contains(id);

    _handleOptimisticUpdate(post, id, wasLiked, _likedPostIds);

    try {
      final success = await _service.toggleLike(
        userId: userId,
        likeableId: post.id,
        likeableType: 'post',
      );
      if (!success) _rollback(post, id, wasLiked, _likedPostIds);
    } catch (_) {
      _rollback(post, id, wasLiked, _likedPostIds);
    }
  }

  void _handleOptimisticUpdate(dynamic item, String id, bool wasLiked, Set<String> set) {
    if (wasLiked) {
      set.remove(id);
      item.likesCount = (item.likesCount - 1).clamp(0, 999999);
    } else {
      set.add(id);
      item.likesCount += 1;
    }
    notifyListeners();
    _saveToStorage();
  }

  void _rollback(dynamic item, String id, bool wasLiked, Set<String> set) {
    if (wasLiked) {
      set.add(id);
      item.likesCount += 1;
    } else {
      set.remove(id);
      item.likesCount = (item.likesCount - 1).clamp(0, 999999);
    }
    _saveToStorage();
    notifyListeners();
  }

  void clear() {
    _likedVideoIds.clear();
    _likedPostIds.clear();
    SharedPref.remove('liked_videos');
    SharedPref.remove('liked_posts');
    notifyListeners();
  }
}
