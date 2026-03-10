import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_strings.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_list_provider.dart';
import '../../providers/follow_provider.dart';
import '../widgets/app_circle_avatar.dart';
import '../widgets/follow_button_widget.dart';
import '../../routes/app_router.dart';

class UserListScreen extends StatefulWidget {
  final int userId;
  final String title;
  final bool isFollowers;

  const UserListScreen({
    super.key,
    required this.userId,
    required this.title,
    required this.isFollowers,
  });

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData(refresh: true);
    });
  }

  Future<void> _loadData({bool refresh = false}) async {
    final provider = context.read<UserListProvider>();
    final auth = context.read<AuthProvider>();

    if (widget.isFollowers) {
      await provider.loadFollowers(widget.userId, refresh: refresh);
    } else {
      await provider.loadFollowing(widget.userId, refresh: refresh);

      // ✅ تصحيح المشكلة: المزامنة المحلية تتم فقط إذا كان المستخدم مسجلاً ويشاهد قائمته الشخصية
      if (mounted &&
          auth.isAuthenticated &&
          auth.user!.id == widget.userId &&
          !widget.isFollowers &&
          provider.users.isNotEmpty) {

        context.read<FollowProvider>().addFollowingIdsBulk(
          provider.users.map((u) => u.id).toList(),
        );
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      _loadData(refresh: false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(AppIcons.arrowRight, size: 22, color: theme.appBarTheme.iconTheme?.color),
        ),

        title: Text(widget.title, style: theme.appBarTheme.titleTextStyle,),
      ),
      body: SafeArea(
        child: Consumer<UserListProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.users.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.users.isEmpty && !provider.isLoading) {
              return Center(child: Text(t?.tr(AppStrings.noData) ?? "لا توجد نتائج"));
            }

            return ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              itemCount: provider.users.length,
              itemBuilder: (context, index) {
                final user = provider.users[index];
                return RepaintBoundary(
                  child: ListTile(
                    key: ValueKey(user.id),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                    leading: GestureDetector(
                      onTap: () => _navigateToProfile(context, user.id),
                      child: AppCircleAvatar(imageUrl: user.photoUrl, radius: 24),
                    ),
                    title: Text(user.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Kaff-black', fontWeight: FontWeight.bold, fontSize: 12)),
                    subtitle: Text("@${user.username ?? 'user'}", style: TextStyle(fontFamily: 'Kaff', fontSize: 11, color: Colors.blue)),
                    trailing: (authProvider.isAuthenticated && authProvider.user?.id != user.id)
                        ? FollowButtonWidget(
                            myUserId: authProvider.user?.id ?? 0,
                            followingId: user.id,
                            followText: t?.tr(AppStrings.follow),
                            unfollowText: t?.tr(AppStrings.unfollow),
                      backgroundColor: Colors.black,
                      followedTextColor: Colors.red,
                          )
                        : null,
                    onTap: () => _navigateToProfile(context, user.id),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _navigateToProfile(BuildContext context, int targetId) {
    if (targetId == widget.userId) {
      Navigator.pop(context);
    } else {

      Navigator.pushNamed(context, AppRouter.profile, arguments: targetId);
    }
  }
}
