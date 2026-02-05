import 'package:xml/xml.dart';
import '../../domain/entities/news_article.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../../../core/services/monitoring_service.dart';

class DlpRssParser {
  /// Parses RSS/Atom XML string into NewsArticle list
  List<NewsArticle> parse(String xmlBody, String defaultSource) {
    try {
      final document = XmlDocument.parse(xmlBody);
      final articles = <NewsArticle>[];

      // Detect RSS version
      final rss = document.findAllElements('rss').firstOrNull;
      final rdf = document.findAllElements('rdf:RDF').firstOrNull;
      final atom = document.findAllElements('feed').firstOrNull;

      if (rss != null || rdf != null) {
        // RSS 2.0 or 1.0
        final items = document.findAllElements('item');
        for (var item in items) {
          try {
            articles.add(_parseRssItem(item, defaultSource));
          } catch (e) {
            continue;
          }
        }
      } else if (atom != null) {
        // Atom
        final entries = document.findAllElements('entry');
        for (var entry in entries) {
          try {
            articles.add(_parseAtomEntry(entry, defaultSource));
          } catch (e) {
            continue;
          }
        }
      }

      return articles;
    } catch (e, s) {
      MonitoringService().logError('RSS Parse Failure: $e', s);
      return [];
    }
  }

  NewsArticle _parseRssItem(XmlElement item, String source) {
    final title = item.findAllElements('title').first.innerText;
    final link = item.findAllElements('link').first.innerText;
    final description =
        item.findAllElements('description').firstOrNull?.innerText ?? '';
    final content =
        item.findAllElements('content:encoded').firstOrNull?.innerText ??
            description;

    final pubDateStr = item.findAllElements('pubDate').firstOrNull?.innerText ??
        item.findAllElements('dc:date').firstOrNull?.innerText;
    DateTime pubDate = DateTime.now();
    if (pubDateStr != null) {
      try {
        pubDate = _parseDate(pubDateStr);
      } catch (_) {}
    }

    final category = source;

    // Multi-Tier Image Extraction
    final imageUrl = _extractImageUrl(item, description + content);

    return NewsArticle(
      id: _generateId(link),
      title: _cleanText(title),
      summary: _cleanText(description).isEmpty
          ? (_cleanText(content).length > 200
              ? _cleanText(content).substring(0, 200)
              : _cleanText(content))
          : _cleanText(description),
      url: link,
      publishedAt: pubDate,
      source: source,
      category: category,
      imageUrl: imageUrl,
      isBreaking: _isBreaking(title, description + content),
    );
  }

  NewsArticle _parseAtomEntry(XmlElement entry, String source) {
    final title = entry.findAllElements('title').first.innerText;
    final link = entry
        .findAllElements('link')
        .firstWhere(
          (e) =>
              e.getAttribute('rel') != 'self' &&
              e.getAttribute('rel') != 'edit',
          orElse: () => entry.findAllElements('link').first,
        )
        .getAttribute('href')!;

    final summary = entry.findAllElements('summary').firstOrNull?.innerText;
    final content =
        entry.findAllElements('content').firstOrNull?.innerText ?? '';

    final updated = entry.findAllElements('updated').first.innerText;
    final published =
        entry.findAllElements('published').firstOrNull?.innerText ?? updated;

    final DateTime pubDate = DateTime.parse(published);

    final category = source;

    // Multi-Tier Image Extraction
    final imageUrl = _extractImageUrl(
      entry,
      content.isEmpty ? (summary ?? '') : content,
    );

    return NewsArticle(
      id: _generateId(link),
      title: _cleanText(title),
      summary: _cleanText(summary ?? content).isEmpty
          ? _cleanText(content).substring(0, 100)
          : _cleanText(summary ?? content),
      url: link,
      publishedAt: pubDate,
      source: source,
      category: category,
      imageUrl: imageUrl,
      isBreaking: _isBreaking(title, summary ?? content),
    );
  }

  /// Multi-tier image extraction logic
  String? _extractImageUrl(XmlElement element, String htmlContent) {
    // Helper to find all elements by local name (ignoring namespace)
    Iterable<XmlElement> findAllLocal(String localName) {
      try {
        return element.descendants.whereType<XmlElement>().where(
              (e) => e.name.local == localName,
            );
      } catch (_) {
        return const [];
      }
    }

    // Tier 1: Media Metadata (Standard for Google Blogs)
    // We look for tags named 'content' or 'thumbnail' that specifically carry a URL
    // We check ALL candidates, not just the first one.
    final mediaContents = findAllLocal('content');
    for (final node in mediaContents) {
      final url = node.getAttribute('url') ?? node.getAttribute('href');
      if (url != null && _isImageUrl(url)) return url;
    }

    final mediaThumbnails = findAllLocal('thumbnail');
    for (final node in mediaThumbnails) {
      final url = node.getAttribute('url') ?? node.getAttribute('href');
      if (url != null && _isImageUrl(url)) return url;
    }

    // Tier 2: Enclosures (Common in RSS)
    final enclosures = findAllLocal('enclosure');
    for (final node in enclosures) {
      final url = node.getAttribute('url') ?? node.getAttribute('href');
      if (url != null && _isImageUrl(url)) return url;
    }

    // Tier 3: Atom Specific Link Rel="enclosure"
    try {
      final links = element.findAllElements('link');
      for (final link in links) {
        if (link.getAttribute('rel') == 'enclosure') {
          final url = link.getAttribute('href');
          if (url != null && _isImageUrl(url)) return url;
        }
      }
    } catch (_) {}

    // Tier 4: Regex Scrape from HTML (the "Last Resort")
    // We extract the first <img> tag from either description or content
    // We check for both literal <img and escaped &lt;img
    final imgRegex = RegExp(
      r'(?:<img|&lt;img)[^>]+src\s*=\s*(?:["'
      "'"
      r']|&quot;)([^"'
      "'"
      r'& ]+)(?:["'
      "'"
      r']|&quot;)',
      caseSensitive: false,
    );

    final match = imgRegex.firstMatch(htmlContent);
    if (match != null) {
      final url = match.group(1);
      if (url != null && _isImageUrl(url)) return url;
    }

    return null;
  }

  bool _isImageUrl(String url) {
    if (url.isEmpty) return false;
    final lower = url.toLowerCase();

    // Explicit image extensions
    if (lower.contains('.jpg') ||
        lower.contains('.jpeg') ||
        lower.contains('.png') ||
        lower.contains('.webp') ||
        lower.contains('.gif')) {
      return true;
    }

    // Common CDN/Image service patterns
    if (lower.contains('googleusercontent.com') ||
        lower.contains('bp.blogspot.com') ||
        lower.contains('medium.com/max') ||
        lower.contains('/images/') ||
        lower.contains('/img/')) {
      return true;
    }

    // Basic validity check for remaining URLs
    return lower.startsWith('http');
  }

  /// Static parse for Use with compute()
  static List<NewsArticle> parseXml(Map<String, String> data) {
    final body = data['body']!;
    final source = data['source']!;
    return DlpRssParser().parse(body, source);
  }

  bool _isBreaking(String title, String content) {
    final keywords = [
      'Emergency',
      'Stable Release',
      'v3.0',
      'Aluminium',
      'Gemini 1.5',
      'Quantum',
      'Pixel 10',
    ];
    final text = '$title $content'.toLowerCase();
    return keywords.any((k) => text.contains(k.toLowerCase()));
  }

  DateTime _parseDate(String dateStr) {
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return DateTime.now();
    }
  }

  String _cleanText(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  String _generateId(String url) {
    return md5.convert(utf8.encode(url)).toString();
  }
}
