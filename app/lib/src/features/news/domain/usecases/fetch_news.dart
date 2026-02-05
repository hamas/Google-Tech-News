import '../../../../core/utils/result.dart';
import '../entities/news_article.dart';
import '../repositories/news_repository.dart';

/// Use Case: Refresh News
///
/// Orchestrates the manual refresh of news articles.
class FetchNews {
  final NewsRepository _repository;

  FetchNews(this._repository);

  /// Executes the manual refresh.
  Future<Result<void>> call() {
    return _repository.refreshNews();
  }

  /// Searches for news (kept for compatibility or specific needs).
  Future<Result<List<NewsArticle>>> search({required String query}) {
    return _repository.searchNews(query);
  }
}
