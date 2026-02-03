import '../../../../core/utils/result.dart';
import '../entities/news_article.dart';

/// Interface for News Repository.
/// Defines the contract for fetching news, decoupling Domain from Data.
abstract interface class NewsRepository {
  /// Watches the latest news articles from local storage.
  Stream<List<NewsArticle>> watchNews();

  /// Triggers a fresh network fetch and updates local storage.
  Future<Result<void>> refreshNews();

  /// Searches for news articles matching [query].
  Future<Result<List<NewsArticle>>> searchNews(String query);

  /// Toggles the bookmark state of an article.
  Future<Result<bool>> toggleBookmark(String articleId);

  /// Watches bookmarked news articles.
  Stream<List<NewsArticle>> watchBookmarks();
}
