import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/segmented_button_provider.dart';
import '../../providers/video_player_provider.dart';
import '../../providers/video_provider.dart';
import '../../providers/video_upload_provider.dart';
import '../../routes/app_router.dart';
import '../../utils/login_modal.dart';
import '../widgets/video_grid_item.dart';

class VideoListScreen extends StatefulWidget {
  const VideoListScreen({super.key});

  @override
  State<VideoListScreen> createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isFetchingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_isFetchingMore) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      final provider = context.read<VideoProvider>();
      final auth = context.read<AuthProvider>();

      if (!provider.isLoading && provider.hasMore) {
        _isFetchingMore = true;

        provider
            .loadNextPage(currentUserId: auth.user?.id ?? 0)
            .whenComplete(() => _isFetchingMore = false);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return Selector<SegmentedButtonProvider, int>(
      selector: (_, p) => p.currentIndex,
      builder: (context, currentIndex, child) {

        /// 🔥 يتحمّل غير ملي نوصلو للتاب رقم 1
        if (currentIndex == 2) {
          final videoProvider = context.read<VideoProvider>();

          /// ❗ ما يعاودش التحميل إلا كانت الداتا موجودة
          if (videoProvider.videos.isEmpty &&
              !videoProvider.isLoading) {

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                videoProvider.loadInitial(
                  currentUserId: auth.user?.id ?? 0,
                );
              }
            });
          }
        }

        return child!;
      },

      /// 🧠 child ما كيعاودش rebuild
      child: Stack(
        children: [

          /// 🔹 First loading indicator
          Selector<VideoProvider, bool>(
            selector: (_, p) => p.isLoading && p.videos.isEmpty,
            builder: (context, isFirstLoading, _) {
              if (isFirstLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              return RefreshIndicator(
                onRefresh: () => context
                    .read<VideoProvider>()
                    .loadInitial(currentUserId: auth.user?.id ?? 0),

                child: Consumer<VideoProvider>(
                  builder: (context, provider, _) {

                    return GridView.builder(
                      controller: _scrollController,
                      cacheExtent: 800, // 🔥 scroll smooth
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      physics: const AlwaysScrollableScrollPhysics(),
                      addRepaintBoundaries: true,
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                        childAspectRatio: 0.65,
                      ),
                      itemCount: provider.videos.length,
                      itemBuilder: (context, index) {
                        final video = provider.videos[index];
                        if (index == 0) {
                          return _buildAddStoryButton(context);
                        }
                        return VideoGridItem(
                          key: ValueKey(video.id),
                          video: video,
                          allVideos: provider.videos,
                          index: index,
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),

          /// 🔹 Pagination loading overlay (معزول)
          Selector<VideoProvider, bool>(
            selector: (_, p) =>
            p.isLoading && p.videos.isNotEmpty,
            builder: (context, show, _) {
              if (!show) return const SizedBox.shrink();

              return const Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  Widget _buildAddStoryButton(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.read<AuthProvider>();
    final String? photoUrl = auth.user?.photoUrl;

    return GestureDetector(
      onTap: () async {
        if (!auth.isAuthenticated) {
          LoginModal.show(context);
          return;
        }

        final uploadProv = context.read<VideoUploadProvider>();
        await uploadProv.pickVideo(context);

        if (!context.mounted || uploadProv.selectedVideo == null) return;

        // Pause all videos before navigation
        context.read<VideoPlayerProvider>().pauseAll();
        Navigator.pushNamed(context, AppRouter.uploadVideo);
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            // الصورة + زر "+"
            Expanded(
              flex: 3,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      image: DecorationImage(
                        image: (photoUrl != null && photoUrl.isNotEmpty)
                            ? NetworkImage(photoUrl)
                            : const AssetImage('assets/images/default_avatar.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -15,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          shape: BoxShape.circle,
                        ),
                        child: const CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.blue,
                          child: Icon(Icons.add, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // نص "إنشاء قصة"
            const Expanded(
              flex: 1,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    "إنشاء قصة",
                    style: TextStyle(
                      fontFamily: 'Kaff',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}