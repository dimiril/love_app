import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/follow_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/login_modal.dart';

class FollowButtonWidget extends StatelessWidget {
  final int myUserId;
  final int followingId;
  final String? followText;
  final String? unfollowText;
  
  // التحكم المخصص في الألوان (إختياري)
  final Color? backgroundColor;
  final Color? followedBackgroundColor;
  final Color? borderColor;
  final Color? followedBorderColor;
  final Color? textColor;
  final Color? followedTextColor;

  const FollowButtonWidget({
    super.key,
    required this.myUserId,
    required this.followingId,
    this.followText,
    this.unfollowText,
    this.backgroundColor,
    this.followedBackgroundColor,
    this.borderColor,
    this.followedBorderColor,
    this.textColor,
    this.followedTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<FollowProvider>(
      builder: (context, provider, __) {
        final bool isFollowed = provider.isFollowing(followingId);

        // تحديد الألوان: نستخدم القيم الممررة (إن وُجدت) وإلا نستخدم الـ Defaults الحالية
        final Color currentBg = isFollowed
            ? (followedBackgroundColor ?? Colors.red.withValues(alpha: 0.2))
            : (backgroundColor ?? Colors.white.withValues(alpha: 0.15));

        final Color currentBorder = isFollowed
            ? (followedBorderColor ?? Colors.red)
            : (borderColor ?? Colors.white.withValues(alpha: 0.4));

        final Color currentTextCol = isFollowed
            ? (followedTextColor ?? Colors.white)
            : (textColor ?? Colors.white);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              if (!context.read<AuthProvider>().isAuthenticated) {
                LoginModal.show(context);
                return;
              }

              context.read<FollowProvider>().toggleFollow(
                myUserId: myUserId,
                targetUserId: followingId,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
              decoration: BoxDecoration(
                color: currentBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: currentBorder,
                  width: 1,
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                child: Text(
                  isFollowed
                      ? (unfollowText ?? "متابع")
                      : (followText ?? "متابعة"),
                  key: ValueKey(isFollowed),
                  style: TextStyle(
                    color: currentTextCol,
                    fontSize: 10,
                    fontFamily: 'Kaff',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
