import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/constants.dart';
import '../../models/post_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/like_provider.dart';
import '../../providers/post_provider.dart';
import '../../utils/time_ago_formatter.dart';
import '../../utils/login_modal.dart';
import '../../routes/app_router.dart';
import '../../utils/number_formatter.dart';
import '../../utils/report_utils.dart';
import '../../utils/snack_bar.dart';
import 'app_circle_avatar.dart';
import 'full_screen_image.dart'; // ✅ استيراد صفحة الصورة الكاملة

class PostCard extends StatefulWidget {
  final PostModel post;
  final bool isAuthenticated;
  final String page;

  const PostCard({super.key, required this.post, required this.isAuthenticated, required this.page});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _isExpanded = false;

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(
      ClipboardData(text: widget.post.content),
    );

    if (!mounted) return;

    AppSnackBar.show(context, "تم نسخ النص بنجاح");
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return RepaintBoundary(
      child: Card(
        shadowColor: Colors.black26,
        surfaceTintColor: Colors.transparent,
        margin: widget.page == 'show' ? const EdgeInsets.symmetric(horizontal: 0, vertical: 0) : const EdgeInsets.only(bottom: 12, left: 8, right: 8),
        color: isDark ? AppColors.appBarDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: widget.page == 'show' ? BorderRadius.zero : BorderRadius.circular(8),
          side: widget.page == 'show' ? BorderSide.none : BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(theme: theme, isDark: isDark, post: widget.post, copyFn: () => _copyToClipboard()),
            if (widget.post.content.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      maxLines: _isExpanded ? null : 5,
                      overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                      text: TextSpan(
                        style: TextStyle(
                          fontFamily: 'Kaff',
                          fontSize: 14,
                          height: 1.7,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                        children: _buildTextSpans(widget.post.content, theme),
                      ),
                    ),
                    if (widget.post.content.length > 180 && !_isExpanded)
                      GestureDetector(
                        onTap: () => setState(() => _isExpanded = true),
                        child: const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            "عرض المزيد...",
                            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            
            // ✅ تفعيل تكبير الصورة عند الضغط عليها
            if (widget.post.image != null && widget.post.image!.isNotEmpty)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenImage(imageUrl: widget.post.image!),
                    ),
                  );
                },
                child: Padding(
                  padding: EdgeInsets.only(bottom: widget.post.content.trim().isNotEmpty ? 8 : 0),
                  child: CachedNetworkImage(
                    imageUrl: widget.post.image!,
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                    memCacheWidth: 800,
                    memCacheHeight: 300,
                    placeholder: (context, url) => Container(
                      height: 300,
                      color: isDark ? Colors.white10 : Colors.grey[100],
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (context, url, error) => const SizedBox.shrink(),
                  ),
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: _ActionsRow(post: widget.post, isAuthenticated: widget.isAuthenticated),
            ),
          ],
        ),
      ),
    );
  }

  List<TextSpan> _buildTextSpans(String text, ThemeData theme) {
    final RegExp hashtagRegExp = RegExp(r"(#[\w\u0600-\u06ff]+)");
    final matches = hashtagRegExp.allMatches(text);

    if (matches.isEmpty) {
      return [
        TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: 'Kaff',
            fontSize: 14,
            height: 1.7,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
      ];
    }

    List<TextSpan> spans = [];
    int start = 0;

    for (final match in matches) {
      if (match.start > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, match.start),
            style: TextStyle(
              fontFamily: 'Kaff',
              fontSize: 14,
              height: 1.7,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
        );
      }

      final hashtag = match.group(0)!;

      spans.add(
        TextSpan(
          text: hashtag,
          style: const TextStyle(
            fontFamily: 'Kaff',
            fontSize: 14,
            height: 1.7,
            color: Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      start = match.end;
    }

    if (start < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(start),
          style: TextStyle(
            fontFamily: 'Kaff',
            fontSize: 14,
            height: 1.7,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
      );
    }

    return spans;
  }
}

class _ActionsRow extends StatelessWidget {
  final PostModel post;
  final bool isAuthenticated;

  const _ActionsRow({
    required this.post,
    required this.isAuthenticated,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = context.watch<AuthProvider>().user?.id;

    final buttons = <Widget>[
      _LikeButton(post: post, isAuthenticated: isAuthenticated),
      _ActionButton(
        icon: AppIcons.posts,
        label: NumberFormatter.format(post.commentsCount),
        color: theme.textTheme.bodyMedium?.color,
        onTap: () {},
      ),
      _ActionButton(
        icon: AppIcons.copy,
        label: "",
        color: theme.textTheme.bodyMedium?.color,
        onTap: () {
          Clipboard.setData(ClipboardData(text: post.content));
          AppSnackBar.show(context, "تم نسخ النص بنجاح");
        },
      ),
      _ActionButton(
        icon: AppIcons.share,
        label: "",
        color: theme.textTheme.bodyMedium?.color,
        onTap: () {
          final appUrl = Constants.appUrlShare;
          final additionalText = "شوف هذا المنشور الرائع على تطبيقنا:";
          final textToShare = "$additionalText\n${post.content}\n$appUrl";
          Share.share(textToShare);
        },
      ),
    ];

    if (currentUserId == post.user.id) {
      buttons.insert(
        2,
        _ActionButton(
          icon: AppIcons.trash,
          label: "",
          color: Colors.redAccent,
          onTap: () async {
            final confirmed = await _showDeleteDialog(context);
            if (confirmed && context.mounted) {
              context.read<PostProvider>().deletePost(post.id, currentUserId!);
            }
          },
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: buttons,
    );
  }

  Future<bool> _showDeleteDialog(BuildContext context) async {
    return (await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          "حذف المنشور",
          style: TextStyle(fontFamily: 'Kaff-black', fontSize: 16),
        ),
        content: const Text(
          "هل أنت متأكد من رغبتك في حذف هذا المنشور نهائياً؟",
          style: TextStyle(fontFamily: 'Kaff', fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("إلغاء", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("حذف", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    )) ?? false;
  }
}

class _LikeButton extends StatelessWidget {
  final PostModel post;
  final bool isAuthenticated;
  const _LikeButton({required this.post, required this.isAuthenticated});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Selector<LikeProvider, bool>(
      selector: (_, p) => p.isPostLiked(post.id),
      builder: (context, isLiked, _) {
        return _ActionButton(
          icon: isLiked ? AppIcons.favoriteFill : AppIcons.favorite,
          label: NumberFormatter.format(post.likesCount),
          color: isLiked ? Colors.red : theme.textTheme.bodyMedium?.color,
          onTap: () {
            if (!isAuthenticated) {
              LoginModal.show(context);
              return;
            }
            context.read<LikeProvider>().togglePostLike(context.read<AuthProvider>().user!.id, post);
          },
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final ThemeData theme;
  final bool isDark;
  final PostModel post;
  final Future<void> Function() copyFn;

  const _Header({required this.theme, required this.isDark, required this.post, required this.copyFn});

  @override
  Widget build(BuildContext context) {
    final bool hasImage = post.image != null && post.image!.isNotEmpty;

    return InkWell(
      onTap: () => AppRouter.pushSmart(context, AppRouter.profile, post.user.id),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCircleAvatar(imageUrl: post.user.photoUrl, radius: 20),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: TextStyle(
                    fontFamily: 'Kaff-Black',
                    fontSize: 12,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                  children: [
                    TextSpan(text: post.user.name),
                    if (post.user.username != null && post.user.username!.isNotEmpty)
                      TextSpan(
                        text: " @${post.user.username}",
                        style: const TextStyle(
                          fontFamily: 'Kaff',
                          fontSize: 10,
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const TextSpan(
                      text: " \u2022 ",
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                    TextSpan(
                      text: TimeAgoFormatter.format(context, post.createdAt),
                      style: TextStyle(
                        fontFamily: 'Kaff',
                        fontSize: 9,
                        fontWeight: FontWeight.normal,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 26,
              height: 26,
              child: PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                icon: const Icon(AppIcons.dotsMenu, size: 18),
                onSelected: (value) {
                  switch (value) {
                    case 'copy':
                      copyFn();
                      break;
                    case 'save_image':
                      if (hasImage) AppSnackBar.show(context, "جاري تحضير الصورة للحفظ...");
                      break;
                    case 'favorite':
                      AppSnackBar.show(context, "تمت الإضافة للمفضلة");
                      break;
                    case 'report':
                      ReportUtils.showReportSheet(context, post.id.toString(), 'post');
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'copy', child: _PopupItem(icon: Icons.copy_rounded, text: "نسخ النص")),
                  if (hasImage) const PopupMenuItem(value: 'save_image', child: _PopupItem(icon: Icons.download_rounded, text: "حفظ الصورة")),
                  const PopupMenuItem(value: 'favorite', child: _PopupItem(icon: Icons.bookmark_border_rounded, text: "إضافة للمفضلة")),
                  const PopupMenuItem(value: 'report', child: _PopupItem(icon: Icons.report_problem_outlined, text: "إبلاغ عن المنشور", color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PopupItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  const _PopupItem({required this.icon, required this.text, this.color});
  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(fontFamily: 'Kaff', fontSize: 13, color: color));
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, required this.onTap, this.color});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xff7a7a7a)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontFamily: 'Kaff', fontSize: 12, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
