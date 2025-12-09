class ApiConfig {
  // Ganti dengan API Key Anda dari https://newsapi.org/register
  static const String apiKey = 'b5e67c9c30204ba4becdaaf90625ff18';
  
  static const String baseUrl = 'https://newsapi.org/v2';
  static const String topHeadlinesEndpoint = '/top-headlines';
  static const String everythingEndpoint = '/everything';
  
  // Default country untuk top headlines
  static const String defaultCountry = 'us';
}
