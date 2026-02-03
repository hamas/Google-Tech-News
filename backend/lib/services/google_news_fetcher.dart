import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:core/models/news_article.dart';
import 'package:core/interfaces/feed_interface.dart';
import 'dart:io';

class GoogleNewsFetcher implements FeedProvider {
  final List<String> _keywords = [
    'Google Antigravity',
    'Gemini 3 Pro',
    'Nano Banana',
    'Android 17 leaks',
  ];

  @override
  String get sourceId => 'google_news_api';

  @override
  Future<List<NewsArticle>> fetchArticles() async {
    final List<NewsArticle> allArticles = [];

    for (var keyword in _keywords) {
      try {
        final articles = await _fetchNews(keyword);
        allArticles.addAll(articles);
      } catch (e) {
        print('Failed to fetch news for $keyword: $e');
      }
    }
    return allArticles;
  }

  Future<List<NewsArticle>> _fetchNews(String keyword) async {
    final url =
        'https://news.google.com/rss/search?q=${Uri.encodeComponent(keyword)}&hl=en-US&gl=US&ceid=US:en';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) throw Exception('Failed to load news');

    final document = XmlDocument.parse(response.body);
    final items = document.findAllElements('item');

    return items.map((node) {
      return NewsArticle(
        id: node.findElements('guid').first.innerText,
        title: node.findElements('title').first.innerText,
        summary: node.findElements('description').first.innerText,
        url: node.findElements('link').first.innerText,
        source: FeedSource.googleNewsApi,
        publishedAt: _parseDate(node.findElements('pubDate').first.innerText),
        tags: [keyword],
      );
    }).toList();
  }

  DateTime _parseDate(String dateStr) {
    try {
      return HttpDate.parse(dateStr);
    } catch (_) {
      return DateTime.now();
    }
  }
}
