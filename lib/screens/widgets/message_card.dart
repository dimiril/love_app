import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_strings.dart';
import '../../l10n/app_localizations.dart';
import '../../models/message_model.dart';
import '../../providers/database_provider.dart';
import '../../utils/snack_bar.dart';
import '../../routes/app_router.dart';
import 'favorite_button.dart';

class MessageCard extends StatelessWidget {
  final MessageModel msg;
  final ValueNotifier<double> textSizeNotifier;
  final ScrollController? scrollController;
  final int categoryId;
  final bool isFavoritePage;
  final String? searchQuery;
  final VoidCallback? onRemove;

  const MessageCard({
    super.key,
    required this.msg,
    required this.textSizeNotifier,
    this.scrollController,
    required this.categoryId,
    this.isFavoritePage = false,
    this.searchQuery,
    this.onRemove,
  });

  Future<void> _openWhatsApp(BuildContext context, String message) async {
    final t = AppLocalizations.of(context);
    final url = Uri.parse("https://wa.me/?text=${Uri.encodeComponent(message)}");
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) AppSnackBar.show(context, t?.tr(AppStrings.whatsappNotInstalled) ?? "واتساب غير مثبت على جهازك");
      }
    } catch (e) {
      if (context.mounted) AppSnackBar.show(context, t?.tr(AppStrings.errorOpeningWhatsapp) ?? "حدث خطأ أثناء محاولة فتح واتساب");
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // ✅ تحسين: سحب الـ bookmark مرة واحدة لكل فريم
    final bool isBookmarked = context.select<DatabaseProvider, bool>(
      (p) => p.getBookmark(categoryId) == msg.id
    );

    final bool showAsBookmark = isBookmarked && !isFavoritePage;
    final bool isNew = msg.createdAt != null && DateTime.now().difference(msg.createdAt!).inDays < 2;

    return RepaintBoundary( // ✅ منع إعادة رسم البطاقة بالكامل عند تمرير القائمة
      child: Card(
        elevation: showAsBookmark ? 4 : 2,
        shadowColor: Colors.black12,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.only(bottom: 12),
        color: showAsBookmark ? isDark ? const Color(0xff272201) : const Color(0xfffff9e6) : isDark ? AppColors.appBarDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: showAsBookmark ? isDark ? const Color(0xff3a3300) : Colors.amber.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.1)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isNew) _buildNewBadge(t),
              
              ValueListenableBuilder<double>(
                valueListenable: textSizeNotifier,
                builder: (context, fontSize, child) {
                  return Text(
                    msg.content,
                    style: TextStyle(
                      fontFamily: 'Kaff',
                      fontSize: fontSize,
                      height: 1.6,
                      color: isDark ? AppColors.bgLight : Colors.black87,
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 20),
              Divider(color: isDark ? AppColors.bgDark : Color(0xfff0f0f0), height: 1, thickness: 1),
              const SizedBox(height: 12),
              _buildActionsRow(context, isBookmarked, t),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewBadge(AppLocalizations? t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xfffd3057), borderRadius: BorderRadius.circular(6)),
      child: Text(t?.tr(AppStrings.newBadge) ?? "جديد", style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'Kaff')),
    );
  }

  Widget _buildActionsRow(BuildContext context, bool isBookmarked, AppLocalizations? t) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (!isFavoritePage)
          _actionButton(
            icon: isBookmarked ? AppIcons.bookmarkFill : AppIcons.bookmark,
            color: isBookmarked ? Colors.amber : AppColors.primary,
            onTap: () {
              final provider = context.read<DatabaseProvider>();
              if (isBookmarked) {
                provider.saveBookmark(categoryId, 0);
                provider.saveScrollPosition(categoryId, 0.0);
                AppSnackBar.show(context, t?.tr(AppStrings.bookmarkRemoved) ?? "تم إزالة العلامة المرجعية");
              } else {
                provider.saveBookmark(categoryId, msg.id);
                if (scrollController != null) provider.saveScrollPosition(categoryId, scrollController!.offset);
                AppSnackBar.show(context, t?.tr(AppStrings.bookmarkAdded) ?? "تم وضع علامة مرجعية هنا");

              }
            },
          ),
        FavoriteButton(msg: msg),
        _actionButton(icon: AppIcons.whatsapp, color: AppColors.primary, onTap: () => _openWhatsApp(context, msg.content)),
        _actionButton(icon: AppIcons.edit, color: AppColors.primary, onTap: () => Navigator.pushNamed(context, AppRouter.editMessage, arguments: msg.content)),
        _actionButton(icon: AppIcons.share, color: AppColors.primary, onTap: () => Share.share(msg.content)),
        _actionButton(
          icon: AppIcons.copy,
          color: AppColors.primary,
          onTap: () {
            Clipboard.setData(ClipboardData(text: msg.content));
            AppSnackBar.show(context, t?.tr(AppStrings.textCopied) ?? "تم نسخ النص بنجاح");
          },
        ),
      ],
    );
  }

  Widget _actionButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 22, color: color),
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(),
    );
  }
}
