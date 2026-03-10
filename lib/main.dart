import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/block_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/comment_provider.dart';
import 'providers/database_provider.dart';
import 'providers/follow_provider.dart';
import 'providers/like_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/search_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/edit_design_provider.dart';
import 'providers/user_list_provider.dart';
import 'providers/video_provider.dart';
import 'core/constants/app_strings.dart';
import 'l10n/app_localizations.dart';
import 'providers/segmented_button_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/video_upload_provider.dart';
import 'providers/post_provider.dart';
import 'providers/video_player_provider.dart';
import 'services/dio_service.dart';
import 'services/fcm_service.dart';
import 'utils/cache_utils.dart';
import 'utils/shared_pref.dart';
import 'routes/app_router.dart';
import 'utils/snack_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await SharedPref.init();
  CacheUtils.autoSmartClean(limitMB: 50);
  await FcmService().initialize();

  final dioService = DioService();
  dioService.setForcedUpdateCallback(() {
    final context = navigatorKey.currentContext;
    if (context != null) {
      final t = AppLocalizations.of(context);
      AppSnackBar.show(context, t?.tr(AppStrings.forcedUpdateMessage) ?? "نسخة التطبيق قديمة، الرجاء تحديث التطبيق للمتابعة.", isError: true);
    }
  });

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => SegmentedButtonProvider()),
        ChangeNotifierProvider(create: (_) => DatabaseProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => EditDesignProvider()),
        ChangeNotifierProvider(create: (_) => VideoProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => LikeProvider()),
        ChangeNotifierProvider(create: (_) => FollowProvider()),
        ChangeNotifierProvider(create: (_) => VideoUploadProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserListProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => BlockProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => PostProvider()), // ✅ تفعيل الـ PostProvider
        ChangeNotifierProvider(create: (_) => VideoPlayerProvider()),
        ChangeNotifierProvider(create: (_) => CommentProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      locale: localeProvider.locale,
      themeMode: themeProvider.themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      onGenerateTitle: (context) => AppLocalizations.of(context)?.tr(AppStrings.appName) ?? 'Heartfelt',
      navigatorObservers: [AppRouteObserver()],
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: AppRouter.splash,
    );
  }
}
