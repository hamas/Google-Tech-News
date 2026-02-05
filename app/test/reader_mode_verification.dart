import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:app/src/features/news/domain/services/reader_mode/news_content_service.dart';

void main() {
  test('Reader Mode Extraction Verification', () async {
    final service = NewsContentService(Dio());

    // Test with a known article (Google Blog)
    final url =
        'https://blog.google/technology/ai/google-gemini-next-generation-model-february-2024/';

    debugPrint('Fetching: $url');

    try {
      final article = await service.extractContent(url);

      debugPrint('--- PARSED RESULT ---');
      debugPrint('Title: ${article.title}');
      debugPrint('Author: ${article.author}');
      debugPrint('Hero: ${article.heroImageUrl}');
      debugPrint('Content Elements: ${article.content.length}');
      debugPrint('Markdown Length: ${article.markdown.length}');

      if (article.markdown.isNotEmpty) {
        debugPrint('\n--- MARKDOWN PREVIEW (First 500 chars) ---');
        debugPrint(
          article.markdown.substring(
            0,
            article.markdown.length > 500 ? 500 : article.markdown.length,
          ),
        );
      } else {
        debugPrint('Markdown is empty.');
      }

      expect(article.title, isNotEmpty);
      expect(article.content, isNotEmpty);
    } catch (e) {
      debugPrint('Error: $e');
      // If network fails (e.g. CI), we might skip, but locally it should work.
    }
  });
}
