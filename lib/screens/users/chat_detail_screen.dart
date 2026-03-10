import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_strings.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/block_provider.dart';
import '../../utils/snack_bar.dart';
import '../../utils/report_utils.dart';
import '../widgets/app_circle_avatar.dart';

class ChatDetailScreen extends StatefulWidget {
  final int otherUserId;
  final String otherUserName;
  final String otherUserAvatar;
  final int? conversationId;

  const ChatDetailScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserAvatar,
    this.conversationId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _loadData(refresh: true);
    });
  }

  Future<void> _loadData({bool refresh = false}) async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;

    await context.read<ChatProvider>().loadMessages(
      widget.conversationId,
      userId: auth.user!.id,
      otherId: widget.otherUserId,
      refresh: refresh,
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final chatProv = context.read<ChatProvider>();
      if (!chatProv.isLoading && chatProv.hasMoreMsgs) {
        _loadData(refresh: false);
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;

    final chatProv = context.read<ChatProvider>();
    _messageController.clear();

    final success = await chatProv.sendMessage(
      senderId: auth.user!.id,
      receiverId: widget.otherUserId,
      message: text,
      conversationId: chatProv.activeConversationId,
    );

    if (!success) {
      if (mounted) AppSnackBar.show(context, "فشل إرسال الرسالة", isError: true);
    }
  }

  Future<void> _handleDeleteChat() async {
    final auth = context.read<AuthProvider>();
    final chatProv = context.read<ChatProvider>();
    final convId = chatProv.activeConversationId;

    if (convId == null || auth.user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: const Text("حذف المحادثة", style: TextStyle(fontFamily: 'Kaff-Black', fontSize: 16)),
        content: const Text("هل أنت متأكد من رغبتك في حذف هذه المحادثة نهائياً؟", style: TextStyle(fontFamily: 'Kaff', fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("إلغاء")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("حذف", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await chatProv.deleteConversation(convId, auth.user!.id);
      if (success && mounted) {
        AppSnackBar.show(context, "تم حذف المحادثة بنجاح");
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(AppIcons.arrowRight, size: 22, color: theme.appBarTheme.iconTheme?.color),
        ),
        title: Row(
          children: [
            AppCircleAvatar(imageUrl: widget.otherUserAvatar, radius: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.otherUserName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, fontFamily: 'Kaff'),
                  ),
                  Selector<ChatProvider, bool>(
                    selector: (_, prov) {
                      final convIndex = prov.conversations.indexWhere((c) =>
                      c.id == prov.activeConversationId || c.otherUserId == widget.otherUserId);
                      return convIndex != -1 ? prov.conversations[convIndex].isOnline : false;
                    },
                    builder: (context, isOnline, _) {
                      return Text(
                        isOnline ? (t?.tr(AppStrings.online) ?? "متصل الآن") : (t?.tr(AppStrings.offline) ?? "غير متصل"),
                        style: TextStyle(fontSize: 10, color: isOnline ? Colors.green : Colors.grey[600], fontFamily: 'Kaff', height: 1.2),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(AppIcons.dotsMenu, color: theme.appBarTheme.iconTheme?.color),
            position: PopupMenuPosition.under,
            color: isDark ? Colors.black87 : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) async {
              if (value == 'block') {
                final isBlocked = context.read<BlockProvider>().isBlocked(widget.otherUserId);
                final success = await context.read<BlockProvider>().toggleBlock(
                  myUserId: auth.user?.id ?? 0,
                  targetUserId: widget.otherUserId,
                );
                if (success && context.mounted) {
                  AppSnackBar.show(context, isBlocked ? "تم إلغاء الحظر" : "تم حظر المستخدم");
                  if (!isBlocked) Navigator.pop(context);
                }
              } else if (value == 'delete') {
                _handleDeleteChat();
              } else if (value == 'report') {
                ReportUtils.showReportSheet(context, widget.otherUserId.toString(), 'chat', textColor: isDark ? Colors.white : Colors.black87, iconColor: isDark ? Colors.white : Colors.black87);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'block',
                child: Selector<BlockProvider, bool>(
                  selector: (_, prov) => prov.isBlocked(widget.otherUserId),
                  builder: (context, isBlocked, _) {
                    return Row(
                      children: [
                        Icon(
                          isBlocked ? Icons.lock_open : AppIcons.userBlock, 
                          color: isBlocked ? Colors.blue : Colors.red, 
                          size: 20
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isBlocked ? "إلغاء الحظر" : "حظر المستخدم", 
                          style: const TextStyle(fontFamily: 'Kaff', fontSize: 13)
                        ),
                      ],
                    );
                  },
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(AppIcons.trash, color: theme.iconTheme.color, size: 20),
                    const SizedBox(width: 12),
                    const Text("حذف المحادثة", style: TextStyle(fontFamily: 'Kaff', fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    const Icon(AppIcons.infoTriangle, color: Colors.orange, size: 20),
                    const SizedBox(width: 12),
                    const Text("إبلاغ عن إساءة", style: TextStyle(fontFamily: 'Kaff', fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, chatProv, _) {
                  final messages = chatProv.messages;

                  if (chatProv.isLoading && messages.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!chatProv.isLoading && messages.isEmpty) {
                    return Center(
                      child: Text("ابدأ المحادثة مع ${widget.otherUserName}",
                          style: const TextStyle(color: Colors.grey, fontFamily: 'Kaff')),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length + (chatProv.hasMoreMsgs ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < messages.length) {
                        final msg = messages[index];
                        final isMe = msg.senderId == auth.user?.id;
                        return _buildMessageBubble(msg.message, isMe, theme);
                      }
                      return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2)));
                    },
                  );
                },
              ),
            ),
            _buildMessageInput(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe, ThemeData theme) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
            color: isMe ? AppColors.primary : (theme.brightness == Brightness.dark ? Colors.white10 : Colors.white),
            borderRadius: BorderRadius.circular(15).copyWith(
              bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(15),
              bottomLeft: isMe ? const Radius.circular(15) : const Radius.circular(0),
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 2, spreadRadius: 1)
            ]
        ),
        child: Text(
            text,
            style: TextStyle(
              color: isMe ? Colors.white : theme.textTheme.bodyLarge?.color,
              fontFamily: 'Kaff',
              fontSize: 13,
            )
        ),
      ),
    );
  }

  Widget _buildMessageInput(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
          color: theme.cardColor,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 5, offset: const Offset(0, -2))]
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: TextStyle(fontSize: 14, fontFamily: 'Kaff', color: theme.textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                hintText: "اكتب رسالة...",
                hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                filled: true,
                fillColor: theme.brightness == Brightness.dark ? Colors.white10 : const Color(0xfff5f5f5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 4),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _messageController,
            builder: (context, value, _) {
              final bool isNotEmpty = value.text.trim().isNotEmpty;
              return IconButton(
                onPressed: isNotEmpty ? _sendMessage : null,
                icon: RotatedBox(
                  quarterTurns: 2,
                  child: Icon(AppIcons.send2, color: isNotEmpty ? AppColors.primary : Colors.grey, size: 28),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

}
