import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';
import '../../models/parsed_article.dart';

class NewsContentService {
  final Dio _dio;
  NewsContentService(this._dio);

  Future<ParsedArticle> extractContent(String url) async {
    try {
      final response = await _dio.get<String>(
        url,
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          },
        ),
      );

      if (response.statusCode == 200) {
        return await compute(
            _parseHtml, {'html': response.data ?? '', 'url': url});
      } else {
        throw ParsingException(
          'Failed to load page. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is ParsingException) rethrow;
      throw ParsingException('Error fetching url: $e');
    }
  }
}

/// Parsing Exception
class ParsingException implements Exception {
  final String message;
  ParsingException(this.message);
  @override
  String toString() => message;
}

// --- ISOALTE FUNCTION (Must be top-level or static) ---

ParsedArticle _parseHtml(Map<String, String> args) {
  final htmlString = args['html']!;
  final sourceUrl = args['url']!;
  final document = parser.parse(htmlString);

  // 1. Title Extraction
  String title = '';
  final ogTitle = document
      .querySelector('meta[property="og:title"]')
      ?.attributes['content'];
  if (ogTitle != null && ogTitle.isNotEmpty) {
    title = ogTitle;
  }
  if (title.isEmpty) {
    title = document.querySelector('title')?.text ?? '';
  }
  if (title.isEmpty) {
    title = document.querySelector('h1')?.text ?? 'No Title';
  }

  // 2. Author Extraction
  String author = 'Unknown Author';
  final metaAuthor =
      document.querySelector('meta[name="author"]')?.attributes['content'];
  if (metaAuthor != null) {
    author = metaAuthor;
  } else {
    // Try heuristics
    final authorLink = document.querySelector(
      'a[href*="author"], .author, .byline',
    );
    if (authorLink != null) {
      author = authorLink.text.trim();
    }
  }

  // 3. Hero Image
  String? heroImage;
  final ogImage = document
      .querySelector('meta[property="og:image"]')
      ?.attributes['content'];
  if (ogImage != null) {
    heroImage = ogImage;
  }

  // 4. Body Extraction (Heuristics)
  Element? contentNode;

  // Strategy A: <article> tag
  contentNode = document.querySelector('article');

  // Strategy B: Role="main" or <main>
  contentNode ??=
      document.querySelector('main') ?? document.querySelector('[role="main"]');

  // Strategy C: Div with specific class names
  if (contentNode == null) {
    final possibleBundles = document.querySelectorAll('div');
    int maxScore = 0;

    for (var div in possibleBundles) {
      int score = 0;
      final className = div.className.toLowerCase();
      final id = div.id.toLowerCase();

      if (className.contains('content')) score += 5;
      if (className.contains('article')) score += 5;
      if (className.contains('body')) score += 3;
      if (className.contains('post')) score += 3;
      if (id.contains('content')) score += 5;

      // Penalty/Sanity check: Must have P tags
      final pCount = div.querySelectorAll('p').length;
      if (pCount < 3) {
        score -= 10;
      } else {
        score += pCount; // More paragraphs = likely content
      }

      if (score > maxScore) {
        maxScore = score;
        contentNode = div;
      }
    }
  }

  contentNode ??= document.body;

  if (contentNode == null) {
    throw ParsingException('Could not determine content area');
  }

  // 5. Cleanup
  // Remove scripts, styles, navs, ads
  contentNode
      .querySelectorAll(
        'script, style, nav, header, footer, aside, iframe, .ad, .advertisement, .social-share',
      )
      .forEach((element) => element.remove());

  // 6. Traverse and build output
  final List<ArticleElement> elements = [];
  final StringBuffer markdownBuffer = StringBuffer();

  // Heading logic for Markdown
  markdownBuffer.writeln('# $title\n');
  if (heroImage != null) {
    markdownBuffer.writeln('![$title]($heroImage)\n');
  }

  void traverse(Element node) {
    for (var child in node.children) {
      final tag = child.localName;

      if (['p', 'div', 'section'].contains(tag)) {
        if (child.children.isNotEmpty &&
            ![
              'p',
              'h1',
              'h2',
              'h3',
              'h4',
              'h5',
              'h6',
              'ul',
              'ol',
              'img',
            ].contains(tag)) {
          traverse(child);
        } else {
          final text = child.text.trim();
          if (text.isNotEmpty) {
            elements.add(TextElement(text, style: 'p'));
            markdownBuffer.writeln('$text\n');
          }
          for (var img in child.querySelectorAll('img')) {
            final src = img.attributes['src'];
            if (src != null) {
              if (!src.contains('icon') && !src.contains('logo')) {
                elements.add(ImageElement(src));
                markdownBuffer.writeln('![]($src)\n');
              }
            }
          }
        }
      } else if (['h1', 'h2', 'h3', 'h4', 'h5', 'h6'].contains(tag)) {
        final text = child.text.trim();
        if (text.isNotEmpty) {
          elements.add(TextElement(text, style: tag!));
          final level = tag.substring(1);
          markdownBuffer.writeln('${"#" * int.parse(level)} $text\n');
        }
      } else if (tag == 'ul' || tag == 'ol') {
        for (var li in child.children) {
          if (li.localName == 'li') {
            final text = li.text.trim();
            if (text.isNotEmpty) {
              elements.add(TextElement('• $text', style: 'p'));
              markdownBuffer.writeln('- $text');
            }
          }
        }
        markdownBuffer.writeln();
      } else if (tag == 'img') {
        final src = child.attributes['src'];
        if (src != null) {
          if (!src.contains('icon') && !src.contains('logo')) {
            elements.add(ImageElement(src));
            markdownBuffer.writeln('![]($src)\n');
          }
        }
      } else if (tag == 'blockquote') {
        final text = child.text.trim();
        if (text.isNotEmpty) {
          elements.add(TextElement(text, style: 'quote'));
          markdownBuffer.writeln('> $text\n');
        }
      }
    }
  }

  traverse(contentNode);

  if (elements.isEmpty) {
    throw ParsingException('Content parsing yielded zero elements.');
  }

  return ParsedArticle(
    title: title,
    author: author,
    heroImageUrl: heroImage,
    content: elements,
    sourceUrl: sourceUrl,
    markdown: markdownBuffer.toString(),
  );
}
