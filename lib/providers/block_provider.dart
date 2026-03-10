import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/block_service.dart';

class BlockProvider with ChangeNotifier {
  final BlockService _service = BlockService();
  
  // 1. القوائم
  final Set<int> _blockedUserIds = {}; // للفلترة السريعة
  List<UserModel> _blockedUsers = [];  // للعرض في الشاشة
  
  // 2. حالة التحميل والـ Pagination
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;

  // Getters
  bool isBlocked(int userId) => _blockedUserIds.contains(userId);
  Set<int> get blockedIdsSet => _blockedUserIds; // متاح للـ VideoProvider للفلترة
  List<UserModel> get blockedUsers => _blockedUsers;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;

  /// حظر أو إلغاء حظر
  Future<bool> toggleBlock({required int myUserId, required int targetUserId}) async {
    if (myUserId == 0 || myUserId == targetUserId) return false;

    // تحديد الحالة الحالية قبل الإرسال
    final bool currentlyBlocked = _blockedUserIds.contains(targetUserId);

    final success = await _service.toggleBlock(
      blockerId: myUserId, 
      blockedId: targetUserId,
      isCurrentlyBlocked: currentlyBlocked,
    );

    if (success) {
      if (currentlyBlocked) {
        // إذا كان محظوراً، نقوم بإلغاء الحظر محلياً
        _blockedUserIds.remove(targetUserId);
        _blockedUsers.removeWhere((u) => u.id == targetUserId);
      } else {
        // إذا لم يكن محظوراً، نقوم بالحظر محلياً
        _blockedUserIds.add(targetUserId);
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  /// تحميل قائمة المحظورين (للعرض في شاشة الإعدادات)
  Future<void> loadBlockedUsers(int userId, {bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _blockedUsers = [];
      _hasMore = true;
    }

    if (!_hasMore || _isLoading) return;

    _isLoading = true;
    notifyListeners();

    final newUsers = await _service.fetchBlockedUsers(userId: userId, page: _currentPage);

    if (newUsers.isEmpty) {
      _hasMore = false;
    } else {
      _blockedUsers.addAll(newUsers);
      _currentPage++;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// تحميل الـ IDs فقط عند تشغيل التطبيق (للفلترة في الخلفية)
  Future<void> loadInitialBlockedIds(int userId) async {
    final ids = await _service.fetchBlockedIds(userId);
    _blockedUserIds.clear();
    _blockedUserIds.addAll(ids);
    notifyListeners();
  }

  void clear() {
    _blockedUserIds.clear();
    _blockedUsers.clear();
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();
  }
}
