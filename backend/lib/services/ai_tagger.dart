import 'package:core/models/news_article.dart';

class AiTagger {
  // In a real app, this would be an API key from environment variables.
  // final String _apiKey = 'YOUR_GEMINI_API_KEY';

  Future<NewsArticle> tagArticle(NewsArticle article) async {
    try {
      // Simulate network delay for Gemini 3 Flash API
      await Future.delayed(Duration(milliseconds: 100));

      // Mock AI Logic: Assign tags based on keywords in title/summary
      final newTags = List<String>.from(article.tags);
      final text = '${article.title} ${article.summary}'.toLowerCase();

      if (text.contains('android')) newTags.add('Android');
      if (text.contains('pixel')) newTags.add('Hardware');
      if (text.contains('gemini') || text.contains('ai'))
        newTags.add('Generative AI');
      if (text.contains('chrome') || text.contains('browser'))
        newTags.add('Chrome');
      if (text.contains('security') || text.contains('leak'))
        newTags.add('Security');
      if (text.contains('fuschia') ||
          text.contains('aluminium') ||
          text.contains('os')) newTags.add('Operating Systems');

      // Return a new article with updated tags (immutability preferred)
      return NewsArticle(
        id: article.id,
        title: article.title,
        summary: article.summary,
        url: article.url,
        source: article.source,
        publishedAt: article.publishedAt,
        imageUrl: article.imageUrl,
        tags: newTags.toSet().toList(), // Deduplicate tags
      );
    } catch (e) {
      print('AI Tagging failed for ${article.id}: $e');
      return article; // Return original if failure
    }
  }

  Future<List<NewsArticle>> tagArticles(List<NewsArticle> articles) async {
    // Gemini 3 Flash is fast, but we might want to batch requests in a real scenario.
    // For now, simple parallelism.
    final futures = articles.map((a) => tagArticle(a));
    return Future.wait(futures);
  }
}
