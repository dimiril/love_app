import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_icons.dart';
import '../core/constants/app_strings.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/database_provider.dart';
import '../providers/segmented_button_provider.dart';
import '../providers/theme_provider.dart';
import '../routes/app_router.dart';
import '../services/chat_service.dart';
import '../services/sync_service.dart';
import '../utils/rate_utils.dart'; // ✅ إضافة الاستيراد
import '../utils/snack_bar.dart';
import 'messages/category_screen.dart';
import 'posts/posts_screen.dart';
import 'videos/video_list_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  DateTime? _lastQuitPressed;
  final ChatService _chatService = ChatService();
  bool _isCurrentlyOnline = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addObserver(this);
    
    Future.delayed(Duration.zero, () {
      _updateStatus(true);
      // ✅ التحقق من طلب التقييم عند فتح التطبيق
      RateUtils.checkAndShowRateDialog(context);
    });
  }

  @override
  void dispose() {
    _updateStatus(false);
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateStatus(true);
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _updateStatus(false);
    }
  }

  void _updateStatus(bool isOnline) {
    if (_isCurrentlyOnline == isOnline) return;
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated) {
      _isCurrentlyOnline = isOnline;
      _chatService.updateUserStatus(auth.user!.id, isOnline).catchError((e) {
        _isCurrentlyOnline = !isOnline;
      });
    }
  }

  void _handleScroll() {
    final provider = context.read<SegmentedButtonProvider>();
    final direction = _scrollController.position.userScrollDirection;
    if (direction == ScrollDirection.reverse) {
      provider.hide();
    } else if (direction == ScrollDirection.forward) {
      provider.show();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final titles = [
      t?.tr(AppStrings.appName) ?? "Love Messages",
      t?.tr(AppStrings.posts) ?? "Posts",
      t?.tr(AppStrings.videos) ?? "Stories",
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final provider = context.read<SegmentedButtonProvider>();
        if (provider.currentIndex != 0) {
          provider.currentIndex = 0;
          return;
        }
        final now = DateTime.now();
        if (_lastQuitPressed == null || now.difference(_lastQuitPressed!) > const Duration(seconds: 2)) {
          _lastQuitPressed = now;
          AppSnackBar.show(context, t?.tr(AppStrings.pressAgainToExit) ?? "Press again to exit");
          return;
        }
        SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight2,
        appBar: AppBar(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarBrightness: isDark ? Brightness.light : Brightness.dark,
            statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarColor: isDark ? AppColors.bgDark : AppColors.bgLight2,
          ),
          leading: IconButton(
            onPressed: () => Navigator.pushNamed(context, AppRouter.setting),
            icon: Icon(AppIcons.menu, color: theme.appBarTheme.iconTheme?.color, size: 22),
          ),
          title: Selector<SegmentedButtonProvider, int>(
            selector: (_, p) => p.currentIndex,
            builder: (_, index, __) => Text(
              titles[index],
              style: theme.appBarTheme.titleTextStyle,
            ),
          ),
          actions: [
            Selector<DatabaseProvider, bool>(
              selector: (_, p) => p.isSyncing,
              builder: (context, isSyncing, child) {
                if (!isSyncing) return child!;
                return const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)));
              },
              child: _buildIconButton(icon: AppIcons.refresh, onPressed: _syncMessages),
            ),
            _buildIconButton(icon: AppIcons.search, onPressed: () => Navigator.pushNamed(context, AppRouter.search)),
            _buildIconButton(
              icon: AppIcons.favorite,
              onPressed: () => Navigator.pushNamed(context, AppRouter.favorite),
            ),
            Selector<ThemeProvider, bool>(
              selector: (_, p) => p.isDark,
              builder: (context, isDark, _) {
                return IconButton(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  constraints: const BoxConstraints(),
                  onPressed: () => context.read<ThemeProvider>().toggleTheme(),
                  icon: Icon(
                    isDark ? Icons.light_mode : AppIcons.moon,
                    size: 22,
                    color: theme.appBarTheme.iconTheme?.color,
                  ),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          bottom: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                  child: _buildSegmentedButton(t)),
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollUpdateNotification) {
                      final delta = notification.scrollDelta ?? 0;
                      final provider = context.read<SegmentedButtonProvider>();
                      if (delta > 5.0) provider.hide();
                      if (delta < -5.0) provider.show();
                    }
                    return false;
                  },
                  child: Selector<SegmentedButtonProvider, int>(
                    selector: (_, p) => p.currentIndex,
                    builder: (_, index, __) => IndexedStack(
                      index: index,
                      children: const [CategoryScreen(), PostsScreen(), VideoListScreen()],
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

  Widget _buildSegmentedButton(AppLocalizations? t) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Selector<SegmentedButtonProvider, bool>(
      selector: (_, p) => p.isVisible,
      builder: (context, isVisible, child) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        height: isVisible ? 60 : 0,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: isVisible ? 1 : 0,
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Selector<SegmentedButtonProvider, int>(
          selector: (_, p) => p.currentIndex,
          builder: (context, currentIndex, __) {
            final provider = context.read<SegmentedButtonProvider>();
            return SegmentedButton<int>(
              style: SegmentedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xff333333) : Colors.white,
                selectedBackgroundColor: AppColors.accent,
                selectedForegroundColor: isDark ? const Color(0xff333333) : const Color(0xff3a3a3a),
                side: BorderSide(width: .5, color: isDark ? const Color(0xff444444) : const Color(0xffc2c2c2)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                textStyle: const TextStyle(fontSize: 11, fontFamily: "Kaff", fontWeight: FontWeight.w900),
              ),
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: 0, label: Text(t!.tr(AppStrings.category))),
                ButtonSegment(icon: Icon(AppIcons.now, color: Colors.redAccent, size: 22), value: 1, label: Text(t.tr(AppStrings.posts))),
                ButtonSegment(value: 2, label: Text(t.tr(AppStrings.videos))),
              ],
              selected: {currentIndex},
              onSelectionChanged: (newSelection) => provider.currentIndex = newSelection.first,
            );
          },
        ),
      ),
    );
  }

  IconButton _buildIconButton({required IconData icon, required VoidCallback onPressed}) {
    final theme = Theme.of(context);

    return IconButton(icon: Icon(icon, color: theme.appBarTheme.iconTheme?.color, size: 22), onPressed: onPressed);
  }

  Future<void> _syncMessages() async {
    final dbProvider = context.read<DatabaseProvider>();
    dbProvider.setSyncing(true);
    final count = await SyncService().checkAndSync();
    dbProvider.setSyncing(false);
    if (!mounted) return;
    if (count > 0) {
      dbProvider.loadCategories();
      AppSnackBar.show(context, AppLocalizations.of(context)!.tr(AppStrings.newMessagesSynced, args: {'count': count.toString()}));
    } else {
      AppSnackBar.success(context, AppStrings.noNewUpdates);
    }
  }
}
