import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_strings.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../routes/app_router.dart';
import '../../utils/time_ago_formatter.dart';
import '../widgets/app_circle_avatar.dart';

class PrivateInboxScreen extends StatefulWidget {
  const PrivateInboxScreen({super.key});

  @override
  State<PrivateInboxScreen> createState() => _PrivateInboxScreenState();
}

class _PrivateInboxScreenState extends State<PrivateInboxScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().user?.id;
      if (userId != null) {
        context.read<ChatProvider>().loadConversations(userId, refresh: true);
      }
    });
  }

  Future<void> _confirmDelete(BuildContext context, int conversationId, int userId) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("حذف المحادثة", style: TextStyle(fontFamily: 'Kaff-Black', fontSize: 16)),
        content: const Text("هل أنت متأكد من رغبتك في حذف هذه المحادثة نهائياً؟", style: TextStyle(fontFamily: 'Kaff', fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<ChatProvider>().deleteConversation(conversationId, userId);
            },
            child: const Text("حذف", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final userId = context.read<AuthProvider>().user?.id;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(AppIcons.arrowRight, size: 22, color: theme.appBarTheme.iconTheme?.color),
        ),
        title: Text(
          t?.tr(AppStrings.messages) ?? "الرسائل الخاصة",
          style: theme.appBarTheme.titleTextStyle,
        ),
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProv, _) {
          if (chatProv.isLoading && chatProv.conversations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (chatProv.conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mail_outline_rounded, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(t?.tr(AppStrings.noMessages) ?? "لا توجد رسائل بعد", 
                    style: const TextStyle(fontFamily: 'Kaff', color: Colors.grey)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              if (userId != null) await chatProv.loadConversations(userId, refresh: true);
            },
            child: ListView.separated(
              itemCount: chatProv.conversations.length,
              separatorBuilder: (context, index) => Divider(height: 1, indent: 70, color: isDark ? Colors.black87 : Color(0xfff5f5f5)),
              itemBuilder: (context, index) {
                final conv = chatProv.conversations[index];
                
                return Dismissible(
                  key: Key(conv.id.toString()),
                  direction: DismissDirection.endToStart, // السحب من اليمين لليسار للحذف
                  background: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    color: Colors.redAccent,
                    child: const Icon(Icons.delete_outline, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    if (userId != null) {
                      await _confirmDelete(context, conv.id, userId);
                    }
                    return false; // نمنع الحذف التلقائي للـ Dismissible لأننا نتحكم فيه عبر الـ Provider
                  },
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Stack(
                      children: [
                        AppCircleAvatar(imageUrl: conv.otherUserAvatar, radius: 26),
                        if (conv.isOnline)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(conv.otherUserName, 
                          style: const TextStyle(fontFamily: 'Kaff', fontWeight: FontWeight.bold, fontSize: 14)),
                        if (conv.lastMessageTime != null)
                          Text(TimeAgoFormatter.format(context, conv.lastMessageTime!),
                            style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              conv.lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Kaff', 
                                fontSize: 12, 
                                color: conv.unreadCount > 0 ? Colors.black : Colors.grey,
                                fontWeight: conv.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (conv.unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              child: Text("${conv.unreadCount}", 
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                    ),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRouter.chatDetail,
                        arguments: {
                          'otherUserId': conv.otherUserId,
                          'otherUserName': conv.otherUserName,
                          'otherUserAvatar': conv.otherUserAvatar,
                          'conversationId': conv.id,
                        },
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
