import 'dart:io';
import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../services/like_service.dart';

class PostProvider with ChangeNotifier {
  final PostService _service = PostService();
  final LikeService _likeService = LikeService();

  final Map<int, PostModel> _postsMap = {};
  final List<int> _postIds = [];

  List<int> get postIds => _postIds;

  PostModel getPostById(int id) => _postsMap[id]!;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isFetchingMore = false;
  bool get isFetchingMore => _isFetchingMore;

  int _currentPage = 1;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  void _setLoading(bool v) {
    if (_isLoading == v) return;
    _isLoading = v;
    notifyListeners();
  }

  /// ✅ تحسين: جلب المنشورات مع ضمان إخطار الواجهة بالتغييرات
  Future<void> loadPosts({bool refresh = false, int? userId}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _postIds.clear();
      _postsMap.clear();
    }

    if (!_hasMore || _isLoading || _isFetchingMore) return;

    if (refresh) {
      _setLoading(true);
    } else {
      _isFetchingMore = true;
      notifyListeners(); // ✅ ضروري لإظهار مؤشر التحميل في الأسفل
    }

    try {
      final results = await _service.fetchPosts(page: _currentPage, viewerId: userId);

      for (final post in results) {
        _postsMap[post.id] = post;
        if (!_postIds.contains(post.id)) _postIds.add(post.id);
      }

      if (results.isEmpty || results.length < 15) {
        _hasMore = false;
      } else {
        _currentPage++;
      }
      
      // ✅ إخطار الواجهة بعد نجاح عملية الجلب وإضافة البيانات
      notifyListeners(); 

    } catch (e) {
      debugPrint("Error loading posts: $e");
    } finally {
      _isLoading = false;
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  Future<void> toggleLike(int postId, int userId) async {
    if (!_postsMap.containsKey(postId)) return;

    final post = _postsMap[postId]!;
    final currentlyLiked = post.isLiked;

    _postsMap[postId] = post.copyWith(
      isLiked: !currentlyLiked,
      likesCount: currentlyLiked ? post.likesCount - 1 : post.likesCount + 1,
    );
    notifyListeners();

    final success = await _likeService.toggleLike(
      userId: userId,
      likeableId: postId,
      likeableType: 'post',
    );

    if (!success) {
      _postsMap[postId] = post;
      notifyListeners();
    }
  }

  Future<bool> createPost({required int userId, required String content, File? image}) async {
    _setLoading(true);
    final newPost = await _service.createPost(userId: userId, content: content, image: image);
    _setLoading(false);

    if (newPost == null) return false;

    _postsMap[newPost.id] = newPost;
    _postIds.insert(0, newPost.id);
    notifyListeners();
    return true;
  }

  /// 🔹 Delete post (Optimistic UI)
  Future<bool> deletePost(int postId, int userId) async {
    if (!_postsMap.containsKey(postId)) return false;

    // 🔥 Optimistic removal
    final removedPost = _postsMap.remove(postId);
    _postIds.remove(postId);
    notifyListeners();

    try {
      final success = await _service.deletePost(postId, userId);
      if (!success && removedPost != null) {
        // rollback if delete failed
        _postsMap[postId] = removedPost;
        _postIds.insert(0, postId);
        notifyListeners();
        return false;
      }
      return true;
    } catch (e) {
      debugPrint("Error deleting post: $e");
      if (removedPost != null) {
        _postsMap[postId] = removedPost;
        _postIds.insert(0, postId);
        notifyListeners();
      }
      return false;
    }
  }

  void clear() {
    _postsMap.clear();
    _postIds.clear();
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();
  }
}
