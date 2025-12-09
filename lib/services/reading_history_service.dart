import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/article.dart';
import 'auth_service.dart';

class ReadingHistoryService {
  static const String _legacyKey = 'reading_history';
  static const int _maxHistoryItems = 100;

  static Future<String> _currentKey() async {
    final user = AuthService.getCurrentUser();
    final isGuest = await AuthService.isGuest();
    if (user == null && !isGuest) {
      return 'reading_history_anonymous';
    }
    if (isGuest) return 'reading_history_guest';
    return 'reading_history_${user!.uid}';
  }

  static Future<void> _maybeMigrate(SharedPreferences prefs, String key) async {
    if (!prefs.containsKey(key) && prefs.containsKey(_legacyKey)) {
      final legacy = prefs.getStringList(_legacyKey) ?? [];
      if (legacy.isNotEmpty) {
        await prefs.setStringList(key, legacy);
      }
    }
  }

  static Future<List<Article>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _currentKey();
    await _maybeMigrate(prefs, key);
    final historyJson = prefs.getStringList(key) ?? [];
    
    return historyJson.map((json) {
      return Article.fromJson(jsonDecode(json));
    }).toList();
  }

  static Future<void> addToHistory(Article article) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _currentKey();
    await _maybeMigrate(prefs, key);
    final historyJson = prefs.getStringList(key) ?? [];
    
    // Remove if already exists (to avoid duplicates)
    historyJson.removeWhere((json) {
      final savedArticle = Article.fromJson(jsonDecode(json));
      return savedArticle.url == article.url;
    });
    
    // Add to beginning
    historyJson.insert(0, jsonEncode(article.toJson()));
    
    // Keep only last N items
    if (historyJson.length > _maxHistoryItems) {
      historyJson.removeRange(_maxHistoryItems, historyJson.length);
    }
    
    await prefs.setStringList(key, historyJson);
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _currentKey();
    await prefs.remove(key);
  }

  static Future<bool> isRead(Article article) async {
    final history = await getHistory();
    return history.any((a) => a.url == article.url);
  }
}
