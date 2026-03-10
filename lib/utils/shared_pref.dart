import 'package:shared_preferences/shared_preferences.dart';

class SharedPref {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ================== SET ==================

  static Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  static Future<void> setInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  static Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  static Future<void> setDouble(String key, double value) async {
    await _prefs.setDouble(key, value);
  }

  static Future<void> setStringList(String key, List<String> value) async {
    await _prefs.setStringList(key, value);
  }

  // ================== GET ==================

  static String? getString(String key) {
    return _prefs.getString(key);
  }

  static int? getInt(String key) {
    return _prefs.getInt(key);
  }

  static bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  static double? getDouble(String key) {
    return _prefs.getDouble(key);
  }

  static List<String>? getStringList(String key) {
    return _prefs.getStringList(key);
  }

  // ================== REMOVE ==================

  static Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  static Future<void> clear() async {
    await _prefs.clear();
  }
}
