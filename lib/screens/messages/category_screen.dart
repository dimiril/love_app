import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/database_provider.dart';
import '../../routes/app_router.dart';
import '../../services/sync_service.dart';
import '../../utils/snack_bar.dart';
import '../../utils/shared_pref.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialLoad();
    });
  }

  Future<void> _initialLoad() async {
    if (!mounted) return;
    final dbProvider = context.read<DatabaseProvider>();

    try {
      await dbProvider.loadCategories();

      final String? lastSyncStr = SharedPref.getString('last_sync_time');
      final DateTime now = DateTime.now();
      bool shouldSync = true;

      if (lastSyncStr != null) {
        final lastSync = DateTime.parse(lastSyncStr);
        final int syncInterval = SharedPref.getInt('sync_interval_hours') ?? 1;
        if (now.difference(lastSync).inHours < syncInterval) shouldSync = false;
      }

      if (shouldSync) {
        SyncService().checkAndSync().then((newMessagesCount) async {
          if (!mounted) return;
          await SharedPref.setString('last_sync_time', now.toIso8601String());
          if (newMessagesCount > 0) {
            await dbProvider.loadCategories();
            if (!mounted) return;
            final t = AppLocalizations.of(context);
            if (t != null) {
              AppSnackBar.show(context, t.tr(AppStrings.newMessagesSynced, args: {'count': newMessagesCount.toString()}));
            }
          }
        }).catchError((e) {
          debugPrint("Sync Error: $e");
          return null; 
        });
      }
    } catch (e) {
      debugPrint("Local load error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    
    // ✅ تحسين: نراقب قائمة الأقسام بالكامل لضمان تحديث عداد newMsg فوراً
    return Selector<DatabaseProvider, bool>(
      selector: (_, p) => p.loadingCategories,
      builder: (context, loading, _) {
        return Consumer<DatabaseProvider>(
          builder: (context, provider, _) {
            final categories = provider.categories;

            if (loading && categories.isEmpty) return const Center(child: CircularProgressIndicator());
            if (categories.isEmpty) return Center(child: Text(t?.tr(AppStrings.noCategories) ?? "لا توجد أقسام حالياً"));

            return ListView.builder(
              physics: const ClampingScrollPhysics(),
              itemCount: categories.length,
              cacheExtent: 500,
              itemBuilder: (_, index) {
                final cat = categories[index];
                
                return RepaintBoundary(
                  key: ValueKey("cat_${cat.id}_${cat.newMsg}"), 
                  child: messageListTile(
                    totalMsg: cat.totalMsg,
                    newMsg: cat.newMsg,
                    name: cat.name,
                    colorStr: cat.colors,
                    onTap: () {
                      context.read<DatabaseProvider>().markCategoryAsRead(cat.id);
                      Navigator.pushNamed(context, AppRouter.messages, arguments: {'id': cat.id, 'name': cat.name});
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget messageListTile({
    required int totalMsg,
    required int newMsg,
    required String name,
    required String? colorStr,
    VoidCallback? onTap,
  }) {
    Color themeColor = AppColors.primary;
    if (colorStr != null && colorStr.isNotEmpty) {
      try { themeColor = Color(int.parse('FF$colorStr', radix: 16)); } catch (_) {}
    }

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Row(
        children: [
          if (newMsg > 0) Container(width: 6, height: 6, margin: const EdgeInsets.only(left: 8), decoration: BoxDecoration(color: themeColor, shape: BoxShape.circle)),
          Expanded(child: Text(name, style: const TextStyle(fontFamily: 'Kaff', fontSize: 13, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (newMsg > 0)
            Container(
              padding: const EdgeInsets.all(6),
              margin: const EdgeInsets.only(left: 8),
              decoration: const BoxDecoration(color: Color(0xfffd3057), shape: BoxShape.circle),
              child: Text(newMsg > 99 ? "+99" : "+$newMsg", style: const TextStyle(color: Colors.white, fontSize: 9, fontFamily: "Kaff")),
            ),
          Text("$totalMsg", style: const TextStyle(fontSize: 12, color: Color(0xff444444), fontFamily: "Kaff")),
        ],
      ),
    );
  }
}
