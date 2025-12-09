import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/article.dart';
import 'auth_service.dart';

class BookmarkService {
  static const String _legacyKey = 'bookmarks';

  static Future<String> _currentKey() async {
    final user = AuthService.getCurrentUser();
    final isGuest = await AuthService.isGuest();
    if (user == null && !isGuest) {
      // Not logged in, treat as anonymous session
      return 'bookmarks_anonymous';
    }
    if (isGuest) return 'bookmarks_guest';
    return 'bookmarks_${user!.uid}';
  }

  static Future<void> _maybeMigrate(SharedPreferences prefs, String key) async {
    // Migrate legacy global bookmarks to user-specific key if present
    if (!prefs.containsKey(key) && prefs.containsKey(_legacyKey)) {
      final legacy = prefs.getStringList(_legacyKey) ?? [];
      if (legacy.isNotEmpty) {
        await prefs.setStringList(key, legacy);
      }
    }
  }

  static Future<List<Article>> getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _currentKey();
    await _maybeMigrate(prefs, key);
    final bookmarksJson = prefs.getStringList(key) ?? [];
    
    return bookmarksJson.map((json) {
      return Article.fromJson(jsonDecode(json));
    }).toList();
  }

  static Future<void> addBookmark(Article article) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _currentKey();
    await _maybeMigrate(prefs, key);
    final bookmarksJson = prefs.getStringList(key) ?? [];
    
    bookmarksJson.add(jsonEncode(article.toJson()));
    await prefs.setStringList(key, bookmarksJson);
  }

  static Future<void> removeBookmark(Article article) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _currentKey();
    await _maybeMigrate(prefs, key);
    final bookmarksJson = prefs.getStringList(key) ?? [];
    
    bookmarksJson.removeWhere((json) {
      final savedArticle = Article.fromJson(jsonDecode(json));
      return savedArticle.url == article.url;
    });
    
    await prefs.setStringList(key, bookmarksJson);
  }

  static Future<bool> isBookmarked(Article article) async {
    final bookmarks = await getBookmarks();
    return bookmarks.any((a) => a.url == article.url);
  }
}
