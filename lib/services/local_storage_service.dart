import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LocalStorageService {
  static late SharedPreferences _preferences;

  static Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  // Save reservations locally
  static Future<void> saveReservations(List<Map<String, dynamic>> reservations) async {
    final String jsonString = json.encode(reservations);
    await _preferences.setString('reservations', jsonString);
  }

  // Get reservations from local storage
  static List<Map<String, dynamic>> getReservations() {
    final String? jsonString = _preferences.getString('reservations');
    if (jsonString == null) return [];
    
    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  // Save user preferences
  static Future<void> saveUserPreference(String key, String value) async {
    await _preferences.setString(key, value);
  }

  static String? getUserPreference(String key) {
    return _preferences.getString(key);
  }

  // Clear all data (for logout)
  static Future<void> clearAllData() async {
    await _preferences.clear();
  }
}