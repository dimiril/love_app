import 'package:flutter/material.dart';
import '../core/constants/app_theme.dart';
import '../core/constants/constants.dart';
import '../utils/shared_pref.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDark = false;

  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider() {
    _loadTheme();
  }

  void _loadTheme() {
    _isDark = SharedPref.getBool(Constants.themeKey) ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    await SharedPref.setBool(Constants.themeKey, _isDark);
    notifyListeners();
  }

  ThemeData get lightTheme => AppTheme.light();
  ThemeData get darkTheme => AppTheme.dark();
}
