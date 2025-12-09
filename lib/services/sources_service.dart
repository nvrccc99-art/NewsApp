import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/news_source.dart';

class SourcesService {
  static const String _followedSourcesKey = 'followed_sources';

  static Future<List<String>> getFollowedSources() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_followedSourcesKey) ?? [];
  }

  static Future<void> followSource(String sourceId) async {
    final prefs = await SharedPreferences.getInstance();
    final followed = prefs.getStringList(_followedSourcesKey) ?? [];
    if (!followed.contains(sourceId)) {
      followed.add(sourceId);
      await prefs.setStringList(_followedSourcesKey, followed);
    }
  }

  static Future<void> unfollowSource(String sourceId) async {
    final prefs = await SharedPreferences.getInstance();
    final followed = prefs.getStringList(_followedSourcesKey) ?? [];
    followed.remove(sourceId);
    await prefs.setStringList(_followedSourcesKey, followed);
  }

  static Future<bool> isFollowing(String sourceId) async {
    final followed = await getFollowedSources();
    return followed.contains(sourceId);
  }

  static Future<void> clearFollowedSources() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_followedSourcesKey);
  }
}
