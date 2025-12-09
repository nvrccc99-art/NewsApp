import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/article.dart';

class OfflineService {
  static const String _offlineArticlesKey = 'offline_articles';
  static const int _maxOfflineItems = 50;

  static Future<List<Article>> getOfflineArticles() async {
    final prefs = await SharedPreferences.getInstance();
    final articlesJson = prefs.getStringList(_offlineArticlesKey) ?? [];
    
    return articlesJson.map((json) {
      return Article.fromJson(jsonDecode(json));
    }).toList();
  }

  static Future<void> saveForOffline(Article article) async {
    final prefs = await SharedPreferences.getInstance();
    final articlesJson = prefs.getStringList(_offlineArticlesKey) ?? [];
    
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
      
      await prefs.setStringList(_offlineArticlesKey, articlesJson);
    }
  }

  static Future<void> removeOfflineArticle(Article article) async {
    final prefs = await SharedPreferences.getInstance();
    final articlesJson = prefs.getStringList(_offlineArticlesKey) ?? [];
    
    articlesJson.removeWhere((json) {
      final savedArticle = Article.fromJson(jsonDecode(json));
      return savedArticle.url == article.url;
    });
    
    await prefs.setStringList(_offlineArticlesKey, articlesJson);
  }

  static Future<bool> isSavedOffline(Article article) async {
    final articles = await getOfflineArticles();
    return articles.any((a) => a.url == article.url);
  }

  static Future<void> clearOfflineArticles() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_offlineArticlesKey);
  }
}
