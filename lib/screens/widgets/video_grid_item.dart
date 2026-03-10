import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_icons.dart';
import '../../../models/video_model.dart';
import '../../../providers/video_player_provider.dart';
import '../../utils/report_utils.dart';
import '../videos/video_player_screen.dart';

class VideoGridItem extends StatelessWidget {
  final VideoModel video;
  final List<VideoModel> allVideos;
  final int index;

  const VideoGridItem({
    super.key,
    required this.video,
    required this.allVideos,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return RepaintBoundary(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider(
                create: (_) => VideoPlayerProvider(),
                child: VideoPlayerScreen(
                  videos: allVideos,
                  initialIndex: index,
                ),
              ),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: video.thumbnail,
                  fit: BoxFit.cover,
                  memCacheWidth: 300, 
                  placeholder: (context, url) => Container(
                    color: Colors.grey[isDark ? 900 : 200],
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[isDark ? 900 : 200],
                    child: const Icon(Icons.image, size: 30),
                  ),
                  color: Colors.black.withValues(alpha: 0.2),
                  colorBlendMode: BlendMode.darken,
                ),
              ),
              const Center(
                child: Icon(
                  AppIcons.play,
                  size: 25,
                  color: Colors.white,
                ),
              ),
              Positioned(
                left: 6,
                top: 6,
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: IconButton(
                      onPressed: () => ReportUtils.showReportSheet(context, video.id, 'video',             backgroundColor: const Color(0xff333333),
                        textColor: Colors.white,
                        iconColor: Colors.white,
                      ),
                      padding: EdgeInsets.zero,
                      icon: const Icon(AppIcons.dotsMenu, size: 16, color: Colors.white,)),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Text(
                  video.user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: "Kaff-black",
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      )
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 39, // حجم الدائرة مع البوردير
                  height: 39,
                  padding: const EdgeInsets.all(2), // سمك البوردير
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple, Colors.green], // ألوان الإطار بحال IG
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: video.user.photoUrl,
                      fit: BoxFit.cover,
                      width: 35,
                      height: 35,
                      memCacheWidth: 300,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[isDark ? 900 : 200],
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[isDark ? 900 : 200],
                        child: const Icon(Icons.image, size: 30),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
