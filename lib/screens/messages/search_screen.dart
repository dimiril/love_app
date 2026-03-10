import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_strings.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/database_provider.dart';
import '../../providers/search_provider.dart';
import '../../utils/dialog_utils.dart';
import '../widgets/message_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _textSizeNotifier = ValueNotifier(14.0);
  String _query = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchProvider>().loadHistory();
      context.read<DatabaseProvider>().clearSearch();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _textSizeNotifier.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      context.read<DatabaseProvider>().performSearch(query: _query);
    }
  }

  void _onSearchSubmitted(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return;

    setState(() {
      _query = trimmedQuery;
    });
    context.read<SearchProvider>().addSearch(trimmedQuery);
    context.read<DatabaseProvider>().performSearch(query: trimmedQuery, refresh: true);
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
        title: TextField(
          controller: _searchController,
          style: const TextStyle(fontSize: 14, fontFamily: "Kaff"),
          maxLines: 1,
          decoration: InputDecoration(
            hintText: t?.tr(AppStrings.searchHint) ?? "ابحث هنا...",
            border: InputBorder.none,
            hintStyle: const TextStyle(fontSize: 14, fontFamily: "Kaff")
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: _onSearchSubmitted,
        ),
        actions: [
          IconButton(
            onPressed: () => DialogUtils.showTextSizeDialog(context, _textSizeNotifier),
            icon: Icon(AppIcons.textSize, size: 22, color: theme.appBarTheme.iconTheme?.color),
          ),
          IconButton(
            onPressed: () => context.read<SearchProvider>().clearHistory(),
            icon: Icon(AppIcons.trash, size: 22, color: theme.appBarTheme.iconTheme?.color),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Consumer<SearchProvider>(
              builder: (_, searchProvider, __) {
                final history = searchProvider.history;
                if (history.isEmpty || _query.isNotEmpty) return const SizedBox();

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: history.length,
                  itemBuilder: (_, index) {
                    final item = history[index];
                    return ListTile(
                      tileColor: isDark ? Colors.black87 : Colors.grey.shade100,
                      leading: const Icon(Icons.history, size: 18),
                      title: Text(
                        item.query,
                        style: TextStyle(
                          fontFamily: "Kaff",
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 11,
                        ),
                      ),
                      onTap: () {
                        _searchController.text = item.query;
                        _onSearchSubmitted(item.query);
                      },
                    );
                  },
                );
              },
            ),

            // ========== نتائج البحث ==========
            Expanded(
              child: Consumer<DatabaseProvider>(
                builder: (context, provider, _) {
                  final results = provider.searchResults;
                  final isLoading = provider.loadingSearch;
                  final hasMore = provider.hasMoreSearch;

                  if (isLoading && results.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (results.isEmpty && _query.isNotEmpty) {
                    return const Center(child: Text("لا توجد نتائج"));
                  }

                  if (results.isEmpty && _query.isEmpty) {
                    return const Center(child: Text("ابدأ البحث الآن..."));
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: results.length + (hasMore ? 1 : 0),
                    itemBuilder: (_, index) {
                      if (index < results.length) {
                        return MessageCard(
                          key: ValueKey(results[index].id),
                          msg: results[index],
                          textSizeNotifier: _textSizeNotifier,
                          scrollController: _scrollController,
                          categoryId: results[index].categoryId,
                          isFavoritePage: true,
                          searchQuery: _query,
                        );
                      }
                      return const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
