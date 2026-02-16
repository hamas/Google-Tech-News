import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../../entities/news_article.dart';
import '../../repositories/news_repository.dart';
import 'news_scraper_service.dart';

class NewsPreCacheService {
  final NewsScraperService _scraper;
  final NewsRepository _repository;

  NewsPreCacheService(this._scraper, this._repository);

  /// Starts the pre-caching process for the given list of articles.
  /// Usually called after a refresh to cache the top 30 items.
  Future<void> start(List<NewsArticle> articles, {int limit = 30}) async {
    final targetArticles = articles.take(limit).toList();

    debugPrint('Starting pre-cache for ${targetArticles.length} articles...');

    // We run this in sequence with small delays to avoid hammering the servers
    for (var article in targetArticles) {
      if (article.localId == null) continue;

      // 1. Check if text is already cached
      final exists = await _repository.getFullContent(article.localId!);
      if (exists == null || exists.isEmpty) {
        // 2. Scrape Text
        try {
          final blocks = await _scraper.scrape(article.url).timeout(
                const Duration(seconds: 10),
                onTimeout: () => [],
              );

          if (blocks.isNotEmpty) {
            await _repository.saveFullContent(
              article.localId!,
              jsonEncode(blocks),
            );
            debugPrint('Pre-cached text: ${article.title}');
          }
        } catch (e) {
          debugPrint('Pre-cache text failed for ${article.title}: $e');
        }
      }

      // 3. Pre-cache Hero Image
      if (article.imageUrl != null) {
        try {
          await DefaultCacheManager().downloadFile(article.imageUrl!);
        } catch (e) {
          debugPrint('Pre-cache image failed for ${article.title}: $e');
        }
      }

      // 4. Small delay to be background-friendly
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }

    debugPrint('Pre-caching complete.');
  }
}
