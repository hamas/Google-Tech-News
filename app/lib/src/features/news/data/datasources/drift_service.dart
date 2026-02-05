import 'package:drift/drift.dart';
import '../../../../shared/data/database.dart';

class DriftService {
  final AppDatabase _db;

  DriftService(this._db);

  NewsDao get _newsDao => _db.newsDao;

  // --- News Articles (Delegated to Dao) ---

  Stream<List<NewsArticleTableData>> watchArticles() {
    return _newsDao.watchAllNews();
  }

  Stream<List<NewsArticleTableData>> watchBookmarks() {
    return (_db.select(_db.newsArticles)
          ..where((t) => t.isBookmarked.equals(true))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.publishedAt, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  Future<void> saveArticles(List<NewsArticlesCompanion> articles) async {
    await _newsDao.upsertNews(articles);
  }

  Future<List<NewsArticleTableData>> searchArticles(String query) async {
    return (_db.select(_db.newsArticles)
          ..where((t) => t.title.contains(query) | t.content.contains(query))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.publishedAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  Future<bool> toggleBookmark(int id) async {
    final article = await (_db.select(_db.newsArticles)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    if (article != null) {
      final newValue = !article.isBookmarked;
      await _newsDao.toggleBookmark(id, article.isBookmarked);
      return newValue;
    }
    return false;
  }

  // --- Muted Keywords ---

  Future<void> addMutedKeyword(String keyword) async {
    await _db.into(_db.mutedKeywords).insert(
          MutedKeywordsCompanion.insert(keyword: keyword),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<void> deleteMutedKeyword(int id) async {
    await (_db.delete(_db.mutedKeywords)..where((t) => t.id.equals(id))).go();
  }

  Stream<List<MutedKeywordTableData>> watchMutedKeywords() {
    return _db.select(_db.mutedKeywords).watch();
  }

  // --- News Sources ---

  Future<void> addNewsSource(String name, String url) async {
    await _db.into(_db.newsSources).insert(
          NewsSourcesCompanion.insert(url: url, name: name),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<void> deleteNewsSource(int id) async {
    await (_db.delete(_db.newsSources)..where((t) => t.id.equals(id))).go();
  }

  Future<void> toggleNewsSource(int id, bool isEnabled) async {
    await (_db.update(_db.newsSources)..where((t) => t.id.equals(id)))
        .write(NewsSourcesCompanion(isEnabled: Value(isEnabled)));
  }

  Future<List<NewsSourceTableData>> getEnabledNewsSources() {
    return (_db.select(_db.newsSources)..where((t) => t.isEnabled.equals(true)))
        .get();
  }

  Stream<List<NewsSourceTableData>> watchNewsSources() {
    return _db.select(_db.newsSources).watch();
  }

  // --- Metadata / Data Saver ---

  Future<void> setDataSaverEnabled(bool enabled) async {
    await _db.into(_db.appMetadata).insert(
          MetadataTableData(
              id: 0, key: 'is_data_saver_enabled', value: enabled.toString()),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<bool> isDataSaverEnabled() async {
    final entry = await (_db.select(_db.appMetadata)
          ..where((t) => t.key.equals('is_data_saver_enabled')))
        .getSingleOrNull();
    return entry?.value == 'true';
  }

  Stream<bool> watchDataSaverEnabled() {
    return (_db.select(_db.appMetadata)
          ..where((t) => t.key.equals('is_data_saver_enabled')))
        .watchSingleOrNull()
        .map((event) => event?.value == 'true');
  }

  Future<void> setLastUpdated(DateTime time) async {
    await _db.into(_db.appMetadata).insert(
          MetadataTableData(
              id: 0, key: 'last_updated', value: time.toIso8601String()),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<DateTime?> getLastUpdated() async {
    final entry = await (_db.select(_db.appMetadata)
          ..where((t) => t.key.equals('last_updated')))
        .getSingleOrNull();
    if (entry != null) {
      return DateTime.tryParse(entry.value);
    }
    return null;
  }

  Stream<DateTime?> watchLastUpdated() {
    return (_db.select(_db.appMetadata)
          ..where((t) => t.key.equals('last_updated')))
        .watchSingleOrNull()
        .map((event) => event != null ? DateTime.tryParse(event.value) : null);
  }

  // --- Reader Mode ---

  Future<void> saveFullContent(int localId, String content) async {
    await (_db.update(_db.newsArticles)..where((t) => t.id.equals(localId)))
        .write(NewsArticlesCompanion(fullContent: Value(content)));
  }

  Future<String?> getFullContent(int localId) async {
    final article = await (_db.select(_db.newsArticles)
          ..where((t) => t.id.equals(localId)))
        .getSingleOrNull();
    return article?.fullContent;
  }
}
