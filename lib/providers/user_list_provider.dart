import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../core/constants/api_urls.dart';

class UserListProvider with ChangeNotifier {
  final UserService _service = UserService();

  List<UserModel> _users = [];
  List<UserModel> get users => _users;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int _currentPage = 1;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  Future<void> loadFollowers(int userId, {bool refresh = false}) async {
    await _fetchList(ApiUrls.followersList, userId, refresh);
  }

  Future<void> loadFollowing(int userId, {bool refresh = false}) async {
    await _fetchList(ApiUrls.followingList, userId, refresh);
  }

  Future<void> _fetchList(String url, int userId, bool refresh) async {
    if (refresh) {
      _currentPage = 1;
      _users = [];
      _hasMore = true;
      notifyListeners();
    }

    if (!_hasMore || _isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      final List<UserModel> newUsers = await _service.fetchUserList(
        url: url,
        userId: userId,
        page: _currentPage,
      );

      if (newUsers.isEmpty) {
        _hasMore = false;
      } else {
        // ✅ التأكد من إضافة العناصر الجديدة للقائمة الحالية
        _users = [..._users, ...newUsers];
        _currentPage++;
        
        // إذا كان العدد القادم أقل من 10 (مثلاً)، فهذا يعني غالباً انتهاء الصفحات
        if (newUsers.length < 10) {
          _hasMore = false;
        }
      }
    } catch (e) {
      debugPrint("Error fetching users: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearList() {
    _users = [];
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();
  }
}
