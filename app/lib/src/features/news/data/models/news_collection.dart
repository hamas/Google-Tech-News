import 'package:isar/isar.dart';
import '../../domain/entities/news_article.dart';

part 'news_collection.g.dart';

@collection
class NewsCollection {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String articleId; // Maps to NewsArticle.id (url hash or guid)

  late String title;
  late String summary; // Maps to summary usually, but schema field is content
  late String url;
  late String? imageUrl;
  late DateTime publishedAt;
  late String source;
  late String category;
  late bool isBreaking;

  @Index()
  late bool isBookmarked = false;

  /// Convert Domain Entity to Isar Collection
  static NewsCollection fromDomain(NewsArticle article) {
    return NewsCollection()
      ..articleId = article.id
      ..title = article.title
      ..summary = article.summary
      ..url = article.url
      ..imageUrl = article.imageUrl
      ..publishedAt = article.publishedAt
      ..source = article.source
      ..category = article.category
      ..isBreaking = article.isBreaking
      ..isBookmarked = article.isBookmarked;
  }

  /// Convert to Domain Entity
  NewsArticle toDomain() {
    return NewsArticle(
      id: articleId,
      title: title,
      summary: summary,
      url: url,
      imageUrl: imageUrl,
      publishedAt: publishedAt,
      source: source,
      category: category,
      isBreaking: isBreaking,
      isBookmarked: isBookmarked,
    );
  }
}

@collection
class AppMetadata {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String key;
  late String value; // We'll store ISO strings here for simplicity
}
