import 'dart:async';
import 'package:core/models/news_article.dart';
import 'package:core/interfaces/feed_interface.dart';
import 'package:backend/services/official_blogs_scraper.dart';
import 'package:backend/services/google_news_fetcher.dart';
import 'package:backend/services/leak_hunter.dart';

import 'package:backend/services/ai_tagger.dart';

class FeedService {
  final List<FeedProvider> _providers = [];
  final AiTagger _aiTagger = AiTagger();

  FeedService() {
    registerProvider(OfficialBlogsScraper());
    registerProvider(GoogleNewsFetcher());
    registerProvider(LeakHunter());
  }

  void registerProvider(FeedProvider provider) {
    _providers.add(provider);
  }

  Future<List<NewsArticle>> fetchAllFeeds() async {
    final futures = _providers.map(
      (p) => p.fetchArticles().catchError((e) {
        print('Error fetching from ${p.sourceId}: $e');
        return <NewsArticle>[];
      }),
    );

    final results = await Future.wait(futures);
    final rawArticles = results.expand((x) => x).toList();

    // Deduplication Engine: Hash based on URL and Title
    final Map<String, NewsArticle> uniqueMap = {};
    for (var article in rawArticles) {
      final key = '${article.url}|${article.title}';
      if (!uniqueMap.containsKey(key)) {
        uniqueMap[key] = article;
      }
    }

    // AI Tagging (Intelligence Layer)
    final taggedArticles =
        await _aiTagger.tagArticles(uniqueMap.values.toList());

    return taggedArticles;
  }
}
