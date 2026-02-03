/// Standardized News Map model for Google Tech News.
class NewsArticle {
  final String id;
  final String title;
  final String summary;
  final String url;
  final FeedSource source;
  final DateTime publishedAt;
  final String? imageUrl;
  final List<String> tags;

  NewsArticle({
    required this.id,
    required this.title,
    required this.summary,
    required this.url,
    required this.source,
    required this.publishedAt,
    this.imageUrl,
    this.tags = const [],
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: json['id'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String,
      url: json['url'] as String,
      source: FeedSource.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => FeedSource.other,
      ),
      publishedAt: DateTime.parse(json['publishedAt'] as String),
      imageUrl: json['imageUrl'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'summary': summary,
      'url': url,
      'source': source.name,
      'publishedAt': publishedAt.toIso8601String(),
      'imageUrl': imageUrl,
      'tags': tags,
    };
  }
}

enum FeedSource {
  googleBlog,
  androidDevelopers,
  deepMind,
  chromeOS,
  materialDesign,
  issueTracker,
  googleNewsApi,
  other,
}
