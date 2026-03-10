import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../core/constants/constants.dart';
import '../models/video_model.dart';

class VideoPlayerProvider with ChangeNotifier {
  List<VideoModel> _videos = [];
  final Map<int, VideoPlayerController> _controllers = {};
  int _currentIndex = 0;
  bool _isAllowedToPlay = true;

  VideoPlayerController? get currentController => _controllers[_currentIndex];
  Map<int, VideoPlayerController> get controllers => _controllers;
  int get currentIndex => _currentIndex;

  bool _isSharing = false;
  bool get isSharing => _isSharing;

  void initPlayer(List<VideoModel> videos, int initialIndex) {
    _videos = videos;
    _currentIndex = initialIndex;
    _isAllowedToPlay = true;

    _initializeVideo(_currentIndex, shouldNotify: false);
    _initializeVideo(_currentIndex + 1, shouldNotify: false);
    _initializeVideo(_currentIndex - 1, shouldNotify: false);

    notifyListeners();
  }

  void _initializeVideo(int index, {bool shouldNotify = true}) {
    if (index < 0 || index >= _videos.length || _controllers.containsKey(index)) return;

    final controller = VideoPlayerController.networkUrl(Uri.parse(_videos[index].videoUrl));
    _controllers[index] = controller;

    controller.setLooping(true);
    controller.initialize().then((_) {
      // ✅ تحسين: إذا وصل المستخدم لهذا الفيديو أثناء تحميله، شغله فوراً
      if (_currentIndex == index && _isAllowedToPlay) {
        controller.play();
        WakelockPlus.enable();
      }
      if (shouldNotify) notifyListeners();
    }).catchError((error) {
      debugPrint("Video Init Error at index $index: $error");
      _controllers.remove(index);
    });
  }

  void onPageChanged(int index) {
    if (_currentIndex == index) return;
    
    _controllers[_currentIndex]?.pause();
    _currentIndex = index;

    if (_controllers.containsKey(_currentIndex)) {
      final controller = _controllers[_currentIndex]!;
      if (_isAllowedToPlay) {
        if (controller.value.isInitialized) {
          controller.play();
          WakelockPlus.enable();
        } else {
          // إذا لم يكتمل التحميل بعد، دالة initialize المبرمجة أعلاه ستتكفل بالتشغيل
        }
      }
    } else {
      _initializeVideo(_currentIndex);
    }

    // تجهيز الفيديوهات المجاورة
    _initializeVideo(_currentIndex + 1, shouldNotify: false);
    _initializeVideo(_currentIndex - 1, shouldNotify: false);

    // تنظيف الذاكرة
    final keys = _controllers.keys.toList();
    for (final key in keys) {
      if ((key - _currentIndex).abs() > 1) {
        _controllers[key]?.dispose();
        _controllers.remove(key);
      }
    }
    notifyListeners();
  }

  void togglePlayPause() {
    if (currentController == null) return;
    if (currentController!.value.isPlaying) {
      currentController!.pause();
      WakelockPlus.disable();
    } else {
      currentController!.play();
      WakelockPlus.enable();
    }
    notifyListeners();
  }

  void pauseAll() {
    _isAllowedToPlay = false;
    for (var controller in _controllers.values) {
      controller.pause();
    }
    WakelockPlus.disable();
    notifyListeners();
  }

  void resumePlayback() {
    _isAllowedToPlay = true;
    currentController?.play();
    WakelockPlus.enable();
    notifyListeners();
  }

  void playCurrent() {
    if (currentController != null && !currentController!.value.isPlaying) {
      _isAllowedToPlay = true;
      currentController!.play();
      WakelockPlus.enable();
      notifyListeners();
    }
  }

  Future<void> shareVideo(VideoModel video) async {
    if (_isSharing) return;

    _isSharing = true;
    notifyListeners();

    File? tempFile;

    try {
      final directory = await getTemporaryDirectory();
      final filePath = "${directory.path}/share_video.mp4";

      await Dio().download(video.videoUrl, filePath);

      tempFile = File(filePath);

      if (await tempFile.exists()) {
        const appUrl = Constants.appUrlShare;

        await Share.shareXFiles(
          [XFile(filePath)],
          text: "${video.title} 🎬\n\nشاهد المزيد في تطبيقنا 👇\n$appUrl",
        );
      }
    } catch (e) {
      debugPrint("Share Error: $e");
    } finally {
      _isSharing = false;

      if (tempFile != null && await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }

      notifyListeners();
    }
  }

  void disposeControllers() {
    _isAllowedToPlay = false;
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    WakelockPlus.disable();
  }
}
