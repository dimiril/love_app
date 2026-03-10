import 'package:flutter/foundation.dart';
import '../models/video_model.dart';
import '../services/video_service.dart';
import '../utils/db_helper.dart';

class VideoProvider with ChangeNotifier {
  final VideoService _service = VideoService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final Set<int> _seenVideoIds = {};

  List<VideoModel> _videos = [];

  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;

  List<VideoModel> get videos => _videos;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;

  Future<void> loadInitial({int? currentUserId}) async {
    // 1. عرض الكاش أولاً إذا كانت القائمة فارغة
    if (_videos.isEmpty) {
      final cached = await _dbHelper.getCachedVideos();
      if (cached.isNotEmpty) {
        _videos = cached;
        notifyListeners();
      }
    }

    // 2. تصفير العداد والبدء من الصفحة 1 من السيرفر
    _currentPage = 1;
    _hasMore = true;
    await _loadPage(refresh: true, userId: currentUserId);
  }

  Future<void> loadNextPage({int? currentUserId}) async {
    if (_isLoading || !_hasMore) return;
    // تم حذف زيادة العداد من هنا لأنها تتم داخل _loadPage بعد نجاح الطلب
    await _loadPage(refresh: false, userId: currentUserId);
  }

  Future<void> _loadPage({bool refresh = false, int? userId}) async {
    if (_isLoading) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      final newVideos = await _service.fetchVideos(
        page: _currentPage, 
        userId: userId
      );

      if (refresh) {
        // ✅ إذا نجح التحميل من السيرفر، نستبدل الكاش بالبيانات الحقيقية
        if (newVideos.isNotEmpty) {
          _videos = newVideos;
          await _dbHelper.cacheVideos(newVideos);
          _currentPage = 2; // ننتقل للصفحة التالية مباشرة
        }
      } else {
        // ✅ في حالة التمرير لأسفل (Pagination)
        if (newVideos.isEmpty) {
          _hasMore = false;
        } else {
          // التحقق من عدم تكرار الفيديوهات باستخدام الـ ID
          final existingIds = _videos.map((v) => v.id).toSet();
          final uniqueNewVideos = newVideos.where((v) => !existingIds.contains(v.id)).toList();
          
          if (uniqueNewVideos.isEmpty) {
             _hasMore = false; // إذا كانت كل الفيديوهات الجديدة مكررة، نتوقف
          } else {
            _videos.addAll(uniqueNewVideos);
            _currentPage++;
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading videos: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void resetSeenVideos() {
    _seenVideoIds.clear();
  }

  Future<void> incrementView(VideoModel video) async {
    final int? videoId = int.tryParse(video.id);
    if (videoId == null) return;

    if (_seenVideoIds.contains(videoId)) return;
    _seenVideoIds.add(videoId);

    final success = await _service.incrementView(videoId);
    if (success) {
      video.viewsCount += 1;
      notifyListeners();
    } else {
      _seenVideoIds.remove(videoId);
    }
  }

}
