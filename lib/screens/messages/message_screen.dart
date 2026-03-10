import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_strings.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/database_provider.dart';
import '../../utils/dialog_utils.dart';
import '../../utils/snack_bar.dart';
import '../widgets/message_card.dart';

class MessageScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const MessageScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _textSizeNotifier = ValueNotifier<double>(14.0);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final db = context.read<DatabaseProvider>();
      // تحميل الرسائل أولاً
      await db.loadMessages(widget.categoryId, refresh: true);
      // التمرير التلقائي بعد التحميل
      _scrollToSavedPosition();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textSizeNotifier.dispose();
    super.dispose();
  }

  /// ✅ تحسين منطق التمرير للعلامة المرجعية
  void _scrollToSavedPosition({bool showMsgIfEmpty = false}) {
    if (!_scrollController.hasClients) return;

    final db = context.read<DatabaseProvider>();
    final savedOffset = db.getScrollPosition(widget.categoryId);
    final t = AppLocalizations.of(context);

    if (savedOffset > 0) {
      // نستخدم تأخير بسيط لضمان بناء الـ Widgets في الـ Grid/List
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          // التحقق من أن القيمة المطلوبة لا تتجاوز الحد الأقصى الحالي
          double target = savedOffset;
          if (target > _scrollController.position.maxScrollExtent) {
             target = _scrollController.position.maxScrollExtent;
          }

          _scrollController.animateTo(
            target,
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
          );
        }
      });
    } else if (showMsgIfEmpty) {
      AppSnackBar.show(context, t?.tr(AppStrings.noBookmarkSaved) ?? "لا توجد علامة مرجعية محفوظة");
    }
  }

  void _onScroll() {
    if (_scrollController.hasClients && _scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      context.read<DatabaseProvider>().loadMessages(widget.categoryId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(AppIcons.arrowRight, size: 22, color: theme.appBarTheme.iconTheme?.color),
        ),
        title: Text(widget.categoryName, style: theme.appBarTheme.titleTextStyle),
        actions: [
          IconButton(onPressed: () => DialogUtils.showTextSizeDialog(context, _textSizeNotifier), icon: Icon(AppIcons.textSize, size: 22, color: theme.appBarTheme.iconTheme?.color)),
          IconButton(onPressed: () => _scrollToSavedPosition(showMsgIfEmpty: true), icon: Icon(AppIcons.bookmarks, size: 22, color: theme.appBarTheme.iconTheme?.color)),
        ],
      ),
      body: SafeArea(
        child: Selector<DatabaseProvider, (int, bool)>(
          selector: (_, provider) => (
            provider.messages[widget.categoryId]?.length ?? 0,
            provider.loadingMessages(widget.categoryId)
          ),
          builder: (context, data, _) {
            final provider = context.read<DatabaseProvider>();
            final messages = provider.messages[widget.categoryId] ?? [];
            final loading = data.$2;

            if (loading && messages.isEmpty) return const Center(child: CircularProgressIndicator());
            if (messages.isEmpty) return Center(child: Text(t?.tr(AppStrings.noData) ?? "لا توجد رسائل"));

            return Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                physics: const BouncingScrollPhysics(),
                cacheExtent: 2000, // زيادة الكاش لضمان وجود العناصر المحفوظة في الذاكرة
                itemCount: messages.length + (provider.hasMore(widget.categoryId) ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < messages.length) {
                    return RepaintBoundary(
                      child: MessageCard(
                        key: ValueKey("msg_${messages[index].id}"),
                        msg: messages[index],
                        textSizeNotifier: _textSizeNotifier,
                        scrollController: _scrollController,
                        categoryId: widget.categoryId,
                      ),
                    );
                  }
                  return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(strokeWidth: 2)));
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
