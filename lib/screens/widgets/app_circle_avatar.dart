import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AppCircleAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;

  const AppCircleAvatar({
    super.key,
    this.imageUrl,
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cacheSize = (radius * 2 * MediaQuery.of(context).devicePixelRatio).round();

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 5, spreadRadius: 1)
        ],
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: isDark ? Colors.black87 : Colors.grey[200],
        child: ClipOval(
          child: (imageUrl == null || imageUrl!.isEmpty || !imageUrl!.startsWith('http'))
              ? Image.asset(
                  'assets/images/default_avatar.png',
                  fit: BoxFit.cover,
                  width: radius * 2,
                  height: radius * 2,
                )
              : CachedNetworkImage(
            imageUrl: imageUrl!,
            fit: BoxFit.cover,
            width: radius * 2,
            height: radius * 2,
            memCacheWidth: cacheSize,
            memCacheHeight: cacheSize,
            maxWidthDiskCache: cacheSize,
            maxHeightDiskCache: cacheSize,
            placeholder: (context, url) => Container(
              width: radius * 2,
              height: radius * 2,
              alignment: Alignment.center,
              child: SizedBox(
                width: radius,
                height: radius,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.grey[400],
                ),
              ),
            ),
            errorWidget: (context, url, error) => Image.asset(
              'assets/images/default_avatar.png', // ✅ صورة افتراضية عند حدوث خطأ في التحميل
              fit: BoxFit.cover,
              width: radius * 2,
              height: radius * 2,
            ),
            fadeInDuration: const Duration(milliseconds: 300),
            fadeOutDuration: const Duration(milliseconds: 300),
          ),
        ),
      ),
    );
  }
}
