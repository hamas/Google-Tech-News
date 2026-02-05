import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/services/connectivity_service.dart';
import '../../../../../core/services/export_service.dart';
import '../../../../shared/data/database.dart';
import '../../data/datasources/dlp_rss_fetcher.dart';
import '../../data/datasources/dlp_rss_parser.dart';
import '../../data/datasources/drift_service.dart';
import '../../data/repositories/news_repository_impl.dart';
import '../../domain/entities/news_article.dart';
import '../../domain/repositories/news_repository.dart';
import '../../domain/usecases/fetch_news.dart';
import '../../domain/services/reader_mode/news_content_service.dart';
import '../../domain/services/reader_mode/news_scraper_service.dart';
import '../../../../core/services/story_share_service.dart';

// --- Data Sources & Infrastructure ---

final dioProvider = Provider((ref) {
  final dio = Dio();
  dio.interceptors.add(LogInterceptor(
    request: false,
    requestHeader: false,
    responseHeader: false,
    responseBody: false,
    error: true,
  ));
  return dio;
});

final rssParserProvider = Provider((ref) => DlpRssParser());

final rssFetcherProvider = Provider((ref) {
  return DlpRssFetcher(ref.watch(dioProvider));
});

final databaseProvider = Provider((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final driftServiceProvider = Provider((ref) {
  return DriftService(ref.watch(databaseProvider));
});

final newsContentServiceProvider = Provider((ref) {
  return NewsContentService(ref.watch(dioProvider));
});

final newsScraperServiceProvider = Provider((ref) {
  return NewsScraperService();
});

final storyShareServiceProvider = Provider((ref) {
  return StoryShareService();
});

final exportServiceProvider = Provider((ref) => ExportService());

final newsRepositoryProvider = Provider<NewsRepository>((ref) {
  return NewsRepositoryImpl(
    ref.watch(rssFetcherProvider),
    ref.watch(driftServiceProvider),
    ref.watch(connectivityServiceProvider),
  );
});

// --- Modern Riverpod 3.x Notifiers ---

/// Manages the filtered news feed with automatic stream disposal
class NewsFeedNotifier extends Notifier<AsyncValue<List<NewsArticle>>> {
  @override
  AsyncValue<List<NewsArticle>> build() {
    final newsAsync = ref.watch(_rawNewsStreamProvider);
    final keywordsAsync = ref.watch(mutedKeywordsProvider);

    if (newsAsync.isLoading || keywordsAsync.isLoading) {
      return const AsyncLoading();
    }
    if (newsAsync.hasError) {
      return AsyncError(newsAsync.error!, newsAsync.stackTrace!);
    }

    final articles = newsAsync.value ?? [];
    final keywords = keywordsAsync.value ?? [];

    if (keywords.isEmpty) {
      return AsyncData(articles);
    }

    final filtered = articles.where((article) {
      final title = article.title.toLowerCase();
      final summary = article.summary.toLowerCase();
      for (final k in keywords) {
        if (!k.isEnabled) {
          continue;
        }
        final muteWord = k.keyword.toLowerCase();
        if (title.contains(muteWord) || summary.contains(muteWord)) {
          return false;
        }
      }
      return true;
    }).toList();

    return AsyncData(filtered);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    await ref.read(newsRepositoryProvider).refreshNews();
  }
}

final newsFeedProvider =
    NotifierProvider<NewsFeedNotifier, AsyncValue<List<NewsArticle>>>(
        NewsFeedNotifier.new);

// --- Supporting Streams (Auto-Disposing) ---

final _rawNewsStreamProvider =
    StreamProvider.autoDispose<List<NewsArticle>>((ref) {
  return ref.watch(newsRepositoryProvider).watchNews();
});

/// Legacy compatibility for muted keywords page
final mutedKeywordsProvider =
    StreamProvider.autoDispose<List<MutedKeywordTableData>>((ref) {
  return ref.watch(newsRepositoryProvider).watchMutedKeywords();
});

final bookmarksProvider = StreamProvider.autoDispose<List<NewsArticle>>((ref) {
  return ref.watch(newsRepositoryProvider).watchBookmarks();
});

final lastUpdatedProvider = StreamProvider.autoDispose<DateTime?>((ref) {
  return ref.watch(driftServiceProvider).watchLastUpdated();
});

final newsSourcesProvider =
    StreamProvider.autoDispose<List<NewsSourceTableData>>((ref) {
  return ref.watch(newsRepositoryProvider).watchNewsSources();
});

final dataSaverProvider = StreamProvider.autoDispose<bool>((ref) {
  return ref.watch(driftServiceProvider).watchDataSaverEnabled();
});

/// Legacy compatibility for usecases
final fetchNewsProvider = Provider((ref) {
  return FetchNews(ref.watch(newsRepositoryProvider));
});
