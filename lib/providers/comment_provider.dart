import 'package:flutter/material.dart';
import '../models/comment_model.dart';
import '../services/comment_service.dart';

class CommentProvider with ChangeNotifier {
  final CommentService _service = CommentService();

  final Map<int, List<CommentModel>> _commentsMap = {};
  final Map<int, bool> _loadingMap = {};

  List<CommentModel> getComments(int targetId) => _commentsMap[targetId] ?? [];
  bool isLoading(int targetId) => _loadingMap[targetId] ?? false;

  /// جلب التعليقات
  Future<void> loadComments({required int targetId, required String type}) async {
    if (_loadingMap[targetId] == true) return;

    _loadingMap[targetId] = true;
    notifyListeners();

    final results = await _service.fetchComments(targetId: targetId, type: type);
    _commentsMap[targetId] = results;
    
    _loadingMap[targetId] = false;
    notifyListeners();
  }

  /// إضافة تعليق جديد
  Future<bool> addComment({
    required int userId,
    required int targetId,
    required String type,
    required String comment,
  }) async {
    final newComment = await _service.addComment(
      userId: userId,
      targetId: targetId,
      type: type,
      comment: comment,
    );

    if (newComment != null) {
      if (_commentsMap.containsKey(targetId)) {
        _commentsMap[targetId]!.insert(0, newComment);
      } else {
        _commentsMap[targetId] = [newComment];
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  /// ✅ حذف تعليق
  Future<bool> deleteComment({
    required int commentId,
    required int userId,
    required int targetId,
  }) async {
    final success = await _service.deleteComment(commentId, userId);
    if (success) {
      if (_commentsMap.containsKey(targetId)) {
        _commentsMap[targetId]!.removeWhere((c) => c.id == commentId);
        notifyListeners();
      }
      return true;
    }
    return false;
  }

  void clear(int targetId) {
    _commentsMap.remove(targetId);
    _loadingMap.remove(targetId);
  }
}
