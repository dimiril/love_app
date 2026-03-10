import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_strings.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/block_provider.dart';
import '../../providers/follow_provider.dart';
import '../../utils/number_formatter.dart';
import '../../utils/snack_bar.dart';
import '../../utils/login_modal.dart';
import '../widgets/app_circle_avatar.dart';
import '../../routes/app_router.dart';
import '../widgets/video_grid_item.dart';

class ProfileScreen extends StatefulWidget {
  final int? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = context.read<AuthProvider>().user;
      context.read<ProfileProvider>().loadProfile(widget.userId, currentUser);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final profileProvider = context.watch<ProfileProvider>();
    final authProvider = context.read<AuthProvider>();
    final user = profileProvider.user;
    final isLoading = profileProvider.isLoading;
    final isMe = user?.id == authProvider.user?.id;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isLoading && user == null) {
      return Scaffold(backgroundColor: theme.scaffoldBackgroundColor, body: const Center(child: CircularProgressIndicator()));
    }

    if (user == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(),
        body: const Center(child: Text("المستخدم غير موجود")),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(AppIcons.arrowRight, size: 22, color: theme.appBarTheme.iconTheme?.color),
        ),
        title: Text(
          isMe ? (t?.tr(AppStrings.profile) ?? "الملف الشخصي") : "",
          style: theme.appBarTheme.titleTextStyle,
        ),
        actions: [
          if (isMe) 
            IconButton(
              icon: Icon(AppIcons.edit, color: theme.appBarTheme.iconTheme?.color), 
              onPressed: () => Navigator.pushNamed(context, AppRouter.editProfile)
            ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const ClampingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            AppCircleAvatar(imageUrl: user.photoUrl, radius: 35),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user.name, style: TextStyle(fontFamily: "Kaff-Black", fontSize: 15, fontWeight: FontWeight.w900, color: theme.textTheme.bodyLarge?.color)),
                                  if (user.username != null) Text("@${user.username}", style: const TextStyle(fontFamily: "Kaff", fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blue)),
                                  if (user.bio != null && user.bio!.isNotEmpty)
                                    Padding(padding: const EdgeInsets.only(top: 4), child: Text(user.bio!, style: TextStyle(fontFamily: "Kaff", fontSize: 11, color: theme.textTheme.bodyMedium?.color))),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        IntrinsicHeight(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(context, AppRouter.userList, arguments: {'userId': user.id, 'title': t?.tr(AppStrings.following) ?? "أتابعهم", 'isFollowers': false}),
                                child: _buildStatItem("${user.followingCount}", t?.tr(AppStrings.following) ?? "أتابعهم"),
                              ),
                              VerticalDivider(color: isDark ? const Color(0xff333333) : const Color(0xffeaeaea), thickness: 1),
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(context, AppRouter.userList, arguments: {'userId': user.id, 'title': t?.tr(AppStrings.followers) ?? "المتابعون", 'isFollowers': true}),
                                child: _buildStatItem("${user.followersCount}", t?.tr(AppStrings.followers) ?? "المتابعون"),
                              ),
                              VerticalDivider(color: isDark ? const Color(0xff333333) : const Color(0xffeaeaea), thickness: 1),
                              _buildStatItem("${user.profileViews}", "المشاهدات"),
                            ],
                          ),
                        ),
                        if (!isMe) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Selector<FollowProvider, bool>(
                                  selector: (_, prov) => prov.isFollowing(user.id),
                                  builder: (context, isFollowed, _) {
                                    return _buildButton(
                                      label: isFollowed ? (t?.tr(AppStrings.unfollow) ?? "إلغاء") : (t?.tr(AppStrings.follow) ?? "متابعة"),
                                      icon: isFollowed ? Icons.favorite : AppIcons.favorite,
                                      backgroundColor: isFollowed ? (isDark ? Colors.white10 : Colors.grey[200]) : const Color(0xfff4f0ca),
                                      textColor: isFollowed ? theme.textTheme.bodyLarge?.color : const Color(0xff717051),
                                      onTap: () {
                                        if (!authProvider.isAuthenticated) { LoginModal.show(context); return; }
                                        if (!isFollowed && !user.followEnabled) { AppSnackBar.show(context, "المتابعة معطلة", isError: true); return; }
                                        context.read<FollowProvider>().toggleFollow(myUserId: authProvider.user!.id, targetUserId: user.id);
                                      },
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildButton(
                                  label: t?.tr(AppStrings.messages) ?? "رسالة",
                                  icon: Icons.chat_bubble_outline,
                                  onTap: () {
                                    if (!authProvider.isAuthenticated) { LoginModal.show(context); return; }
                                    if (!user.chatEnabled) { AppSnackBar.show(context, "المراسلة معطلة", isError: true); return; }
                                    Navigator.pushNamed(context, AppRouter.chatDetail, arguments: {'otherUserId': user.id, 'otherUserName': user.name, 'otherUserAvatar': user.photoUrl});
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Selector<BlockProvider, bool>(
                                  selector: (_, prov) => prov.isBlocked(user.id),
                                  builder: (context, isBlocked, _) {
                                    return _buildButton(
                                      label: isBlocked ? "فك الحظر" : "حظر",
                                      icon: isBlocked ? Icons.lock_open : Icons.block,
                                      backgroundColor: isBlocked ? Colors.blue.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                                      textColor: isBlocked ? Colors.blue : Colors.red,
                                      iconColor: isBlocked ? Colors.blue : Colors.red,
                                      onTap: () async {
                                        if (!authProvider.isAuthenticated) { LoginModal.show(context); return; }
                                        final success = await context.read<BlockProvider>().toggleBlock(myUserId: authProvider.user!.id, targetUserId: user.id);
                                        if (success && mounted) AppSnackBar.show(context, "تم تحديث حالة الحظر");
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (profileProvider.userVideos.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.all(8),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: 0.65,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final video = profileProvider.userVideos[index];
                      return VideoGridItem(
                        key: ValueKey("user_v_${video.id}"),
                        video: video,
                        allVideos: profileProvider.userVideos,
                        index: index,
                      );
                    },
                    childCount: profileProvider.userVideos.length,
                  ),
                ),
              )
            else if (profileProvider.isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Column(
                    children: [
                      Icon(Icons.video_library_outlined, size: 50, color: Colors.grey[isDark ? 800 : 300]),
                      const SizedBox(height: 12),
                      Text("لا توجد فيديوهات حتى الآن", style: TextStyle(fontFamily: 'Kaff', color: Colors.grey[isDark ? 600 : 400])),
                    ],
                  ),
                ),
              ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 50)),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({required String label, required IconData icon, required VoidCallback onTap, Color? backgroundColor, Color? textColor, Color? iconColor}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        backgroundColor: backgroundColor ?? (isDark ? Colors.white10 : const Color(0xfff4f0ca)),
        foregroundColor: textColor ?? theme.textTheme.bodyLarge?.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
      icon: Icon(icon, size: 16, color: iconColor ?? (isDark ? Colors.white70 : const Color(0xff717051))),
      label: Text(label, style: TextStyle(fontSize: 11, fontFamily: 'Kaff', color: textColor ?? theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStatItem(String count, String label) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      children: [
        Text(NumberFormatter.format(int.parse(count)), style: TextStyle(fontFamily: 'Kaff-black', fontSize: 15, color: isDark ? Colors.white : const Color(0xff0a1f44))),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontFamily: 'Kaff', fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
