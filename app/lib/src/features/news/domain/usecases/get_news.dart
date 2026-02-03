import '../entities/news_article.dart';
import '../repositories/news_repository.dart';

/// UseCase: WatchNews
/// Watches for real-time updates to the news feed from local storage.
class WatchNews {
  final NewsRepository _repository;

  const WatchNews(this._repository);

  /// Callable class pattern for UseCase execution.
  Stream<List<NewsArticle>> call() {
    return _repository.watchNews();
  }

  Stream<List<NewsArticle>> watchBookmarks() {
    return _repository.watchBookmarks();
  }
}
