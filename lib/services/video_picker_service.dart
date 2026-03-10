import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../utils/snack_bar.dart';

class VideoPickerService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickVideoFromGallery(BuildContext context) async {
    final XFile? pickedFile =
    await _picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile == null) return null;

    File videoFile = File(pickedFile.path);

    final fileSize = await videoFile.length();
    if (fileSize > 10 * 1024 * 1024) {
      if (!context.mounted) return null;
      AppSnackBar.error(context, "الفيديو كبير بزاف (أقصى حجم 10MB)");
      return null;
    }

    VideoPlayerController? controller;
    try {
      controller = VideoPlayerController.file(videoFile);
      await controller.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception("Timeout"),
      );

      final duration = controller.value.duration.inSeconds;
      final size = controller.value.size;
      final height = size.height;

      if (duration > 120) {
        if (!context.mounted) return null;
        AppSnackBar.error(context, "يجب أن يكون الفيديو أقل من دقيقة");
        return null;
      }

      if (height > 2160) {
        if (!context.mounted) return null;
        AppSnackBar.error(context, "الجودة عالية جداً (الحد الأقصى 4K)");
        return null;
      }

      return videoFile;
    } catch (e) {
      debugPrint("خطأ في فحص الفيديو: $e");
      if (context.mounted) {
        AppSnackBar.error(context, "حدث خطأ في قراءة الفيديو");
      }
      return null;
    } finally {
      await controller?.dispose();
    }
  }
}