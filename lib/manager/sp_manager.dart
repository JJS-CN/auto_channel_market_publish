import 'package:shared_preferences/shared_preferences.dart';

///@Author jsji
///@Date 2023/8/7
///
///@Description

class SpManager {
  static late SharedPreferences _sp;

  static Future<void> launchInit() async {
    _sp = await SharedPreferences.getInstance();
  }

  static void setValue(String key, Object? value) {
    if (value is int) {
      setInt(key, value);
    } else if (value is bool) {
      setBool(key, value);
    } else if (value is double) {
      setDouble(key, value);
    } else if (value is String) {
      setString(key, value);
    } else if (value is List<String>) {
      setStringList(key, value);
    }
  }

  static Future<bool> setInt(String key, int? value, [int defaultValue = 0]) async {
    return _sp.setInt(key, value ?? defaultValue);
  }

  static int getInt(String key, [int defaultValue = 0]) {
    return _sp.getInt(key) ?? defaultValue;
  }

  static Future<bool> setBool(String key, bool? value, [bool defaultValue = false]) async {
    return _sp.setBool(key, value ?? defaultValue);
  }

  static bool getBool(String key, [bool defaultValue = false]) {
    return _sp.getBool(key) ?? defaultValue;
  }

  static Future<bool> setDouble(String key, double? value, [double defaultValue = 0.0]) async {
    return _sp.setDouble(key, value ?? defaultValue);
  }

  static double getDouble(String key, [double defaultValue = 0.0]) {
    return _sp.getDouble(key) ?? defaultValue;
  }

  static Future<bool> setString(String key, String? value, [String defaultValue = '']) async {
    return _sp.setString(key, value ?? defaultValue);
  }

  static String getString(String key, [String defaultValue = ""]) {
    return _sp.getString(key) ?? defaultValue;
  }

  static Future<bool> setStringList(String key, List<String> value) async {
    return _sp.setStringList(key, value);
  }

  static List<String> getStringList(String key)  {
    return _sp.getStringList(key) ?? List.empty(growable: true);
  }

  static Future<bool> remove(String key) async {
    return _sp.remove(key);
  }

  static Future<bool> clearAll() async {
    return _sp.clear();
  }

  static Future<Set<String>> getKeys() async {
    return _sp.getKeys();
  }

  static Future<bool> containsKey(String key) async {
    return _sp.containsKey(key);
  }
}
