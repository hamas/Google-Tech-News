/// Represents the structured content extracted from a news article.
class ParsedArticle {
  final String title;
  final String author;
  final String? heroImageUrl;
  final List<ArticleElement> content;
  final String sourceUrl;
  final String markdown;

  const ParsedArticle({
    required this.title,
    required this.author,
    this.heroImageUrl,
    required this.content,
    required this.sourceUrl,
    required this.markdown,
  });
}

/// Base class for different types of content elements (Text, Image, etc.)
sealed class ArticleElement {}

/// Represents a block of text (paragraph, heading, quote).
class TextElement extends ArticleElement {
  final String text;
  final String style; // 'p', 'h1'-'h6', 'quote'

  TextElement(this.text, {this.style = 'p'});
}

/// Represents an image within the article body.
class ImageElement extends ArticleElement {
  final String imageUrl;
  final String? caption;

  ImageElement(this.imageUrl, {this.caption});
}
