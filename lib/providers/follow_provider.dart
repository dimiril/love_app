import 'package:flutter/material.dart';
import '../services/follow_service.dart';
import '../utils/shared_pref.dart';

class FollowProvider with ChangeNotifier {
  final FollowService _service = FollowService();
  final Set<String> _followingIds = {};

  FollowProvider() {
    _loadFromStorage();
  }

  /// ✅ فحص سريع جداً: O(1) complexity
  bool isFollowing(dynamic userId) {
    if (userId == null) return false;
    final String idStr = userId.toString().trim();
    return _followingIds.contains(idStr);
  }

  /// ✅ تحسين الأداء: إضافة مجموعة IDs وحفظها مرة واحدة وتنبيه الواجهة
  void addFollowingIdsBulk(List<dynamic> userIds) {
    bool changed = false;
    for (var userId in userIds) {
      if (userId == null) continue;
      final String idStr = userId.toString().trim();
      if (!_followingIds.contains(idStr)) {
        _followingIds.add(idStr);
        changed = true;
      }
    }

    if (changed) {
      _saveToStorage();
      notifyListeners(); // إشعار الـ Selectors لتحديث الأزرار
    }
  }

  /// ✅ إضافة ID واحد يدوياً وتنبيه الواجهة فوراً
  void addFollowingIdLocal(dynamic userId) {
    if (userId == null) return;
    final String idStr = userId.toString().trim();
    if (!_followingIds.contains(idStr)) {
      _followingIds.add(idStr);
      _saveToStorage();
      notifyListeners(); // ✅ ضروري لكي يتحدث الزر فوراً
    }
  }

  void _loadFromStorage() {
    final savedList = SharedPref.getStringList('following_ids') ?? [];
    if (savedList.isEmpty) return;
    
    _followingIds.clear();
    _followingIds.addAll(savedList.map((e) => e.trim()));
    // لا نحتاج notify هنا لأن التحميل يتم في الـ constructor قبل بناء أي Widget
  }

  Future<void> _saveToStorage() async {
    await SharedPref.setStringList('following_ids', _followingIds.toList());
  }

  Future<bool> toggleFollow({required int myUserId, required dynamic targetUserId}) async {
    if (myUserId == 0 || targetUserId == null) return false;
    final String targetIdStr = targetUserId.toString().trim();
    final bool currentlyFollowing = _followingIds.contains(targetIdStr);
    
    // التحديث التفاؤلي (Optimistic Update) لسرعة الاستجابة
    if (currentlyFollowing) {
      _followingIds.remove(targetIdStr);
    } else {
      _followingIds.add(targetIdStr);
    }
    
    notifyListeners();
    _saveToStorage();

    final result = await _service.toggleFollow(
      userId: myUserId,
      followingId: int.parse(targetIdStr),
    );

    if (result == null) {
      // التراجع في حالة الفشل (Rollback)
      if (currentlyFollowing) {
        _followingIds.add(targetIdStr);
      } else {
        _followingIds.remove(targetIdStr);
      }
      notifyListeners();
      _saveToStorage();
      return false;
    }
    return true;
  }

  void clear() {
    _followingIds.clear();
    SharedPref.remove('following_ids');
    notifyListeners();
  }
}
