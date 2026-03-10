import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_strings.dart';
import '../../l10n/app_localizations.dart';
import '../../models/category_model.dart';
import '../../providers/database_provider.dart';
import '../../routes/app_router.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DatabaseProvider>().loadFavoriteCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text(
          t?.tr(AppStrings.favorite) ?? "المفضلة",
          style: theme.appBarTheme.titleTextStyle,
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: Selector<DatabaseProvider, List<CategoryModel>>(
          selector: (_, provider) => provider.favoriteCategories,
          builder: (context, categories, child) {
            if (categories.isEmpty) {
              return const Center(
                child: Text(
                  "لا توجد مفضلات حالياً",
                  style: TextStyle(fontFamily: 'Kaff', color: Colors.grey),
                ),
              );
            }

            return ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                return ListTile(
                  tileColor: isDark ? Colors.black87 : Colors.white,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRouter.categoryFavorite,
                      arguments: {'id': cat.id, 'name': cat.name},
                    );
                  },
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                  title: Text(
                    cat.name,
                    style: const TextStyle(fontFamily: 'Kaff', fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${cat.totalMsg}",
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
