import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'dart:convert';

class StatsService {
  static Future<String> _key(String suffix) async {
    final user = AuthService.getCurrentUser();
    final isGuest = await AuthService.isGuest();
    final prefix = isGuest ? 'guest' : (user?.uid ?? 'anonymous');
    return 'stats_${prefix}_$suffix';
  }

  static Future<void> logRead({required String url, required String category, DateTime? at}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _key('reads');
    final list = prefs.getStringList(key) ?? [];
    final event = {
      'url': url,
      'category': category,
      'at': (at ?? DateTime.now()).toIso8601String(),
      'durationSec': 0, // placeholder; can be updated later
    };
    list.add(jsonEncode(event));
    await prefs.setStringList(key, list);

    // Increment counters
    await _incCounter('total_reads');
    await _incCategory(category);
    await _incDaily(at ?? DateTime.now());
  }

  static Future<void> _incCounter(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _key(name);
    final val = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, val + 1);
  }

  static Future<void> _incCategory(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _key('categories');
    final map = jsonDecode(prefs.getString(key) ?? '{}') as Map<String, dynamic>;
    final current = (map[category] ?? 0) as int;
    map[category] = current + 1;
    await prefs.setString(key, jsonEncode(map));
  }

  static Future<void> _incDaily(DateTime day) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _key('daily');
    final dateStr = DateTime(day.year, day.month, day.day).toIso8601String();
    final map = jsonDecode(prefs.getString(key) ?? '{}') as Map<String, dynamic>;
    final current = (map[dateStr] ?? 0) as int;
    map[dateStr] = current + 1;
    await prefs.setString(key, jsonEncode(map));
  }

  static Future<int> getTotalReads() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _key('total_reads');
    return prefs.getInt(key) ?? 0;
  }

  static Future<Map<String, int>> getFavoriteCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _key('categories');
    final map = jsonDecode(prefs.getString(key) ?? '{}') as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, (v as int)));
  }

  static Future<Map<DateTime, int>> getDailyReads() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _key('daily');
    final map = jsonDecode(prefs.getString(key) ?? '{}') as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(DateTime.parse(k), (v as int)));
  }
}
