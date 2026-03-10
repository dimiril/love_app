import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../services/image_picker_service.dart';
import '../../utils/snack_bar.dart';
import '../widgets/app_circle_avatar.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final TextEditingController _contentController = TextEditingController();
  File? _selectedImage;
  bool _isPublishing = false;
  final ImagePickerService _picker = ImagePickerService();

  Future<void> _pickImage() async {
    final file = await _picker.pickImageFromGallery();
    if (file != null) {
      setState(() => _selectedImage = file);
    }
  }

  void _removeImage() {
    setState(() => _selectedImage = null);
  }

  Future<void> _handlePublish() async {
    final content = _contentController.text.trim();
    if (content.isEmpty && _selectedImage == null) {
      AppSnackBar.show(context, "يرجى كتابة نص أو اختيار صورة للنشر", isError: true);
      return;
    }

    setState(() => _isPublishing = true);

    final auth = context.read<AuthProvider>();
    final success = await context.read<PostProvider>().createPost(
      userId: auth.user!.id,
      content: content,
      image: _selectedImage,
    );

    if (mounted) {
      setState(() => _isPublishing = false);
      if (success) {
        AppSnackBar.show(context, "تم نشر منشورك بنجاح");
        Navigator.pop(context);
      } else {
        AppSnackBar.show(context, "فشل نشر المنشور، حاول مجدداً", isError: true);
      }
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = context.read<AuthProvider>().user;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 1,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.close, color: theme.appBarTheme.iconTheme?.color),
        ),
        title: Text("منشور جديد", style: theme.appBarTheme.titleTextStyle),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ElevatedButton(
              onPressed: _isPublishing ? null : _handlePublish,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              child: _isPublishing 
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text("نشر", style: TextStyle(fontFamily: 'Kaff', fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCircleAvatar(imageUrl: user?.photoUrl ?? "", radius: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _contentController,
                    maxLines: null,
                    minLines: 5,
                    autofocus: true,
                    style: TextStyle(fontSize: 16, fontFamily: 'Kaff', color: theme.textTheme.bodyLarge?.color),
                    decoration: const InputDecoration(
                      hintText: "بماذا تشعر اليوم؟",
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
            
            if (_selectedImage != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.file(
                        _selectedImage!,
                        width: double.infinity,
                        height: 300,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: _removeImage,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: theme.dividerColor.withOpacity(0.1))),
          color: theme.appBarTheme.backgroundColor,
        ),
        child: ListTile(
          onTap: _pickImage,
          leading: const Icon(Icons.image_outlined, color: AppColors.primary),
          title: Text("إضافة صورة للمنشور", style: TextStyle(fontFamily: 'Kaff', fontSize: 14, color: theme.textTheme.bodyLarge?.color)),
          trailing: const Icon(Icons.add_a_photo_outlined, color: Colors.grey, size: 20),
        ),
      ),
    );
  }
}
