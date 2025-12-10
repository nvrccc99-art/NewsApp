import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/news_source.dart';
import 'auth_service.dart';

class SourcesService {
  static const String _legacyKey = 'followed_sources';

  static Future<String> _currentKey() async {
    final user = AuthService.getCurrentUser();
    final isGuest = await AuthService.isGuest();
    if (user == null && !isGuest) {
      return 'followed_sources_anonymous';
    }
    if (isGuest) return 'followed_sources_guest';
    return 'followed_sources_${user!.uid}';
  }

  static Future<void> _maybeMigrate(SharedPreferences prefs, String key) async {
    if (!prefs.containsKey(key) && prefs.containsKey(_legacyKey)) {
      final legacy = prefs.getStringList(_legacyKey) ?? [];
      if (legacy.isNotEmpty) {
        await prefs.setStringList(key, legacy);
      }
    }
  }

  static Future<List<String>> getFollowedSources() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _currentKey();
    await _maybeMigrate(prefs, key);
    return prefs.getStringList(key) ?? [];
  }

  static Future<void> followSource(String sourceId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _currentKey();
    await _maybeMigrate(prefs, key);
    final followed = prefs.getStringList(key) ?? [];
    if (!followed.contains(sourceId)) {
      followed.add(sourceId);
      await prefs.setStringList(key, followed);
    }
  }

  static Future<void> unfollowSource(String sourceId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _currentKey();
    await _maybeMigrate(prefs, key);
    final followed = prefs.getStringList(key) ?? [];
    followed.remove(sourceId);
    await prefs.setStringList(key, followed);
  }

  static Future<bool> isFollowing(String sourceId) async {
    final followed = await getFollowedSources();
    return followed.contains(sourceId);
  }

  static Future<void> clearFollowedSources() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _currentKey();
    await prefs.remove(key);
  }
}
