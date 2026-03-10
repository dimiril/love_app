import 'package:flutter/material.dart';

import '../utils/shared_pref.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _key = 'app_locale';

  Locale _locale = const Locale('ar'); // default

  Locale get locale => _locale;

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final code = SharedPref.getString(_key);

    const supported = ['ar', 'en'];

    _locale = supported.contains(code)
        ? Locale(code!)
        : const Locale('ar');

    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (!['ar', 'en'].contains(locale.languageCode)) return;

    _locale = locale;
    notifyListeners();

    await SharedPref.setString(_key, locale.languageCode);
  }
}