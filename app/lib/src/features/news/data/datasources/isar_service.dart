import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/news_collection.dart';

class IsarService {
  late Future<Isar> db;

  IsarService() {
    db = _initDb();
  }

  Future<Isar> _initDb() async {
    final dir = await getApplicationDocumentsDirectory();
    if (Isar.instanceNames.isEmpty) {
      return await Isar.open(
        [NewsCollectionSchema, AppMetadataSchema],
        directory: dir.path,
        inspector: true,
      );
    }
    return Isar.getInstance()!;
  }

  /// Save articles to local DB
  Future<void> saveArticles(List<NewsCollection> articles) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.newsCollections.putAll(articles);

      // Update sync timestamp
      final metadata = AppMetadata()
        ..key = 'last_updated'
        ..value = DateTime.now().toIso8601String();
      await isar.appMetadatas.put(metadata);
    });
  }

  /// Get last updated timestamp
  Future<DateTime?> getLastUpdated() async {
    final isar = await db;
    final metadata = await isar.appMetadatas
        .where()
        .keyEqualTo('last_updated')
        .findFirst();
    if (metadata != null) {
      return DateTime.tryParse(metadata.value);
    }
    return null;
  }

  /// Watch last updated timestamp
  Stream<DateTime?> watchLastUpdated() async* {
    final isar = await db;
    yield* isar.appMetadatas
        .where()
        .keyEqualTo('last_updated')
        .watch(fireImmediately: true)
        .map((event) {
          if (event.isNotEmpty) {
            return DateTime.tryParse(event.first.value);
          }
          return null;
        });
  }

  /// Get all articles sorted by date
  Future<List<NewsCollection>> getArticles() async {
    final isar = await db;
    return await isar.newsCollections.where().sortByPublishedAtDesc().findAll();
  }

  /// Watch articles for real-time updates
  Stream<List<NewsCollection>> watchArticles() async* {
    final isar = await db;
    yield* isar.newsCollections.where().sortByPublishedAtDesc().watch(
      fireImmediately: true,
    );
  }

  /// Search articles (Basic implementation)
  Future<List<NewsCollection>> searchArticles(String query) async {
    final isar = await db;
    return await isar.newsCollections
        .filter()
        .titleContains(query, caseSensitive: false)
        .or()
        .summaryContains(query, caseSensitive: false)
        .sortByPublishedAtDesc()
        .findAll();
  }

  /// Toggle bookmark status
  Future<bool> toggleBookmark(String articleId) async {
    final isar = await db;
    return await isar.writeTxn(() async {
      final article = await isar.newsCollections
          .filter()
          .articleIdEqualTo(articleId)
          .findFirst();
      if (article != null) {
        article.isBookmarked = !article.isBookmarked;
        await isar.newsCollections.put(article);
        return article.isBookmarked;
      }
      return false;
    });
  }

  /// Watch only bookmarked articles
  Stream<List<NewsCollection>> watchBookmarks() async* {
    final isar = await db;
    yield* isar.newsCollections
        .filter()
        .isBookmarkedEqualTo(true)
        .sortByPublishedAtDesc()
        .watch(fireImmediately: true);
  }

  /// Clear old articles (7-day TTL)
  Future<void> clearOldArticles() async {
    final isar = await db;
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    await isar.writeTxn(() async {
      final oldArticles = await isar.newsCollections
          .filter()
          .publishedAtLessThan(sevenDaysAgo)
          .findAll();

      if (oldArticles.isNotEmpty) {
        await isar.newsCollections.deleteAll(
          oldArticles.map((e) => e.id).toList(),
        );
        debugPrint('CacheManager: Purged ${oldArticles.length} old articles.');
      }
    });
  }
}
