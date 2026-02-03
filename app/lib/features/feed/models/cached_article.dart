import 'package:isar/isar.dart';
import 'package:core/models/news_article.dart';

part 'cached_article.g.dart';

@collection
class CachedArticle {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String articleId;

  late String title;
  late String summary;
  late String url;
  late String source; // Store as String (enum name)
  late DateTime publishedAt;
  String? imageUrl;
  List<String>? tags;

  /// Convert Core Model -> Cached Model
  static CachedArticle fromDomain(NewsArticle article) {
    return CachedArticle()
      ..articleId = article.id
      ..title = article.title
      ..summary = article.summary
      ..url = article.url
      ..source = article.source.name
      ..publishedAt = article.publishedAt
      ..imageUrl = article.imageUrl
      ..tags = article.tags;
  }

  /// Convert Cached Model -> Core Model
  NewsArticle toDomain() {
    return NewsArticle(
      id: articleId,
      title: title,
      summary: summary,
      url: url,
      source: FeedSource.values.firstWhere(
        (e) => e.name == source,
        orElse: () => FeedSource.other,
      ),
      publishedAt: publishedAt,
      imageUrl: imageUrl,
      tags: tags ?? [],
    );
  }
}
