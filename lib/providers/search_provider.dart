import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/search_model.dart';
import '../utils/shared_pref.dart';

class SearchProvider extends ChangeNotifier {
  final List<SearchItem> _history = [];

  List<SearchItem> get history => _history.reversed.toList();

  static const int maxHistory = 5;

  Future<void> addSearch(String query) async {
    if (query.isEmpty) return;

    // إذا الكلمة موجودة، نحيدها باش نضيفها من جديد كآخر بحث
    _history.removeWhere((item) => item.query == query);
    _history.add(SearchItem(query));

    // نحافظو غير على آخر 5 كلمات
    while (_history.length > maxHistory) {
      _history.removeAt(0); // remove oldest
    }

    notifyListeners();

    final jsonList = _history.map((e) => e.toMap()).toList();
    await SharedPref.setString('search_history', jsonEncode(jsonList));
  }

  Future<void> loadHistory() async {
    final jsonString = SharedPref.getString('search_history');
    if (jsonString != null) {
      final List decoded = jsonDecode(jsonString);
      _history.clear();
      _history.addAll(decoded.map((e) => SearchItem.fromMap(e)));
      // نحافظو على آخر 5 كلمات فقط
      while (_history.length > maxHistory) {
        _history.removeAt(0);
      }
      notifyListeners();
    }
  }

  Future<void> clearHistory() async {
    _history.clear();
    notifyListeners();
    await SharedPref.remove('search_history');
  }
}