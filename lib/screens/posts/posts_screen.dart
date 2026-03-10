import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/post_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/segmented_button_provider.dart';
import '../../routes/app_router.dart';
import '../../utils/login_modal.dart';
import '../widgets/post_card.dart';
import '../widgets/app_circle_avatar.dart';

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _didLoadOnce = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _loadInitialData() {
    if (_didLoadOnce) return;
    final provider = context.read<PostProvider>();
    final auth = context.read<AuthProvider>();

    if (provider.postIds.isEmpty && !provider.isLoading) {
      provider.loadPosts(refresh: true, userId: auth.user?.id);
    }
    _didLoadOnce = true;
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    
    final provider = context.read<PostProvider>();
    final auth = context.read<AuthProvider>();

    // ✅ تحسين شرط التمرير: البدء في التحميل قبل الوصول للنهاية بـ 400 بكسل
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 400) {
      if (!provider.isLoading && !provider.isFetchingMore && provider.hasMore) {
        provider.loadPosts(userId: auth.user?.id);
      }
    }
  }

  Future<void> _onRefresh() async {
    final auth = context.read<AuthProvider>();
    await context.read<PostProvider>().loadPosts(refresh: true, userId: auth.user?.id);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Selector<SegmentedButtonProvider, int>(
      selector: (_, p) => p.currentIndex,
      builder: (context, currentIndex, child) {
        if (currentIndex == 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadInitialData();
          });
        }
        return child!;
      },
      child: Container(
        color: isDark ? AppColors.bgDark : const Color(0xffececec),
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: CustomScrollView(
            controller: _scrollController,
            cacheExtent: 2000, // زيادة الكاش لضمان سلاسة التمرير
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Consumer<AuthProvider>(
                  builder: (context, auth, _) => _buildCreatePostBar(context, theme, auth.user),
                ),
              ),

              Consumer<PostProvider>(
                builder: (context, provider, _) {
                  final ids = provider.postIds;

                  if (ids.isEmpty && provider.isLoading) {
                    return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (ids.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(
                        child: Text("لا توجد منشورات حالياً", style: TextStyle(fontFamily: 'Kaff', color: Colors.grey)),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index < ids.length) {
                          final postId = ids[index];
                          // ✅ استخدام Selector لكل منشور لضمان أفضل أداء
                          return Selector<PostProvider, PostModel>(
                            selector: (_, p) => p.getPostById(postId),
                            builder: (context, post, _) {
                              return GestureDetector(
                                onTap: () => Navigator.pushNamed(context, AppRouter.postDetail, arguments: post),
                                child: PostCard(
                                  post: post,
                                  isAuthenticated: context.read<AuthProvider>().isAuthenticated,
                                  page: ""
                                ),
                              );
                            },
                          );
                        }

                        // مؤشر تحميل المزيد
                        if (provider.hasMore) {
                          return const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          );
                        }
                        return const SizedBox(height: 50);
                      },
                      childCount: ids.length + (provider.hasMore ? 1 : 0),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreatePostBar(
      BuildContext context,
      ThemeData theme,
      dynamic user,
      ) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDark : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          AppCircleAvatar(imageUrl: user?.photoUrl ?? "", radius: 20),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () {
                if (user == null) {
                  LoginModal.show(context);
                  return;
                }
                Navigator.pushNamed(context, AppRouter.addPost);
              },
              borderRadius: BorderRadius.circular(25),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: Text(
                  "بماذا تشعر اليوم؟",
                  style: TextStyle(
                    fontFamily: 'Kaff',
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.6,
                    ),
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              if (user == null) {
                LoginModal.show(context);
                return;
              }
              Navigator.pushNamed(context, AppRouter.addPost);
            },
            icon: const Icon(
              Icons.photo_library_rounded,
              color: Colors.green,
              size: 24,
            ),
            tooltip: "إضافة صورة",
          ),
        ],
      ),
    );
  }
}
