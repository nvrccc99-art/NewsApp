import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'dart:convert';

class RatingService {
  static Future<String> _key() async {
    final user = AuthService.getCurrentUser();
    final isGuest = await AuthService.isGuest();
    final prefix = isGuest ? 'guest' : (user?.uid ?? 'anonymous');
    return 'ratings_$prefix';
  }

  // like: true, dislike: false, null: remove
  static Future<void> setLike(String url, bool? like) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _key();
    final map = jsonDecode(prefs.getString(key) ?? '{}') as Map<String, dynamic>;
    if (like == null) {
      map.remove(url);
    } else {
      map[url] = {'like': like};
    }
    await prefs.setString(key, jsonEncode(map));
  }

  static Future<bool?> getLike(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _key();
    final map = jsonDecode(prefs.getString(key) ?? '{}') as Map<String, dynamic>;
    final v = map[url];
    if (v == null) return null;
    return (v as Map<String, dynamic>)['like'] as bool?;
  }

  static Future<Map<String, bool>> getAllLikes() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _key();
    final map = jsonDecode(prefs.getString(key) ?? '{}') as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, (v as Map<String, dynamic>)['like'] as bool));
  }

  static Future<void> setRating(String url, int? stars) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _key();
    final map = jsonDecode(prefs.getString(key) ?? '{}') as Map<String, dynamic>;
    final entry = (map[url] ?? {}) as Map<String, dynamic>;
    if (stars == null) {
      entry.remove('stars');
    } else {
      entry['stars'] = stars.clamp(1, 5);
    }
    map[url] = entry;
    await prefs.setString(key, jsonEncode(map));
  }

  static Future<int?> getRating(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _key();
    final map = jsonDecode(prefs.getString(key) ?? '{}') as Map<String, dynamic>;
    final v = map[url];
    if (v == null) return null;
    return (v as Map<String, dynamic>)['stars'] as int?;
  }
}
