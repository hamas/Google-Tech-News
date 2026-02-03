import '../models/news_article.dart';

/// Interface for all feed providers (RSS, API, Scraper).
abstract class FeedProvider {
  /// Fetches a list of standardized [NewsArticle]s.
  Future<List<NewsArticle>> fetchArticles();

  /// unique identifier for the provider source
  String get sourceId;
}
