import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'news_providers.dart';
import '../../../../core/services/tagging_service.dart';
import '../../domain/entities/news_article.dart';

/// The currently selected filter tag. Null means "All".
final activeFilterProvider = StateProvider<String?>((ref) => null);

/// Filtered list of news articles based on the selected tag.
final filteredNewsProvider = Provider<AsyncValue<List<NewsArticle>>>((ref) {
  final newsAsync = ref.watch(newsFeedProvider);
  final activeFilter = ref.watch(activeFilterProvider);

  if (activeFilter == null || activeFilter == 'All') {
    return newsAsync;
  }

  return newsAsync.whenData((List<NewsArticle> articles) {
    return articles.where((NewsArticle article) {
      if (article.source == activeFilter) return true;

      final filterLower = activeFilter.toLowerCase();

      // Fallback 1: Source Keyword
      if (article.source.toLowerCase().contains(filterLower)) return true;

      // Fallback 2: Category Match
      if (article.category.toLowerCase() == filterLower) return true;

      // Fallback 3: Smart Tag extraction from title
      final tags = TaggingService.extractTags(
        article.title,
      ).map((e) => e.toLowerCase());
      if (tags.contains(filterLower)) return true;

      // Fallback 4: Direct keyword check in title
      if (article.title.toLowerCase().contains(filterLower)) return true;

      return false;
    }).toList();
  });
});
