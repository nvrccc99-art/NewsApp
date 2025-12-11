import 'dart:convert';
import 'dart:io';
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
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        throw Exception('No internet connection. Please check your network.');
      }
      throw Exception('Failed to load news. Please try again.');
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
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        throw Exception('No internet connection. Please check your network.');
      }
      throw Exception('Failed to search news. Please try again.');
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
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        throw Exception('No internet connection. Please check your network.');
      }
      throw Exception('Failed to load news. Please try again.');
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
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        throw Exception('No internet connection. Please check your network.');
      }
      throw Exception('Failed to load sources. Please try again.');
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
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        throw Exception('No internet connection. Please check your network.');
      }
      throw Exception('Failed to load news. Please try again.');
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
        // Start of the from date (00:00:00)
        final fromDate = DateTime(from.year, from.month, from.day);
        url += '&from=${fromDate.toIso8601String()}';
      }
      if (to != null) {
        // End of the to date (23:59:59)
        final toDate = DateTime(to.year, to.month, to.day, 23, 59, 59);
        url += '&to=${toDate.toIso8601String()}';
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
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        throw Exception('No internet connection. Please check your network.');
      }
      throw Exception('Failed to search. Please try again.');
    }
  }
}
