import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [NewsArticles, AppMetadata, NewsSources, MutedKeywords],
  daos: [NewsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4; // Incremented for Reader Mode fullContent

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'db.sqlite'));
      return NativeDatabase(file);
    });
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        if (from < 4) {
          // Reset for Pro Schema Alignment (Content & Social Phase)
          for (final table in allTables) {
            await m.deleteTable(table.actualTableName);
            await m.createTable(table);
          }
        }
      },
      beforeOpen: (details) async {
        // Run Pro Cleanup on app start
        final dao = NewsDao(this);
        await dao.deleteOldArticles();
      },
    );
  }
}

@DriftAccessor(tables: [NewsArticles])
class NewsDao extends DatabaseAccessor<AppDatabase> with _$NewsDaoMixin {
  NewsDao(super.db);

  /// Returns news articles sorted by most recent first
  Stream<List<NewsArticleTableData>> watchAllNews() {
    return (select(newsArticles)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.publishedAt, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  /// Insert or update news articles based on urlHash
  Future<void> upsertNews(List<NewsArticlesCompanion> entries) async {
    await batch((batch) {
      batch.insertAll(newsArticles, entries, mode: InsertMode.insertOrReplace);
    });
  }

  /// Flip bookmark status
  Future<void> toggleBookmark(int id, bool currentStatus) async {
    await (update(newsArticles)..where((t) => t.id.equals(id)))
        .write(NewsArticlesCompanion(isBookmarked: Value(!currentStatus)));
  }

  /// Cleanup: Keep only last 500 items for performance
  Future<void> deleteOldArticles() async {
    await customStatement('''
      DELETE FROM news_articles 
      WHERE id NOT IN (
        SELECT id FROM news_articles 
        ORDER BY published_at DESC 
        LIMIT 500
      ) AND is_bookmarked = 0
    ''');
  }

  /// Cleanup by date (30 days)
  Future<void> deleteNewsOlderThan(int days) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    await (delete(newsArticles)
          ..where((t) =>
              t.publishedAt.isSmallerThanValue(cutoff) &
              t.isBookmarked.equals(false)))
        .go();
  }
}
