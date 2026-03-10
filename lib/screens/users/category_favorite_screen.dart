import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_icons.dart';
import '../../providers/database_provider.dart';
import '../../utils/dialog_utils.dart';
import '../widgets/message_card.dart';

class CategoryFavoriteScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const CategoryFavoriteScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryFavoriteScreen> createState() => _CategoryFavoriteScreenState();
}

class _CategoryFavoriteScreenState extends State<CategoryFavoriteScreen> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _textSizeNotifier = ValueNotifier<double>(15.0);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DatabaseProvider>().loadFavorites(refresh: true, categoryId: widget.categoryId);
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      context.read<DatabaseProvider>().loadFavorites(categoryId: widget.categoryId);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textSizeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(AppIcons.arrowRight, size: 22, color: theme.appBarTheme.iconTheme?.color),
        ),
        title: Text(
          widget.categoryName,
          style: theme.appBarTheme.titleTextStyle,
        ),
        actions: [
          IconButton(onPressed: () => DialogUtils.showTextSizeDialog(context, _textSizeNotifier), icon: Icon(AppIcons.textSize, size: 22, color: theme.appBarTheme.iconTheme?.color)),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: Consumer<DatabaseProvider>(
          builder: (context, provider, child) {
            final favorites = provider.favorites;
            final loading = provider.loadingFavorites;

            if (loading && favorites.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (favorites.isEmpty) {
              return const Center(
                child: Text("لا توجد مفضلات في هذا القسم حالياً"),
              );
            }

            return ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: favorites.length + (provider.hasMoreFavorites ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < favorites.length) {
                  return MessageCard(
                    key: ValueKey(favorites[index].id),
                    msg: favorites[index],
                    textSizeNotifier: _textSizeNotifier,
                    categoryId: widget.categoryId,
                    scrollController: _scrollController,
                    isFavoritePage: true,
                  );
                } else {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
              },
            );
          },
        ),
      ),
    );
  }
}
