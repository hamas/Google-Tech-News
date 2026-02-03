import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:core/models/news_article.dart';
import '../models/cached_article.dart';

class LocalNewsService {
  late Future<Isar> _isarFuture;

  LocalNewsService() {
    _isarFuture = _initIsar();
  }

  Future<Isar> _initIsar() async {
    if (Isar.instanceNames.isNotEmpty) {
      return Isar.getInstance()!;
    }
    final dir = await getApplicationDocumentsDirectory();
    return await Isar.open([CachedArticleSchema], directory: dir.path);
  }

  /// Save articles to local cache
  Future<void> saveArticles(List<NewsArticle> articles) async {
    final isar = await _isarFuture;
    final cachedArticles = articles.map(CachedArticle.fromDomain).toList();

    await isar.writeTxn(() async {
      // Clear old specific strategy could be added here
      // For now, we putAll. We might want to retain "saved" items if we had a "save for later" feature.
      // But since this is a cache for offline viewing of the feed, overwriting duplicates is fine.
      await isar.cachedArticles.putAll(cachedArticles);
    });
  }

  /// Get all articles from local cache, sorted by date desc
  Future<List<NewsArticle>> getArticles() async {
    final isar = await _isarFuture;
    final cached = await isar.cachedArticles
        .where()
        .sortByPublishedAtDesc()
        .findAll();
    return cached.map((c) => c.toDomain()).toList();
  }
}
