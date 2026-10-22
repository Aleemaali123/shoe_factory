import 'package:shared_preferences/shared_preferences.dart';

class SessionStore {
  static const _tokenKey = 'sf-device-token';
  static const _branchKey = 'sf-branch';

  static Future<String?> token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveToken(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, value);
  }

  static Future<String?> branchId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_branchKey);
  }

  static Future<void> saveBranch(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_branchKey, id);
  }
}
