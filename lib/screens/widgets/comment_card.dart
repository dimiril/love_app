import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_icons.dart';
import '../../models/comment_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/comment_provider.dart';
import '../../utils/report_utils.dart';
import '../../utils/snack_bar.dart';
import '../../utils/time_ago_formatter.dart';
import 'app_circle_avatar.dart';

class CommentCard extends StatefulWidget {
  final CommentModel comments;
  final bool isAuthenticated;

  const CommentCard({super.key, required this.comments, required this.isAuthenticated});

  @override
  State<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      shadowColor: Colors.black38,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            theme: theme,
            isDark: isDark,
            comment: widget.comments,
            isAuthenticated: widget.isAuthenticated,
          ),
          if (widget.comments.comment.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    maxLines: _isExpanded ? null : 6,
                    overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    text: TextSpan(
                      // ✅ إضافة style هنا هي المفتاح لعمل الـ RichText
                      style: TextStyle(
                        fontFamily: 'Kaff',
                        fontSize: 12,
                        height: 1.5,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                      children: _buildTextSpans(widget.comments.comment, theme),
                    ),
                  ),
                  if (widget.comments.comment.length > 200 && !_isExpanded)
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
          SizedBox(height: 16,)
        ],
      )
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
            fontSize: 12,
            height: 1.5,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
      ];
    }

    List<TextSpan> spans = [];
    int start = 0;

    for (final match in matches) {
      // النص العادي قبل الهاشتاغ
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

      // الهاشتاغ
      final hashtag = match.group(0)!;

      spans.add(
        TextSpan(
          text: hashtag,
          style: const TextStyle(
            fontFamily: 'Kaff',
            fontSize: 14,
            height: 1.7,
            color: Colors.blue, // لون الهاشتاغ
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      start = match.end;
    }

    // النص المتبقي بعد آخر هاشتاغ
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

class _Header extends StatelessWidget {
  final ThemeData theme;
  final bool isDark;
  final CommentModel comment;
  final bool isAuthenticated;

  const _Header({
    required this.theme,
    required this.isDark,
    required this.comment,
    required this.isAuthenticated,
  });

  Future<bool> _showDeleteDialog(BuildContext context) async {
    return (await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("حذف التعليق", style: TextStyle(fontFamily: 'Kaff-black', fontSize: 16)),
        content: const Text("هل تريد حذف هذا التعليق نهائياً؟", style: TextStyle(fontFamily: 'Kaff', fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("إلغاء", style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("حذف", style: TextStyle(color: Colors.red))),
        ],
      ),
    )) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final authUser = context.watch<AuthProvider>().user;
    final isMine = isAuthenticated && authUser?.id == comment.user.id;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCircleAvatar(imageUrl: comment.user.photoUrl, radius: 20),
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
                  TextSpan(text: comment.user.name),
                  if (comment.user.username != null && comment.user.username!.isNotEmpty)
                    TextSpan(
                      text: " @${comment.user.username}",
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
                    text: TimeAgoFormatter.format(context, comment.createdAt),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              icon: const Icon(AppIcons.dotsMenu, size: 18),
              onSelected: (value) async {
                if (value == 'delete') {
                  final confirm = await _showDeleteDialog(context);
                  if (confirm && context.mounted) {
                    final success = await context.read<CommentProvider>().deleteComment(
                      commentId: comment.id,
                      userId: authUser!.id,
                      targetId: comment.commentableId,
                    );
                    if (success && context.mounted) {
                      AppSnackBar.show(context, "تم حذف التعليق بنجاح");
                    }
                  }
                } else if (value == 'report') {
                  ReportUtils.showReportSheet(context, comment.id.toString(), 'comment');
                }
              },
              itemBuilder: (context) => [
                if (isMine)
                  const PopupMenuItem(
                    value: 'delete',
                    child: _PopupItem(
                      icon: Icons.delete_outline_rounded,
                      text: "حذف التعليق",
                      color: Colors.redAccent,
                    ),
                  ),
                const PopupMenuItem(
                  value: 'report',
                  child: _PopupItem(
                    icon: Icons.report_problem_outlined,
                    text: "إبلاغ عن التعليق",
                  ),
                ),
              ],
            ),
          )
        ],
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

