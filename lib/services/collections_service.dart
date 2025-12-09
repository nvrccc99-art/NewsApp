import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/article.dart';
import 'auth_service.dart';

class CollectionsService {
  static Future<String> _collKey() async {
    final user = AuthService.getCurrentUser();
    final isGuest = await AuthService.isGuest();
    final prefix = isGuest ? 'guest' : (user?.uid ?? 'anonymous');
    return 'collections_$prefix';
  }

  static Future<String> _itemsKey(String collection) async {
    final user = AuthService.getCurrentUser();
    final isGuest = await AuthService.isGuest();
    final prefix = isGuest ? 'guest' : (user?.uid ?? 'anonymous');
    return 'collection_${prefix}_$collection';
  }

  static Future<List<String>> getCollections() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _collKey();
    return prefs.getStringList(key) ?? [];
  }

  static Future<void> createCollection(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _collKey();
    final list = prefs.getStringList(key) ?? [];
    if (!list.contains(name)) {
      list.add(name);
      await prefs.setStringList(key, list);
    }
  }

  static Future<void> renameCollection(String oldName, String newName) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _collKey();
    final list = prefs.getStringList(key) ?? [];
    final idx = list.indexOf(oldName);
    if (idx >= 0) {
      list[idx] = newName;
      await prefs.setStringList(key, list);
      final oldKey = await _itemsKey(oldName);
      final newKey = await _itemsKey(newName);
      final items = prefs.getStringList(oldKey) ?? [];
      await prefs.setStringList(newKey, items);
      await prefs.remove(oldKey);
    }
  }

  static Future<void> deleteCollection(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _collKey();
    final list = prefs.getStringList(key) ?? [];
    list.remove(name);
    await prefs.setStringList(key, list);
    final itemsKey = await _itemsKey(name);
    await prefs.remove(itemsKey);
  }

  static Future<List<Article>> getItems(String collection) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _itemsKey(collection);
    final list = prefs.getStringList(key) ?? [];
    return list.map((e) => Article.fromJson(jsonDecode(e))).toList();
  }

  static Future<void> addItem(String collection, Article article) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _itemsKey(collection);
    final list = prefs.getStringList(key) ?? [];
    final encoded = jsonEncode(article.toJson());
    if (!list.contains(encoded)) {
      list.add(encoded);
      await prefs.setStringList(key, list);
    }
  }

  static Future<void> removeItem(String collection, Article article) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _itemsKey(collection);
    final list = prefs.getStringList(key) ?? [];
    list.removeWhere((e) => Article.fromJson(jsonDecode(e)).url == article.url);
    await prefs.setStringList(key, list);
  }
}
