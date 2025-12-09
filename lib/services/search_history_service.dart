import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'dart:convert';

class SearchHistoryService {
  static const int _maxItems = 20;

  static Future<String> _key() async {
    final user = AuthService.getCurrentUser();
    final isGuest = await AuthService.isGuest();
    final prefix = isGuest ? 'guest' : (user?.uid ?? 'anonymous');
    return 'search_history_$prefix';
  }

  static Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _key();
    final list = prefs.getStringList(key) ?? [];
    return list.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  static Future<void> addQuery(String query) async {
    if (query.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final key = await _key();
    final list = prefs.getStringList(key) ?? [];
    // remove duplicates
    list.removeWhere((e) => (jsonDecode(e) as Map<String, dynamic>)['q'] == query);
    list.insert(0, jsonEncode({'q': query, 'at': DateTime.now().toIso8601String()}));
    if (list.length > _maxItems) {
      list.removeRange(_maxItems, list.length);
    }
    await prefs.setStringList(key, list);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _key();
    await prefs.remove(key);
  }

  static Future<void> remove(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _key();
    final list = prefs.getStringList(key) ?? [];
    list.removeWhere((e) => (jsonDecode(e) as Map<String, dynamic>)['q'] == query);
    await prefs.setStringList(key, list);
  }
}
