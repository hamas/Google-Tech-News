import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';

class NewsScraperService {
  final Dio _dio;
  NewsScraperService(this._dio);

  /// Fetches and extracts clean content from a URL, with option to skip a specific image (e.g. feature image)
  Future<List<Map<String, String>>> scrape(String url,
      {String? skipImageUrl}) async {
    try {
      final response = await _dio.get<String>(
        url,
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          },
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        return await compute(_parseHtmlThread, {
          'html': response.data!,
          'skipImageUrl': skipImageUrl,
        });
      } else {
        throw Exception('Failed to load page: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Scraper Error: $e');
      rethrow; // Rethrow to let UI handle it
    }
  }
}

/// Isolate function for heavy HTML parsing
List<Map<String, String>> _parseHtmlThread(Map<String, dynamic> args) {
  final String html = args['html'] as String;
  final String? skipImageUrl = args['skipImageUrl'] as String?;

  final document = parser.parse(html);
  final blocks = <Map<String, String>>[];

  // 1. Density Heuristic for Content Extraction
  Element? contentNode;

  // High priority tags
  contentNode = document.querySelector('article') ??
      document.querySelector('main') ??
      document.querySelector('[role="main"]');

  if (contentNode == null) {
    // Highest density <p> tag container logic
    int maxDensity = 0;
    document.querySelectorAll('div, section').forEach((node) {
      final pCount = node.querySelectorAll('p').length;
      if (pCount > maxDensity) {
        maxDensity = pCount;
        contentNode = node;
      }
    });
  }

  contentNode ??= document.body;
  if (contentNode == null) return [];

  // 2. Cleanup: Strip noise
  contentNode!
      .querySelectorAll(
          'script, style, nav, header, footer, aside, iframe, ins, ad, .advertisement')
      .forEach((e) => e.remove());

  // 3. Extraction: Convert to list of objects
  void extract(Element node) {
    for (var child in node.children) {
      final tag = child.localName;

      if (tag == 'p') {
        final text = child.text.trim();
        if (text.isNotEmpty) {
          blocks.add({'type': 'text', 'value': text});
        }
      } else if (tag == 'img') {
        final src = child.attributes['src'];
        if (src != null &&
            !src.contains('spinner') &&
            !src.contains('icon') &&
            (skipImageUrl == null || !src.contains(skipImageUrl))) {
          blocks.add({'type': 'image', 'url': src});
        }
      } else if (child.children.isNotEmpty) {
        // Deep dive for nested content
        extract(child);
      } else if (['h1', 'h2', 'h3', 'h4'].contains(tag)) {
        final text = child.text.trim();
        if (text.isNotEmpty) {
          blocks.add({'type': 'text', 'value': text});
        }
      }
    }
  }

  extract(contentNode!);

  return blocks;
}
