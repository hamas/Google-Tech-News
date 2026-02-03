import '../../domain/entities/news_article.dart';
import '../../domain/repositories/news_repository.dart';
import '../../../../core/utils/result.dart';
import '../datasources/dlp_rss_fetcher.dart';
import '../datasources/isar_service.dart';
import '../models/news_collection.dart';
import 'package:flutter/foundation.dart';

class NewsRepositoryImpl implements NewsRepository {
  final DlpRssFetcher _remoteDataSource;
  final IsarService _localDataSource;

  NewsRepositoryImpl(this._remoteDataSource, this._localDataSource);

  @override
  Stream<List<NewsArticle>> watchNews() {
    // Return a stream of local data only.
    // Manual pull-to-refresh or explicit refresh triggers remote sync.
    return _localDataSource.watchArticles().map((collections) {
      return collections.map((e) => e.toDomain()).toList();
    });
  }

  @override
  Future<Result<void>> refreshNews() async {
    try {
      final remoteArticles = await _remoteDataSource.fetchAll();
      if (remoteArticles.isNotEmpty) {
        final collections = remoteArticles
            .map(NewsCollection.fromDomain)
            .toList();

        // Save to Isar (this will trigger updates to watchNews stream)
        await _localDataSource.saveArticles(collections);
      }
      return const Success(null);
    } catch (e, s) {
      debugPrint('Refresh news failed: $e');
      return Failure(e, s);
    }
  }

  @override
  Future<Result<List<NewsArticle>>> searchNews(String query) async {
    try {
      final localArticles = await _localDataSource.searchArticles(query);
      final domainArticles = localArticles.map((e) => e.toDomain()).toList();
      return Success(domainArticles);
    } catch (e, s) {
      return Failure(e, s);
    }
  }

  @override
  Future<Result<bool>> toggleBookmark(String articleId) async {
    try {
      final result = await _localDataSource.toggleBookmark(articleId);
      return Success(result);
    } catch (e, s) {
      return Failure(e, s);
    }
  }

  @override
  Stream<List<NewsArticle>> watchBookmarks() {
    return _localDataSource.watchBookmarks().map((collections) {
      return collections.map((e) => e.toDomain()).toList();
    });
  }
}
