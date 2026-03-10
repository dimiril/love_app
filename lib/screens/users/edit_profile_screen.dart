import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../services/image_picker_service.dart';
import '../../utils/snack_bar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  
  File? _selectedProfileImage;
  final ImagePickerService _picker = ImagePickerService();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.name);
    _usernameController = TextEditingController(text: user?.username);
    _bioController = TextEditingController(text: user?.bio);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.updateProfile(
      name: _nameController.text.trim(),
      username: _usernameController.text.trim(),
      bio: _bioController.text.trim(),
      photo: _selectedProfileImage,
    );

    if (success && mounted) {
      AppSnackBar.show(context, "تم تحديث الملف الشخصي بنجاح");
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final user = context.watch<AuthProvider>().user;
    final isLoading = context.watch<AuthProvider>().isLoading;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 1,
        shadowColor: isDark ? Colors.black54 : Colors.black12,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: theme.appBarTheme.iconTheme?.color),
        ),
        title: Text(
          t?.tr(AppStrings.editProfile) ?? "تعديل الملف الشخصي", 
          style: theme.appBarTheme.titleTextStyle,
        ),
        centerTitle: true,
        actions: [
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16), 
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: Text(
                t?.tr(AppStrings.save) ?? "حفظ", 
                style: const TextStyle(fontFamily: 'Kaff', fontWeight: FontWeight.bold, color: AppColors.primary)
              ),
            )
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 32),
              
              // Profile Image Picker
              Center(
                child: GestureDetector(
                  onTap: () async {
                    final file = await _picker.pickImageFromGallery();
                    if (file != null) setState(() => _selectedProfileImage = file);
                  },
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05), 
                              blurRadius: 15, 
                              spreadRadius: 2
                            )
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 65,
                          backgroundColor: isDark ? Colors.white10 : Colors.grey[100],
                          backgroundImage: _selectedProfileImage != null
                              ? FileImage(_selectedProfileImage!)
                              : (user?.photoUrl != null && user!.photoUrl.isNotEmpty 
                                  ? NetworkImage(user.photoUrl) as ImageProvider
                                  : const AssetImage('assets/images/default_avatar.png')),
                        ),
                      ),
                      Positioned(
                        bottom: 5,
                        right: 5,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildTextField(
                      theme,
                      t?.tr(AppStrings.username) ?? "اسم المستخدم", 
                      _usernameController, 
                      prefix: "@"
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                      theme,
                      "الاسم الكامل", 
                      _nameController
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                      theme,
                      t?.tr(AppStrings.bio) ?? "نبذة عني", 
                      _bioController, 
                      maxLines: 4
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(ThemeData theme, String label, TextEditingController controller, {int maxLines = 1, String? prefix}) {
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 8),
          child: Text(
            label, 
            style: TextStyle(
              fontFamily: 'Kaff-black', 
              fontSize: 13, 
              color: AppColors.primary.withValues(alpha: 0.9)
            )
          ),
        ),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(
            fontFamily: 'Kaff', 
            fontSize: 15,
            color: theme.textTheme.bodyLarge?.color
          ),
          decoration: InputDecoration(
            prefixText: prefix,
            prefixStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            filled: true,
            fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15), 
              borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey[200]!)
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15), 
              borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey[200]!)
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15), 
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5)
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: (v) => v == null || v.isEmpty ? "هذا الحقل مطلوب" : null,
        ),
      ],
    );
  }
}
