import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/article.dart';
import 'auth_service.dart';

class OfflineService {
  static const String _legacyKey = 'offline_articles';
  static const int _maxOfflineItems = 50;

  static Future<String> _currentKey() async {
    final user = AuthService.getCurrentUser();
    final isGuest = await AuthService.isGuest();
    if (user == null && !isGuest) {
      return 'offline_articles_anonymous';
    }
    if (isGuest) return 'offline_articles_guest';
    return 'offline_articles_${user!.uid}';
  }

  static Future<void> _maybeMigrate(SharedPreferences prefs, String key) async {
    if (!prefs.containsKey(key) && prefs.containsKey(_legacyKey)) {
      final legacy = prefs.getStringList(_legacyKey) ?? [];
      if (legacy.isNotEmpty) {
        await prefs.setStringList(key, legacy);
      }
    }
  }

  static Future<List<Article>> getOfflineArticles() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _currentKey();
    await _maybeMigrate(prefs, key);
    final articlesJson = prefs.getStringList(key) ?? [];
    
    return articlesJson.map((json) {
      return Article.fromJson(jsonDecode(json));
    }).toList();
  }

  static Future<void> saveForOffline(Article article) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _currentKey();
    await _maybeMigrate(prefs, key);
    final articlesJson = prefs.getStringList(key) ?? [];
    
    // Check if already saved
    final alreadySaved = articlesJson.any((json) {
      final savedArticle = Article.fromJson(jsonDecode(json));
      return savedArticle.url == article.url;
    });
    
    if (!alreadySaved) {
      articlesJson.insert(0, jsonEncode(article.toJson()));
      
      // Keep only last N items
      if (articlesJson.length > _maxOfflineItems) {
        articlesJson.removeRange(_maxOfflineItems, articlesJson.length);
      }
      
      await prefs.setStringList(key, articlesJson);
    }
  }

  static Future<void> removeOfflineArticle(Article article) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _currentKey();
    await _maybeMigrate(prefs, key);
    final articlesJson = prefs.getStringList(key) ?? [];
    
    articlesJson.removeWhere((json) {
      final savedArticle = Article.fromJson(jsonDecode(json));
      return savedArticle.url == article.url;
    });
    
    await prefs.setStringList(key, articlesJson);
  }

  static Future<bool> isSavedOffline(Article article) async {
    final articles = await getOfflineArticles();
    return articles.any((a) => a.url == article.url);
  }

  static Future<void> clearOfflineArticles() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _currentKey();
    await prefs.remove(key);
  }
}
