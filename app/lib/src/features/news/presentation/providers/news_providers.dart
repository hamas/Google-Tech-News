import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/news_article.dart';
import '../../domain/usecases/fetch_news.dart';
import '../../domain/usecases/get_news.dart';
import '../../domain/repositories/news_repository.dart';
import '../../data/datasources/dlp_rss_fetcher.dart';
import '../../data/datasources/dlp_rss_parser.dart';
import '../../data/datasources/isar_service.dart';
import '../../data/repositories/news_repository_impl.dart';

// Data Sources
final dioProvider = Provider((ref) => Dio());

final rssParserProvider = Provider((ref) => DlpRssParser());

final rssFetcherProvider = Provider((ref) {
  return DlpRssFetcher(ref.watch(dioProvider));
});

// Helper for IsarService (Assumes single instance ideally, or use as Singleton)
final isarServiceProvider = Provider((ref) => IsarService());

// Repository
final newsRepositoryProvider = Provider<NewsRepository>((ref) {
  return NewsRepositoryImpl(
    ref.watch(rssFetcherProvider),
    ref.watch(isarServiceProvider),
  );
});

// UseCases
final watchNewsProvider = Provider((ref) {
  return WatchNews(ref.watch(newsRepositoryProvider));
});

final fetchNewsProvider = Provider((ref) {
  return FetchNews(ref.watch(newsRepositoryProvider));
});

// State (Feed) - StreamProvider for "Instant-On" loading
final newsFeedProvider = StreamProvider<List<NewsArticle>>((ref) {
  return ref.watch(watchNewsProvider).call();
});

// Last Updated Timestamp
final lastUpdatedProvider = StreamProvider<DateTime?>((ref) {
  return ref.watch(isarServiceProvider).watchLastUpdated();
});

// Bookmarks
final bookmarksProvider = StreamProvider<List<NewsArticle>>((ref) {
  return ref.watch(watchNewsProvider).watchBookmarks();
});
