import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../models/post_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/comment_provider.dart';
import '../../utils/login_modal.dart'; // ✅ إضافة الاستيراد
import '../widgets/comment_card.dart';
import '../widgets/post_card.dart';

class PostDetailScreen extends StatefulWidget {
  final PostModel post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommentProvider>().loadComments(
        targetId: widget.post.id,
        type: 'post',
      );
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitComment() async {
    final auth = context.read<AuthProvider>();
    
    // ✅ التحقق من التسجيل قبل الإرسال
    if (!auth.isAuthenticated) {
      LoginModal.show(context);
      return;
    }

    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final success = await context.read<CommentProvider>().addComment(
      userId: auth.user!.id,
      targetId: widget.post.id,
      type: 'post',
      comment: text,
    );

    if (success) {
      _commentController.clear();
      if (mounted) FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xffececec),
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: isDark ? AppColors.bgDark : Colors.white,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
        title: const Text(
          "المنشور",
          style: TextStyle(fontFamily: 'Kaff-Black', fontSize: 16),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: PostCard(
                    post: widget.post,
                    isAuthenticated: auth.isAuthenticated,
                    page: 'show',
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                Consumer<CommentProvider>(
                  builder: (context, provider, _) {
                    final comments = provider.getComments(widget.post.id);

                    if (provider.isLoading(widget.post.id) && comments.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      );
                    }

                    if (comments.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text(
                              "لا توجد تعليقات بعد",
                              style: TextStyle(fontFamily: 'Kaff', color: Colors.grey),
                            ),
                          ),
                        ),
                      );
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final comment = comments[index];
                        return RepaintBoundary(
                          child: CommentCard(
                            comments: comment,
                            isAuthenticated: auth.isAuthenticated,
                          ),
                        );
                      }, childCount: comments.length),
                    );
                  },
                ),
              ],
            ),
          ),

          /// 🔹 Comment input
          Container(
            padding: EdgeInsets.fromLTRB(
              12,
              12,
              12,
              MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgDark : Colors.white,
              border: Border(top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    readOnly: !auth.isAuthenticated, // منع الكتابة للزوار
                    onTap: () {
                      if (!auth.isAuthenticated) {
                        LoginModal.show(context);
                      }
                    },
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "اكتب تعليقاً...",
                      filled: true,
                      fillColor: isDark ? Colors.white10 : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _submitComment, // دالة الإرسال تتحقق داخلياً أيضاً
                  icon: RotatedBox(
                    quarterTurns: 2,
                    child: Icon(AppIcons.send2, color: AppColors.primary, size: 28),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
