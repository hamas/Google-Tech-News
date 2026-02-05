import '../../domain/entities/news_article.dart';
import '../../domain/repositories/news_repository.dart';
import '../../../../shared/data/database.dart';
import '../../../../core/utils/result.dart';
import '../datasources/dlp_rss_fetcher.dart';
import '../datasources/drift_service.dart';

import 'package:flutter/foundation.dart';

import '../../../../../core/services/connectivity_service.dart';
import 'package:drift/drift.dart';

class NewsRepositoryImpl implements NewsRepository {
  final DlpRssFetcher _remoteDataSource;
  final DriftService _localDataSource;
  final ConnectivityService _connectivityService;

  NewsRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._connectivityService,
  );

  @override
  Stream<List<NewsArticle>> watchNews() {
    return _localDataSource.watchArticles().map((rows) {
      return rows.map(_rowToDomain).toList();
    });
  }

  @override
  Stream<List<NewsArticle>> watchBookmarks() {
    return _localDataSource.watchBookmarks().map((rows) {
      return rows.map(_rowToDomain).toList();
    });
  }

  // --- Custom RSS Implementation ---

  @override
  Future<void> addNewsSource(String name, String url) async {
    await _localDataSource.addNewsSource(name, url);
    await refreshNews();
  }

  @override
  Future<void> deleteNewsSource(int id) async {
    await _localDataSource.deleteNewsSource(id);
    await refreshNews();
  }

  @override
  Future<void> toggleNewsSource(int id, bool isEnabled) async {
    await _localDataSource.toggleNewsSource(id, isEnabled);
    if (isEnabled) await refreshNews();
  }

  @override
  Future<List<NewsSourceTableData>> getEnabledNewsSources() {
    return _localDataSource.getEnabledNewsSources();
  }

  @override
  Stream<List<NewsSourceTableData>> watchNewsSources() {
    return _localDataSource.watchNewsSources();
  }

  // --- Muted Keywords ---

  @override
  Future<void> addMutedKeyword(String keyword) async {
    await _localDataSource.addMutedKeyword(keyword);
  }

  @override
  Future<void> deleteMutedKeyword(int id) async {
    await _localDataSource.deleteMutedKeyword(id);
  }

  @override
  Stream<List<MutedKeywordTableData>> watchMutedKeywords() {
    return _localDataSource.watchMutedKeywords();
  }

  @override
  Future<Result<void>> refreshNews() async {
    try {
      final isDataSaver = await _localDataSource.isDataSaverEnabled();
      if (isDataSaver) {
        final isMobile = await _connectivityService.isMobileData();
        if (isMobile) {
          debugPrint('Data Saver: Blocking fetch on mobile data.');
          return const Success(null);
        }
      }

      final enabledSources = await _localDataSource.getEnabledNewsSources();
      final extraSources = {for (var s in enabledSources) s.name: s.url};

      final remoteArticles = await _remoteDataSource.fetchAll(
        extraSources: extraSources,
      );

      if (remoteArticles.isNotEmpty) {
        final companions = remoteArticles
            .map((a) => NewsArticlesCompanion.insert(
                  title: a.title,
                  content: a.summary,
                  url: a.url,
                  imageUrl: Value(a.imageUrl),
                  source: a.source,
                  category: a.category,
                  publishedAt: a.publishedAt,
                  isBookmarked: Value(a.isBookmarked),
                  urlHash: a.id, // Using existing MD5 hash as urlHash
                ))
            .toList();

        await _localDataSource.saveArticles(companions);
        await _localDataSource.setLastUpdated(DateTime.now());
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
      final rows = await _localDataSource.searchArticles(query);
      final domainArticles = rows.map(_rowToDomain).toList();
      return Success(domainArticles);
    } catch (e, s) {
      return Failure(e, s);
    }
  }

  @override
  Future<Result<bool>> toggleBookmark(int id) async {
    try {
      final result = await _localDataSource.toggleBookmark(id);
      return Success(result);
    } catch (e, s) {
      return Failure(e, s);
    }
  }

  @override
  Future<void> saveFullContent(int localId, String content) async {
    await _localDataSource.saveFullContent(localId, content);
  }

  @override
  Future<String?> getFullContent(int localId) async {
    return _localDataSource.getFullContent(localId);
  }

  NewsArticle _rowToDomain(NewsArticleTableData row) {
    return NewsArticle(
      localId: row.id,
      id: row.urlHash,
      title: row.title,
      summary: row.content,
      url: row.url,
      imageUrl: row.imageUrl,
      publishedAt: row.publishedAt,
      source: row.source,
      category: row.category,
      isBookmarked: row.isBookmarked,
    );
  }
}
