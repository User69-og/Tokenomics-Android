import 'package:shared_preferences/shared_preferences.dart';

class FirebaseConfig {
  static const String _key = 'firebase_url';

  static Future<String?> getUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  static Future<void> setUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, url);
  }
}
