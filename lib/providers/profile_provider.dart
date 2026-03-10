import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/video_model.dart';
import '../services/auth_service.dart';
import '../services/video_service.dart';

class ProfileProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final VideoService _videoService = VideoService();

  final Map<int, UserModel> _profileCache = {};
  
  UserModel? _user;
  bool _isLoading = false;
  List<VideoModel> _userVideos = []; // ✅ جديد

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  List<VideoModel> get userVideos => _userVideos; // ✅ جديد

  Future<void> loadProfile(int? userId, UserModel? currentUser) async {
    _userVideos = []; // تصفير الفيديوهات عند كل تحميل جديد
    
    if (userId == null || userId == currentUser?.id) {
      _user = currentUser;
      _isLoading = false;
      if (_user != null) _loadVideos(_user!.id);
      notifyListeners();
      return;
    }

    if (_profileCache.containsKey(userId)) {
      _user = _profileCache[userId];
      _isLoading = false;
      _loadVideos(userId);
      notifyListeners();
      _fetchFromServer(userId, background: true);
      return;
    }

    await _fetchFromServer(userId);
  }

  Future<void> _fetchFromServer(int userId, {bool background = false}) async {
    if (!background) {
      _isLoading = true;
      _user = null;
      notifyListeners();
    }

    try {
      final fetchedUser = await _authService.getUserProfile(userId);
      if (fetchedUser != null) {
        _user = fetchedUser;
        _profileCache[userId] = fetchedUser;
        _loadVideos(userId);
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ✅ جلب فيديوهات المستخدم
  Future<void> _loadVideos(int userId) async {
    final videos = await _videoService.fetchUserVideos(userId);
    _userVideos = videos;
    notifyListeners();
  }

  void clearProfile() {
    _user = null;
    _userVideos = [];
    _profileCache.clear();
    _isLoading = false;
  }
}
