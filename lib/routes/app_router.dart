import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post_model.dart';
import '../providers/video_player_provider.dart';
import '../screens/home_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/messages/message_screen.dart';
import '../screens/messages/edit_message_screen.dart';
import '../screens/users/edit_profile_screen.dart';
import '../screens/users/favorite_screen.dart';
import '../screens/users/category_favorite_screen.dart';
import '../screens/messages/search_screen.dart';
import '../screens/users/profile_screen.dart';
import '../screens/videos/upload_video_screen.dart';
import '../screens/users/user_list_screen.dart';
import '../screens/users/private_inbox_screen.dart';
import '../screens/users/chat_detail_screen.dart';
import '../screens/settings/privacy_settings_screen.dart';
import '../screens/posts/add_post_screen.dart';
import '../screens/posts/post_detail_screen.dart'; // ✅ استيراد الشاشة

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class AppRouteObserver extends NavigatorObserver {
  static final List<Route> activeStack = [];
  static List<String> get activeNames => activeStack.map((e) => e.settings.name ?? '').toList();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    activeStack.add(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    activeStack.remove(route);
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    activeStack.remove(route);
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) activeStack.remove(oldRoute);
    if (newRoute != null) activeStack.add(newRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

class AppRouter {
  static const String splash = '/';
  static const String home = '/home';
  static const String login = '/login';
  static const String setting = '/setting';
  static const String messages = '/messages';
  static const String editMessage = '/edit-message';
  static const String favorite = '/favorite';
  static const String categoryFavorite = '/category-favorite';
  static const String search = '/search';
  static const String profile = '/profile';
  static const String uploadVideo = '/upload-video';
  static const String editProfile = '/edit-profile';
  static const String userList = '/user-list';
  static const String privateInbox = '/private-inbox';
  static const String chatDetail = '/chat-detail';
  static const String privacySettings = '/privacy-settings';
  static const String addPost = '/add-post';
  static const String postDetail = '/post-detail'; // ✅ مسار جديد

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final String name = settings.name ?? '';

    switch (name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen(), settings: const RouteSettings(name: splash));
      case home:
        return _buildSmoothRoute(const HomePage(), const RouteSettings(name: home));
      case profile:
        final int? userId = settings.arguments as int?;
        return _buildSmoothRoute(ProfileScreen(userId: userId), RouteSettings(name: '$profile/$userId', arguments: userId));
      case addPost:
        return _buildSmoothRoute(const AddPostScreen(), const RouteSettings(name: addPost));
      case postDetail:
        final post = settings.arguments as PostModel; // ✅ تمرير كائن المنشور
        return _buildSmoothRoute(PostDetailScreen(post: post), RouteSettings(name: '$postDetail/${post.id}', arguments: post));
      case userList:
        final args = settings.arguments as Map<String, dynamic>;
        final int userId = args['userId'];
        final String subType = args['isFollowers'] ? 'followers' : 'following';
        return _buildSmoothRoute(UserListScreen(userId: userId, title: args['title'], isFollowers: args['isFollowers']), RouteSettings(name: '$userList/$userId/$subType', arguments: args));
      case chatDetail:
        final args = settings.arguments as Map<String, dynamic>;
        return _buildSmoothRoute(ChatDetailScreen(otherUserId: args['otherUserId'], otherUserName: args['otherUserName'], otherUserAvatar: args['otherUserAvatar'], conversationId: args['conversationId']), RouteSettings(name: '$chatDetail/${args['otherUserId']}', arguments: args));
      case privateInbox:
        return _buildSmoothRoute(const PrivateInboxScreen(), const RouteSettings(name: privateInbox));
      case messages:
        final args = settings.arguments as Map<String, dynamic>;
        return _buildSmoothRoute(MessageScreen(categoryId: args['id'], categoryName: args['name']), settings);
      case editMessage:
        final content = settings.arguments as String;
        return _buildSmoothRoute(EditMessageScreen(content: content), settings);
      case privacySettings:
        return _buildSmoothRoute(const PrivacySettingsScreen(), const RouteSettings(name: privacySettings));
      case setting:
        return _buildSmoothRoute(const SettingsScreen(), settings);
      case favorite:
        return _buildSmoothRoute(const FavoriteScreen(), settings);
      case editProfile:
        return _buildSmoothRoute(const EditProfileScreen(), settings);
      case uploadVideo:
        return _buildSmoothRoute(const UploadVideoScreen(), settings);
      case categoryFavorite:
        final args = settings.arguments as Map<String, dynamic>;
        return _buildSmoothRoute(CategoryFavoriteScreen(categoryId: args['id'], categoryName: args['name']), settings);
      case search:
        return _buildSmoothRoute(const SearchScreen(), settings);
      default:
        return _buildSmoothRoute(const HomePage(), const RouteSettings(name: home));
    }
  }

  static Route _buildSmoothRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  static void pushSmart(BuildContext context, String baseRoute, dynamic id, {Map<String, dynamic>? args, String? subType, bool replace = false}) {
    final String targetName = subType != null ? '$baseRoute/$id/$subType' : '$baseRoute/$id';
    try { Provider.of<VideoPlayerProvider>(context, listen: false).pauseAll(); } catch (_) {}

    if (AppRouteObserver.activeNames.contains(targetName)) {
      Navigator.popUntil(context, (route) => route.settings.name == targetName);
    } else {
      if (replace) {
        Navigator.pushReplacementNamed(context, baseRoute, arguments: args ?? id);
      } else {
        Navigator.pushNamed(context, baseRoute, arguments: args ?? id);
      }
    }
  }

  static void popToFirstProfile(BuildContext context) {
    String? firstProfileName;
    for (final route in AppRouteObserver.activeStack) {
      if (route.settings.name != null && route.settings.name!.startsWith(profile)) {
        firstProfileName = route.settings.name;
        break;
      }
    }
    if (firstProfileName != null) {
      Navigator.popUntil(context, (route) => route.settings.name == firstProfileName);
    } else {
      Navigator.pop(context);
    }
  }
}
