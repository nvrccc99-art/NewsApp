import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/article.dart';
import '../models/news_response.dart';
import '../models/news_source.dart';

class NewsService {
  Future<List<Article>> getTopHeadlines({String country = 'us'}) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.topHeadlinesEndpoint}?country=$country&apiKey=${ApiConfig.apiKey}'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final newsResponse = NewsResponse.fromJson(jsonData);
        
        final articles = newsResponse.articles
            .map((article) => Article.fromJson(article))
            .toList();
        
        return articles;
      } else {
        throw Exception('Failed to load news: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching news: $e');
    }
  }

  Future<List<Article>> searchNews(String query) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.everythingEndpoint}?q=$query&language=en&apiKey=${ApiConfig.apiKey}&sortBy=publishedAt'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final newsResponse = NewsResponse.fromJson(jsonData);
        
        final articles = newsResponse.articles
            .map((article) => Article.fromJson(article))
            .toList();
        
        return articles;
      } else {
        throw Exception('Failed to search news: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching news: $e');
    }
  }

  Future<List<Article>> getNewsByCategory(String category, {String country = 'us'}) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.topHeadlinesEndpoint}?country=$country&category=$category&apiKey=${ApiConfig.apiKey}'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final newsResponse = NewsResponse.fromJson(jsonData);
        
        final articles = newsResponse.articles
            .map((article) => Article.fromJson(article))
            .toList();
        
        return articles;
      } else {
        throw Exception('Failed to load category news: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching category news: $e');
    }
  }

  // Get all available news sources
  Future<List<NewsSource>> getSources({String? category, String? language, String? country}) async {
    try {
      var url = '${ApiConfig.baseUrl}/sources?apiKey=${ApiConfig.apiKey}';
      
      if (category != null) url += '&category=$category';
      if (language != null) url += '&language=$language';
      if (country != null) url += '&country=$country';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final sourcesResponse = SourcesResponse.fromJson(jsonData);
        return sourcesResponse.sources;
      } else {
        throw Exception('Failed to load sources: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching sources: $e');
    }
  }

  // Get news from specific sources
  Future<List<Article>> getNewsBySources(List<String> sourceIds) async {
    try {
      if (sourceIds.isEmpty) return [];
      
      final sourcesParam = sourceIds.join(',');
      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.topHeadlinesEndpoint}?sources=$sourcesParam&apiKey=${ApiConfig.apiKey}'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final newsResponse = NewsResponse.fromJson(jsonData);
        
        final articles = newsResponse.articles
            .map((article) => Article.fromJson(article))
            .toList();
        
        return articles;
      } else {
        throw Exception('Failed to load news from sources: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching news from sources: $e');
    }
  }

  // Get news from a single source
  Future<List<Article>> getNewsBySource(String sourceId) async {
    return getNewsBySources([sourceId]);
  }

  // Search with date range filter
  Future<List<Article>> searchWithDateRange({
    required String query,
    DateTime? from,
    DateTime? to,
    String sortBy = 'publishedAt',
  }) async {
    try {
      var url = '${ApiConfig.baseUrl}${ApiConfig.everythingEndpoint}?q=$query&language=en&apiKey=${ApiConfig.apiKey}&sortBy=$sortBy';
      
      if (from != null) {
        url += '&from=${from.toIso8601String()}';
      }
      if (to != null) {
        url += '&to=${to.toIso8601String()}';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final newsResponse = NewsResponse.fromJson(jsonData);
        
        final articles = newsResponse.articles
            .map((article) => Article.fromJson(article))
            .toList();
        
        return articles;
      } else {
        throw Exception('Failed to search with date range: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching with date range: $e');
    }
  }
}
