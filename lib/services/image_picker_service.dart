import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  /// اختيار صورة من المعرض
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // تقليل الجودة قليلاً لتقليل حجم الملف عند الرفع
        maxWidth: 1000,   // حد أقصى للعرض
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      print("Error picking image: $e");
    }
    return null;
  }

  /// التقاط صورة بالكاميرا (اختياري)
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      print("Error capturing image: $e");
    }
    return null;
  }
}
