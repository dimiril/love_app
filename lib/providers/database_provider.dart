import 'package:flutter/material.dart';
import '../../models/category_model.dart';
import '../../models/message_model.dart';
import '../utils/db_helper.dart';
import '../utils/shared_pref.dart';
import '../utils/cache_utils.dart';

class DatabaseProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // ================= CACHE STATE =================
  String _cacheSize = "0 MB";
  String get cacheSize => _cacheSize;

  Future<void> updateCacheSize() async {
    _cacheSize = await CacheUtils.getCacheSize();
    notifyListeners();
  }

  Future<void> clearAppCache() async {
    await CacheUtils.clearAppCache();
    await updateCacheSize();
  }

  // ================= SYNC STATE =================
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  void setSyncing(bool value) {
    _isSyncing = value;
    notifyListeners();
  }

  // ================= CATEGORIES =================
  List<CategoryModel> _categories = [];
  List<CategoryModel> get categories => _categories;

  bool _loadingCategories = false;
  bool get loadingCategories => _loadingCategories;

  Future<void> loadCategories() async {
    _loadingCategories = true;
    notifyListeners();
    await _loadAllFavoriteIds();
    _categories = await _dbHelper.getCategories();
    _loadingCategories = false;
    notifyListeners();
  }

  Future<void> markCategoryAsRead(int categoryId) async {
    await _dbHelper.resetNewMessagesCounter(categoryId);
    final index = _categories.indexWhere((c) => c.id == categoryId);
    if (index != -1 && _categories[index].newMsg > 0) {
      _categories[index] = _categories[index].copyWith(newMsg: 0);
      notifyListeners();
    }
  }

  // ================= FAVORITES =================
  List<MessageModel> _favorites = [];
  List<MessageModel> get favorites => _favorites;

  List<CategoryModel> _favoriteCategories = [];
  List<CategoryModel> get favoriteCategories => _favoriteCategories;

  bool _loadingFavorites = false;
  bool get loadingFavorites => _loadingFavorites;

  bool _hasMoreFavorites = true;
  bool get hasMoreFavorites => _hasMoreFavorites;

  Set<int> _favoriteIds = {};
  bool isFavorite(int messageId) => _favoriteIds.contains(messageId);

  final int _limit = 20;

  Future<void> _loadAllFavoriteIds({bool force = false}) async {
    if (_favoriteIds.isNotEmpty && !force) return;
    _favoriteIds = await _dbHelper.getAllFavoriteIds();
    notifyListeners();
  }

  Future<void> loadFavoriteCategories() async {
    _favoriteCategories = await _dbHelper.getFavoriteCategories();
    notifyListeners();
  }

  Future<void> loadFavorites({bool refresh = false, int? categoryId}) async {
    if (_loadingFavorites) return;
    if (refresh) {
      _favorites = [];
      _hasMoreFavorites = true;
    }
    if (!_hasMoreFavorites) return;

    _loadingFavorites = true;
    notifyListeners();

    final currentOffset = _favorites.length;
    final newFav = await _dbHelper.getFavoriteMessages(
      categoryId: categoryId,
      limit: _limit,
      offset: currentOffset,
    );

    if (newFav.length < _limit) _hasMoreFavorites = false;

    if (refresh) {
      _favorites = newFav;
      await _loadAllFavoriteIds(force: true);
    } else {
      _favorites.addAll(newFav);
    }

    _loadingFavorites = false;
    notifyListeners();
  }

  Future<void> toggleFavorite(MessageModel msg) async {
    final bool isCurrentlyFav = isFavorite(msg.id);
    final bool newValue = !isCurrentlyFav;
    await _dbHelper.updateFavoriteStatus(msg.id, newValue);

    if (newValue) {
      _favoriteIds.add(msg.id);
      if (_favorites.isNotEmpty && !_favorites.any((m) => m.id == msg.id)) {
        _favorites.insert(0, msg.copyWith(isFavorite: true));
      }
    } else {
      _favoriteIds.remove(msg.id);
      _favorites.removeWhere((m) => m.id == msg.id);
    }

    _updateInMemoryMessages(msg.id, newValue, msg.categoryId);
    await loadFavoriteCategories();
    notifyListeners();
  }

  void _updateInMemoryMessages(int id, bool isFav, int categoryId) {
    final catMsgs = _messages[categoryId];
    if (catMsgs != null) {
      final idx = catMsgs.indexWhere((m) => m.id == id);
      if (idx != -1) catMsgs[idx] = catMsgs[idx].copyWith(isFavorite: isFav);
    }
    final searchIdx = _searchResults.indexWhere((m) => m.id == id);
    if (searchIdx != -1) _searchResults[searchIdx] = _searchResults[searchIdx].copyWith(isFavorite: isFav);
  }

  // ================= BOOKMARK =================
  Future<void> saveBookmark(int categoryId, int messageId) async {
    await SharedPref.setInt('bookmark_$categoryId', messageId);
    notifyListeners();
  }

  int getBookmark(int categoryId) => SharedPref.getInt('bookmark_$categoryId') ?? 0;

  Future<void> saveScrollPosition(int categoryId, double offset) async {
    await SharedPref.setDouble('scroll_$categoryId', offset);
  }

  double getScrollPosition(int categoryId) => SharedPref.getDouble('scroll_$categoryId') ?? 0.0;

  // ================= MESSAGES =================
  final Map<int, List<MessageModel>> _messages = {};
  Map<int, List<MessageModel>> get messages => _messages;

  final Map<int, bool> _loadingMessages = {};
  bool loadingMessages(int categoryId) => _loadingMessages[categoryId] ?? false;

  final Map<int, bool> _hasMoreMessages = {};
  bool hasMore(int categoryId) => _hasMoreMessages[categoryId] ?? true;

  Future<void> loadMessages(int categoryId, {bool refresh = false}) async {
    if (_loadingMessages[categoryId] == true) return;
    await _loadAllFavoriteIds();
    _loadingMessages[categoryId] = true;
    notifyListeners();

    if (refresh) {
      _messages[categoryId] = [];
      _hasMoreMessages[categoryId] = true;
    }

    final currentOffset = _messages[categoryId]?.length ?? 0;
    final newMsg = await _dbHelper.getMessages(
      categoryId: categoryId,
      limit: _limit,
      offset: currentOffset,
    );

    if (newMsg.length < _limit) _hasMoreMessages[categoryId] = false;
    _messages[categoryId] = [...(_messages[categoryId] ?? []), ...newMsg];
    _loadingMessages[categoryId] = false;
    notifyListeners();
  }

  // ================= SEARCH =================
  List<MessageModel> _searchResults = [];
  List<MessageModel> get searchResults => _searchResults;

  bool _loadingSearch = false;
  bool get loadingSearch => _loadingSearch;

  bool _hasMoreSearch = true;
  bool get hasMoreSearch => _hasMoreSearch;

  Future<void> performSearch({required String query, bool refresh = false, int? categoryId}) async {
    if (_loadingSearch) return;
    if (refresh) {
      _searchResults = [];
      _hasMoreSearch = true;
    }
    if (!_hasMoreSearch) return;
    _loadingSearch = true;
    notifyListeners();

    final currentOffset = _searchResults.length;
    final results = await _dbHelper.searchMessages(
      query: query.isEmpty ? '*' : query,
      categoryId: categoryId,
      limit: 50,
      offset: currentOffset,
    );

    if (results.length < 50) _hasMoreSearch = false;
    _searchResults.addAll(results);
    _loadingSearch = false;
    notifyListeners();
  }

  void clearSearch() {
    _searchResults = [];
    _hasMoreSearch = true;
    notifyListeners();
  }
}
