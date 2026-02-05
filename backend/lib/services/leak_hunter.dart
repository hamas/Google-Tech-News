import 'package:core/models/news_article.dart';
import 'package:core/interfaces/feed_interface.dart';

class LeakHunter implements FeedProvider {
  final List<String> _keywords = [
    'Aluminium OS',
    'Chrome OS Flex',
  ];

  @override
  String get sourceId => 'leak_hunter';

  @override
  Future<List<NewsArticle>> fetchArticles() async {
    final List<NewsArticle> allArticles = [];

    for (var keyword in _keywords) {
      try {
        // Simulation
        allArticles.addAll(_simulateLeakDetection(keyword));
      } catch (e) {
        print('LeakHunter failed for $keyword: $e');
      }
    }
    return allArticles;
  }

  List<NewsArticle> _simulateLeakDetection(String keyword) {
    return [
      NewsArticle(
        id: 'leak_${keyword.hashCode}_1',
        title: 'Potential $keyword reference in commit 12345',
        summary: 'Found a reference to $keyword in the latest commit logs.',
        url: 'https://issues.chromium.org/issues/12345',
        source: FeedSource.issueTracker,
        publishedAt: DateTime.now().subtract(Duration(hours: 2)),
        tags: ['Leak', keyword],
      ),
    ];
  }
}
