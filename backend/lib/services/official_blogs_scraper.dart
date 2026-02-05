import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:core/models/news_article.dart';
import 'package:core/interfaces/feed_interface.dart';

class OfficialBlogsScraper implements FeedProvider {
  final Map<FeedSource, String> _feedUrls = {
    FeedSource.googleBlog: 'https://blog.google/rss/',
    FeedSource.androidDevelopers:
        'https://android-developers.googleblog.com/atom.xml',
    FeedSource.chromeOS: 'https://chromeos.dev/rss.xml', // Placeholder
    FeedSource.deepMind: 'https://deepmind.google/rss.xml', // Placeholder
  };

  @override
  String get sourceId => 'official_blogs';

  @override
  Future<List<NewsArticle>> fetchArticles() async {
    final List<NewsArticle> allArticles = [];

    for (var entry in _feedUrls.entries) {
      try {
        final articles = await _fetchFeed(entry.key, entry.value);
        allArticles.addAll(articles);
      } catch (e) {
        print('Failed to fetch ${entry.key}: $e');
      }
    }
    return allArticles;
  }

  Future<List<NewsArticle>> _fetchFeed(FeedSource source, String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) throw Exception('Failed to load feed');

    final document = XmlDocument.parse(response.body);
    final items = document.findAllElements('item'); // RSS
    final entries = document.findAllElements('entry'); // Atom

    final List<NewsArticle> articles = [];

    if (items.isNotEmpty) {
      for (var node in items) {
        articles.add(_parseRssItem(node, source));
      }
    } else if (entries.isNotEmpty) {
      for (var node in entries) {
        articles.add(_parseAtomEntry(node, source));
      }
    }

    return articles;
  }

  NewsArticle _parseRssItem(XmlElement node, FeedSource source) {
    return NewsArticle(
      id: node.findElements('guid').first.innerText,
      title: node.findElements('title').first.innerText,
      summary:
          node.findElements('description').first.innerText, // Needs cleaning
      url: node.findElements('link').first.innerText,
      source: source,
      publishedAt: _parseDate(node.findElements('pubDate').first.innerText),
      tags: [],
    );
  }

  NewsArticle _parseAtomEntry(XmlElement node, FeedSource source) {
    return NewsArticle(
      id: node.findElements('id').first.innerText,
      title: node.findElements('title').first.innerText,
      summary: node.findElements('summary').firstOrNull?.innerText ?? '',
      url: node.findElements('link').first.getAttribute('href') ?? '',
      source: source,
      publishedAt: DateTime.parse(node.findElements('updated').first.innerText),
      tags: [],
    );
  }

  DateTime _parseDate(String dateStr) {
    try {
      return HttpDate.parse(dateStr);
    } catch (_) {
      return DateTime.now(); // Fallback
    }
  }
}
