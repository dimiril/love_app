import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_strings.dart';
import '../l10n/app_localizations.dart';
import '../models/private_message_model.dart';
import '../providers/database_provider.dart';
import '../providers/chat_provider.dart';
import '../utils/shared_pref.dart';
import '../utils/snack_bar.dart';
import 'sync_service.dart';
import '../routes/app_router.dart';

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  late final FirebaseMessaging _messaging;

  Future<void> initialize() async {
    try {
      _messaging = FirebaseMessaging.instance;
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
      _messaging.subscribeToTopic("all_users").catchError((e) => debugPrint("Topic Error: $e"));

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);

      _messaging.getInitialMessage().then((msg) {
        if (msg != null) _handleNotificationClick(msg);
      });
    } catch (e) {
      debugPrint("FCM Init Error: $e");
    }
  }

  static void _handleForegroundMessage(RemoteMessage message) async {
    debugPrint("DEBUG: Foreground message received: ${message.data}");
    final type = message.data['type'];
    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    if (type == 'sync') {
      final syncService = SyncService();
      int newMsg = await syncService.checkAndSync();
      
      var currentCtx = navigatorKey.currentContext;
      if (currentCtx == null || !currentCtx.mounted) return;

      final dbProvider = Provider.of<DatabaseProvider>(currentCtx, listen: false);
      dbProvider.setSyncing(true);
      await dbProvider.loadCategories();
      
      currentCtx = navigatorKey.currentContext;
      if (currentCtx == null || !currentCtx.mounted) return;
      dbProvider.setSyncing(false);

      if (newMsg > 0) {
        AppSnackBar.show(currentCtx, AppLocalizations.of(currentCtx)!.tr(AppStrings.newMessagesSynced, args: {'count': newMsg.toString()}));
      }
    } 
    else if (type == 'chat') {
      try {
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        
        final newMessage = PrivateMessageModel(
          id: int.tryParse(message.data['message_id']?.toString() ?? '') ?? DateTime.now().millisecondsSinceEpoch,
          conversationId: int.tryParse(message.data['conversation_id']?.toString() ?? '0') ?? 0,
          senderId: int.tryParse(message.data['sender_id']?.toString() ?? '0') ?? 0,
          message: message.notification?.body ?? message.data['message'] ?? "",
          isSeen: false,
          createdAt: DateTime.now(),
        );

        // إضافة الرسالة للقائمة فوراً
        chatProvider.addMessageLocally(newMessage);
        
        // ✅ تحسين: لا تظهر SnackBar إذا كان المستخدم داخل شاشة الدردشة حالياً
        final activeRoutes = AppRouteObserver.activeNames;
        final bool isInChat = activeRoutes.isNotEmpty && activeRoutes.last.contains(AppRouter.chatDetail);

        if (!isInChat) {
          AppSnackBar.show(context, "${message.notification?.title}: ${message.notification?.body}");
        }
      } catch (e) {
        debugPrint("Error handling live chat: $e");
      }
    }
  }

  static void _handleNotificationClick(RemoteMessage message) {
    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    if (message.data['type'] == 'chat') {
      final int otherId = int.tryParse(message.data['sender_id']?.toString() ?? '0') ?? 0;
      final String name = message.data['sender_name'] ?? "مستخدم";
      
      Navigator.pushNamed(context, AppRouter.chatDetail, arguments: {
        'otherUserId': otherId,
        'otherUserName': name,
        'otherUserAvatar': '',
        'conversationId': int.tryParse(message.data['conversation_id']?.toString() ?? '0'),
      });
    }
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await SharedPref.init();
  if (message.data['type'] == 'sync') {
    await SyncService().checkAndSync();
  }
}
