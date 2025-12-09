class NewsSource {
  final String? id;
  final String name;
  final String? description;
  final String? url;
  final String category;
  final String language;
  final String country;

  NewsSource({
    this.id,
    required this.name,
    this.description,
    this.url,
    required this.category,
    required this.language,
    required this.country,
  });

  factory NewsSource.fromJson(Map<String, dynamic> json) {
    return NewsSource(
      id: json['id'],
      name: json['name'] ?? 'Unknown Source',
      description: json['description'],
      url: json['url'],
      category: json['category'] ?? 'general',
      language: json['language'] ?? 'en',
      country: json['country'] ?? 'us',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'url': url,
      'category': category,
      'language': language,
      'country': country,
    };
  }
}

class SourcesResponse {
  final String status;
  final List<NewsSource> sources;

  SourcesResponse({
    required this.status,
    required this.sources,
  });

  factory SourcesResponse.fromJson(Map<String, dynamic> json) {
    final sourcesList = (json['sources'] as List?)
        ?.map((source) => NewsSource.fromJson(source))
        .toList() ?? [];
    
    return SourcesResponse(
      status: json['status'] ?? 'error',
      sources: sourcesList,
    );
  }
}
