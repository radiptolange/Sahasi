import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

// --- REAL SERVICE: PERSISTENT STORAGE ---
// This service handles saving and retrieving user settings.
class SettingsService {
  // Singleton instance
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  // Get a setting value by key
  Future<dynamic> getSetting(String key) async {
    final prefs = await SharedPreferences.getInstance();
    // Default values if setting is not found
    if (key == AppConfig.keyLanguage) return prefs.getString(key) ?? 'en';
    if (key == AppConfig.keySosIntervalSeconds) return prefs.getInt(key) ?? 15;
    if (key == AppConfig.keyFakeCallDelay) return prefs.getInt(key) ?? 5;
    if (key == AppConfig.keyDoubleTapSos) return prefs.getBool(key) ?? false;
    return prefs.getBool(key) ?? true;
  }

  // Save a setting value
  Future<void> setSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is String) await prefs.setString(key, value);
    else if (value is bool) await prefs.setBool(key, value);
    else if (value is int) await prefs.setInt(key, value);
  }
}
