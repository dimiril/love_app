import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_strings.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/video_upload_provider.dart';
import '../../routes/app_router.dart';
import '../../utils/snack_bar.dart';

class UploadVideoScreen extends StatefulWidget {
  const UploadVideoScreen({super.key});

  @override
  State<UploadVideoScreen> createState() => _UploadVideoScreenState();
}

class _UploadVideoScreenState extends State<UploadVideoScreen> {
  final TextEditingController _titleController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _showExitConfirmation(VideoUploadProvider provider) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          "هل تريد إلغاء النشر والرجوع؟",
          style: TextStyle(fontFamily: 'Kaff', fontSize: 13),
        ),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: "نعم، إلغاء",
          textColor: Colors.redAccent,
          onPressed: () {
            provider.clearSelection();
            if (mounted) Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final provider = context.watch<VideoUploadProvider>();
    final videoController = provider.videoController;
    final authProvider = context.read<AuthProvider>();
    final bool isBusy = provider.isUploading || provider.isProcessing;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showExitConfirmation(provider);
      },
      child: SafeArea(
        top: false,
        bottom: true,
        child: Scaffold(
          backgroundColor: Colors.black,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            systemOverlayStyle: const SystemUiOverlayStyle(
              systemNavigationBarColor: Colors.black,
              statusBarColor: Colors.transparent,
              systemNavigationBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
              statusBarIconBrightness: Brightness.light,
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
            shape: Border(bottom: BorderSide.none),
            leading: IconButton(
              onPressed: () => _showExitConfirmation(provider),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.4),
              ),
              icon: const Icon(AppIcons.close, color: Colors.white, size: 22),
            ),
          ),
          body: isBusy && provider.isProcessing
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 20),
                      Text(
                        "جاري تجهيز الفيديو...",
                        style: const TextStyle(color: Colors.white, fontFamily: 'Kaff', fontSize: 14),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    if (videoController != null && videoController.value.isInitialized)
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: provider.togglePlayPause,
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: videoController.value.size.width,
                              height: videoController.value.size.height,
                              child: VideoPlayer(videoController),
                            ),
                          ),
                        ),
                      ),

                    if (videoController != null && videoController.value.isInitialized && !videoController.value.isPlaying)
                      const Center(child: Icon(Icons.play_arrow_rounded, size: 80, color: Colors.white)),

                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 250,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: .9),
                              Colors.black.withValues(alpha: .6),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (videoController != null && videoController.value.isInitialized)
                              SizedBox(
                                height: 2,
                                width: double.infinity,
                                child: VideoProgressIndicator(
                                  videoController,
                                  allowScrubbing: true,
                                  padding: EdgeInsets.zero,
                                  colors: const VideoProgressColors(
                                    playedColor: Colors.red,
                                    bufferedColor: Colors.white24,
                                    backgroundColor: Colors.white10,
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                              child: TextField(
                                controller: _titleController,
                                style: const TextStyle(color: Colors.white, fontFamily: 'Kaff-black', fontSize: 14),
                                maxLines: 1,
                                decoration: const InputDecoration(
                                  hintText: "اكتب وصفاً للفيديو...",
                                  hintStyle: TextStyle(color: Colors.white70, fontSize: 13),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Checkbox(
                                      value: provider.agreedToTerms,
                                      onChanged: (value) => provider.setAgreedToTerms(value ?? true),
                                      activeColor: AppColors.primary,
                                      checkColor: Colors.black,
                                      side: const BorderSide(color: Colors.white, width: 1.5),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => _showTermsDialog(),
                                      child: Text(
                                        t?.tr(AppStrings.agreeToTerms) ?? "أوافق على شروط وأحكام التطبيق",
                                        style: const TextStyle(fontFamily: 'Kaff', fontSize: 11, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (!provider.isUploading)
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: () {
                                    final title = _titleController.text.trim();
                                    if (title.isEmpty) {
                                      AppSnackBar.show(context, t?.tr(AppStrings.requiredVideoField) ?? "يرجى كتابة وصف", isError: true);
                                      return;
                                    }
                                    if (!provider.agreedToTerms) {
                                      AppSnackBar.show(context, t?.tr(AppStrings.mustAgreeToTerms) ?? "يجب الموافقة على الشروط", isError: true);
                                      return;
                                    }

                                    final userId = authProvider.user?.id ?? 0;

                                    // 1. نبدأ الرفع في الخلفية بدون await
                                    provider.uploadVideo(userId: userId, title: title).then((success) {
                                      // 3. عند الانتهاء، نظهر الرسالة باستخدام الـ global context
                                      final currentContext = navigatorKey.currentContext;
                                      if (success && currentContext != null && currentContext.mounted) {
                                        AppSnackBar.show(currentContext, "تم الرفع بنجاح! سيظهر الفيديو بعد المراجعة.");
                                      }
                                    });

                                    // 2. نغلق الشاشة فوراً
                                    Navigator.pop(context);
                                  },
                                  style: TextButton.styleFrom(
                                    backgroundColor:
                                    Colors.black.withValues(alpha: 0.7),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.zero,
                                    ),

                                  ),
                                  child: const Text("نشر", style: TextStyle(fontFamily: 'Kaff-black', fontWeight: FontWeight.bold)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _showTermsDialog() {
    final t = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff333333),
        title: Text(t?.tr(AppStrings.termsOfService) ?? "شروط الخدمة", style: const TextStyle(color: Colors.white, fontSize: 14)),
        content: Text(t?.tr(AppStrings.termsContent) ?? "", style: const TextStyle(color: Colors.white70, fontSize: 12)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(t?.tr(AppStrings.ok) ?? "موافق"))],
      ),
    );
  }
}
