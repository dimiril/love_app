import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class CacheUtils {
  /// مسح كاش الصور، الفيديوهات، والملفات المؤقتة (Sharing/Thumbnails)
  static Future<void> clearAppCache() async {
    try {
      await DefaultCacheManager().emptyCache();
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        final List<FileSystemEntity> files = tempDir.listSync(recursive: true);
        for (var file in files) {
          try {
            if (file is File) {
              file.deleteSync();
            } else if (file is Directory) {
              file.deleteSync(recursive: true);
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      print("Error clearing cache: $e");
    }
  }

  /// ✅ ميزة التنظيف التلقائي الذكي
  /// تُستدعى عند فتح التطبيق (في Splash أو Home)
  static Future<void> autoSmartClean({int limitMB = 50}) async {
    try {
      final tempDir = await getTemporaryDirectory();
      int totalSizeBytes = _getSize(tempDir);
      double currentSizeMB = totalSizeBytes / (1024 * 1024);

      if (currentSizeMB > limitMB) {
        print("🚀 Auto Cleaning Cache: Current size ($currentSizeMB MB) exceeds limit ($limitMB MB)");
        await clearAppCache();
      }
    } catch (_) {}
  }

  /// حساب حجم الكاش الحالي
  static Future<String> getCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      int totalSize = _getSize(tempDir);
      if (totalSize == 0) return "0 MB";
      return "${(totalSize / (1024 * 1024)).toStringAsFixed(2)} MB";
    } catch (e) {
      return "0 MB";
    }
  }

  static int _getSize(FileSystemEntity file) {
    if (file is File) return file.lengthSync();
    if (file is Directory && file.existsSync()) {
      int sum = 0;
      try {
        final List<FileSystemEntity> children = file.listSync();
        for (final FileSystemEntity child in children) {
          sum += _getSize(child);
        }
      } catch (_) {}
      return sum;
    }
    return 0;
  }
}
