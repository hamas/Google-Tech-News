import '../../../../core/utils/result.dart';
import '../entities/news_article.dart';
import '../../../../shared/data/database.dart';

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
  Future<Result<bool>> toggleBookmark(int id);

  /// Watches bookmarked news articles.
  Stream<List<NewsArticle>> watchBookmarks();

  // Custom RSS Methods
  Future<void> addNewsSource(String name, String url);
  Future<void> deleteNewsSource(int id);
  Future<void> toggleNewsSource(int id, bool isEnabled);
  Future<List<NewsSourceTableData>> getEnabledNewsSources();
  Stream<List<NewsSourceTableData>> watchNewsSources();

  // Muted Keywords
  Future<void> addMutedKeyword(String keyword);
  Future<void> deleteMutedKeyword(int id);
  Stream<List<MutedKeywordTableData>> watchMutedKeywords();

  // Reader Mode
  Future<void> saveFullContent(int localId, String content);
  Future<String?> getFullContent(int localId);
}
