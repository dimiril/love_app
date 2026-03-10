import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import '../services/video_picker_service.dart';
import '../services/video_service.dart';

class VideoUploadProvider extends ChangeNotifier {
  final VideoPickerService _pickerService = VideoPickerService();
  final VideoService _videoService = VideoService();

  File? _selectedVideo;
  File? get selectedVideo => _selectedVideo;

  File? _thumbnailFile;
  File? get thumbnailFile => _thumbnailFile;

  bool _isUploading = false;
  bool get isUploading => _isUploading;

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  bool _agreedToTerms = true;
  bool get agreedToTerms => _agreedToTerms;

  VideoPlayerController? _videoController;
  VideoPlayerController? get videoController => _videoController;

  Future<void> pickVideo(BuildContext context) async {
    final File? file = await _pickerService.pickVideoFromGallery(context);
    if (file != null) {
      _selectedVideo = file;
      _isProcessing = true;
      notifyListeners(); 
      _processVideo();
    }
  }

  Future<void> _processVideo() async {
    try {
      await _generateThumbnail();
      await _initializePreview();
    } catch (e) {
      debugPrint("Process Video Error: $e");
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> _generateThumbnail() async {
    if (_selectedVideo == null) return;
    final String? thumbnailPath = await VideoThumbnail.thumbnailFile(
      video: _selectedVideo!.path,
      thumbnailPath: (await getTemporaryDirectory()).path,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 250,
      maxHeight: 250,
      quality: 75,
    );
    if (thumbnailPath != null) {
      _thumbnailFile = File(thumbnailPath);
    }
  }

  Future<void> _initializePreview() async {
    if (_selectedVideo == null) return;
    await _videoController?.dispose();
    _videoController = VideoPlayerController.file(_selectedVideo!);
    await _videoController!.initialize();
    _videoController!.setLooping(true);
    _videoController!.pause();
  }

  void togglePlayPause() {
    if (_videoController == null) return;
    if (_videoController!.value.isPlaying) {
      _videoController!.pause();
    } else {
      _videoController!.play();
    }
    notifyListeners();
  }

  void setAgreedToTerms(bool value) {
    _agreedToTerms = value;
    notifyListeners();
  }

  /// ✅ تنظيف الذاكرة والقرص (Disk)
  void clearSelection() {
    // 1. حذف ملف الـ Thumbnail من القرص لتوفير المساحة
    if (_thumbnailFile != null && _thumbnailFile!.existsSync()) {
      try {
        _thumbnailFile!.deleteSync();
      } catch (e) {
        debugPrint("Error deleting thumb: $e");
      }
    }

    _selectedVideo = null;
    _thumbnailFile = null;
    _isProcessing = false;
    _agreedToTerms = true;
    _videoController?.dispose();
    _videoController = null;
    notifyListeners();
  }

  Future<bool> uploadVideo({required int userId, required String title}) async {
    if (_selectedVideo == null) return false;
    _isUploading = true;
    notifyListeners();
    try {
      final uploadedVideo = await _videoService.uploadVideo(
        userId: userId,
        title: title,
        videoFile: _selectedVideo!,
        thumbnailFile: _thumbnailFile,
      );
      if (uploadedVideo != null) {
        clearSelection(); // ستقوم بحذف الـ Thumbnail تلقائياً بعد نجاح الرفع
        return true;
      }
    } catch (e) {
      debugPrint("Upload Error: $e");
    } finally {
      _isUploading = false;
      notifyListeners();
    }
    return false;
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }
}
