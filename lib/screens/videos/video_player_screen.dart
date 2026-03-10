import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_strings.dart';
import '../../l10n/app_localizations.dart';
import '../../models/video_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/like_provider.dart';
import '../../providers/video_player_provider.dart';
import '../../providers/video_provider.dart';
import '../../providers/video_upload_provider.dart';
import '../../providers/follow_provider.dart';
import '../../routes/app_router.dart';
import '../../utils/login_modal.dart';
import '../../utils/report_utils.dart';
import '../../utils/snack_bar.dart';
import '../../utils/time_ago_formatter.dart';
import '../widgets/app_circle_avatar.dart';
import '../widgets/follow_button_widget.dart';

class VideoPlayerScreen extends StatefulWidget {
  final List<VideoModel> videos;
  final int initialIndex;

  const VideoPlayerScreen({
    super.key,
    required this.videos,
    this.initialIndex = 0,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with WidgetsBindingObserver {
  late PageController _pageController;
  final ValueNotifier<int> _currentIndexNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _currentIndexNotifier.value = widget.initialIndex;
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController(initialPage: widget.initialIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<VideoPlayerProvider>().initPlayer(
          widget.videos,
          widget.initialIndex,
        );
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final provider = context.read<VideoPlayerProvider>();
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      provider.pauseAll();
    } else if (state == AppLifecycleState.resumed) {
      provider.resumePlayback();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _currentIndexNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) context.read<VideoPlayerProvider>().disposeControllers();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: _buildOptimizedAppBar(),
        body: SafeArea(
          top: false,
          bottom: true,
          child: PageView.builder(
            scrollDirection: Axis.vertical,
            controller: _pageController,
            itemCount: widget.videos.length,
            onPageChanged: (index) {
              _currentIndexNotifier.value = index;
              context.read<VideoPlayerProvider>().onPageChanged(index);
              if (index >= 0 && index < widget.videos.length) {
                context.read<VideoProvider>().incrementView(
                  widget.videos[index],
                );
              }
            },
            itemBuilder: (context, index) => _VideoItemTile(
              key: ValueKey("v_tile_${widget.videos[index].id}"),
              index: index,
              video: widget.videos[index],
              currentIndexNotifier: _currentIndexNotifier,
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildOptimizedAppBar() {
    final t = AppLocalizations.of(context);
    return AppBar(
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
      shape: const Border(bottom: BorderSide.none),
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        style: IconButton.styleFrom(backgroundColor: Colors.black26),
        icon: const Icon(AppIcons.arrowRight, color: Colors.white, size: 22),
      ),
      actions: [
        IconButton(
          onPressed: () async {
            if (!context.read<AuthProvider>().isAuthenticated) {
              LoginModal.show(context);
              return;
            }
            final videoPlayerProv = context.read<VideoPlayerProvider>();
            final uploadProvider = context.read<VideoUploadProvider>();

            await uploadProvider.pickVideo(context);

            if (mounted && uploadProvider.selectedVideo != null) {
              videoPlayerProv.pauseAll();
              await Navigator.pushNamed(context, AppRouter.uploadVideo);
              if (mounted) videoPlayerProv.resumePlayback();
            }
          },
          style: IconButton.styleFrom(backgroundColor: Colors.black26),
          icon: const Icon(AppIcons.videoAdd, color: Colors.white, size: 22),
        ),

        ValueListenableBuilder<int>(
          valueListenable: _currentIndexNotifier,
          builder: (context, idx, _) {
            final video = widget.videos[idx];
            return Selector<LikeProvider, bool>(
              selector: (_, prov) => prov.isVideoLiked(video.id),
              builder: (context, isLiked, _) => IconButton(
                onPressed: () {
                  final auth = context.read<AuthProvider>();
                  if (!auth.isAuthenticated) {
                    LoginModal.show(context);
                    return;
                  }
                  context.read<LikeProvider>().toggleVideoLike(auth.user!.id, video);
                },
                style: IconButton.styleFrom(backgroundColor: Colors.black26),
                icon: Icon(
                  isLiked ? AppIcons.favoriteFill : AppIcons.favorite,
                  color: isLiked ? Colors.red : Colors.white,
                  size: 22,
                ),
              ),
            );
          },
        ),

        IconButton(
          onPressed: () {
            context.read<VideoPlayerProvider>().shareVideo(
              widget.videos[_currentIndexNotifier.value],
            );
            AppSnackBar.show(
              context,
              t?.tr(AppStrings.shareVideoMessage) ??
                  "جاري تحضير الفيديو للمشاركة...",
            );
          },
          style: IconButton.styleFrom(backgroundColor: Colors.black26),
          icon: const Icon(AppIcons.share, color: Colors.white, size: 22),
        ),
        IconButton(
          onPressed: () => ReportUtils.showReportSheet(
            context,
            widget.videos[_currentIndexNotifier.value].id,
            'video',
            backgroundColor: const Color(0xff333333),
            textColor: Colors.white,
            iconColor: Colors.white,
          ),
          style: IconButton.styleFrom(backgroundColor: Colors.black26),
          icon: const Icon(AppIcons.dotsMenu, color: Colors.white, size: 22),
        ),
      ],
    );
  }
}

class _VideoItemTile extends StatelessWidget {
  final int index;
  final VideoModel video;
  final ValueNotifier<int> currentIndexNotifier;

  const _VideoItemTile({
    super.key,
    required this.index,
    required this.video,
    required this.currentIndexNotifier,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ تحسين: التحقق من وجود المتحكم في القائمة النشطة قبل الرسم
    return Selector<VideoPlayerProvider, VideoPlayerController?>(
      selector: (_, prov) => prov.controllers.containsKey(index) ? prov.controllers[index] : null,
      builder: (context, controller, _) {
        if (controller == null) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            _VideoRenderer(controller: controller),
            _InternalPlayPauseGesture(controller: controller),
            _VideoInformationOverlay(
              index: index,
              video: video,
              controller: controller,
              currentIndexNotifier: currentIndexNotifier,
            ),
          ],
        );
      },
    );
  }
}

class _VideoRenderer extends StatelessWidget {
  final VideoPlayerController controller;
  const _VideoRenderer({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, _) {
        // ✅ حماية: التأكد من جاهزية السطح الرسومي وعدم حذف المتحكم
        if (!value.isInitialized) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        return FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: value.size.width,
            height: value.size.height,
            child: VideoPlayer(controller),
          ),
        );
      },
    );
  }
}

class _InternalPlayPauseGesture extends StatelessWidget {
  final VideoPlayerController controller;
  const _InternalPlayPauseGesture({required this.controller});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () =>
          controller.value.isPlaying ? controller.pause() : controller.play(),
      child: ValueListenableBuilder(
        valueListenable: controller,
        builder: (context, value, _) => Center(
          child: (!value.isPlaying && value.isInitialized)
              ? Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.black26,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: 80,
                    color: Colors.white,
                  ),
                )
              : const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _VideoInformationOverlay extends StatelessWidget {
  final int index;
  final VideoModel video;
  final VideoPlayerController controller;
  final ValueNotifier<int> currentIndexNotifier;

  const _VideoInformationOverlay({
    required this.index,
    required this.video,
    required this.controller,
    required this.currentIndexNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: ValueListenableBuilder<int>(
        valueListenable: currentIndexNotifier,
        builder: (context, currentIdx, child) {
          return AnimatedOpacity(
            opacity: index == currentIdx ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: child,
          );
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black54, Colors.black87],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BottomProgressBar(controller: controller),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 15, 16, 25),
                child: _VideoInfoRow(video: video),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomProgressBar extends StatelessWidget {
  final VideoPlayerController controller;
  const _BottomProgressBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, _) {
        if (!value.isInitialized) return const SizedBox(height: 2);
        return SizedBox(
          height: 2,
          child: VideoProgressIndicator(
            controller,
            allowScrubbing: true,
            padding: EdgeInsets.zero,
            colors: const VideoProgressColors(
              playedColor: Colors.red,
              bufferedColor: Colors.white24,
              backgroundColor: Colors.white10,
            ),
          ),
        );
      },
    );
  }
}

class _VideoInfoRow extends StatelessWidget {
  final VideoModel video;
  const _VideoInfoRow({required this.video});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final currentUserId = context.read<AuthProvider>().user?.id;

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final prov = context.read<VideoPlayerProvider>();
              prov.pauseAll();
              await Navigator.pushNamed(
                context,
                AppRouter.profile,
                arguments: video.user.id,
              );
              if (context.mounted) {
                prov.resumePlayback();
              }
            },
            child: Row(
              children: [
                AppCircleAvatar(imageUrl: video.user.photoUrl, radius: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              "@${video.user.name}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                fontFamily: 'Kaff',
                              ),
                            ),
                          ),
                          Text(
                            " \u2022 ${TimeAgoFormatter.format(context, video.createdAt)}",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontFamily: 'Kaff',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        video.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontFamily: 'Kaff',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (currentUserId != video.user.id)
          Selector<FollowProvider, bool>(
            selector: (_, prov) => prov.isFollowing(video.user.id),
            builder: (context, isFollowed, _) {
              if (!isFollowed && !video.user.followEnabled) {
                return const SizedBox.shrink();
              }
              return FollowButtonWidget(
                myUserId: currentUserId ?? 0,
                followingId: video.user.id,
                followText: t?.tr(AppStrings.follow),
                unfollowText: t?.tr(AppStrings.unfollow),
              );
            },
          ),
      ],
    );
  }
}
