/// A domain entity representing a news article.
///
/// Contains core information displayed to the user.
/// Pure Dart class without JSON parsing logic.
class NewsArticle {
  final int? localId; // Database ID
  final String id; // urlHash
  final String title;
  final String summary; // Formerly content
  final String url;
  final String? imageUrl;
  final DateTime publishedAt;
  final String source; // Explicit string source (e.g. "Google Blog")
  final String category; // Primary category/tag

  const NewsArticle({
    this.localId,
    required this.id,
    required this.title,
    required this.summary,
    required this.url,
    required this.publishedAt,
    required this.source,
    required this.category,
    this.isBreaking = false,
    this.isBookmarked = false,
    this.imageUrl,
  });

  final bool isBreaking;
  final bool isBookmarked;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NewsArticle && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
