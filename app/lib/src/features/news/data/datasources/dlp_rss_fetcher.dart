import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../domain/entities/news_article.dart';
import '../../../../core/constants/news_sources.dart';
import 'dlp_rss_parser.dart';
import '../../../../core/services/health_service.dart';
import '../../../../core/services/monitoring_service.dart';

class DlpRssFetcher {
  final Dio _dio;

  DlpRssFetcher(this._dio);

  Future<List<NewsArticle>> fetchAll({
    Map<String, String>? extraSources,
  }) async {
    final allArticles = <NewsArticle>[];

    final sources = Map<String, String>.from(NewsSources.feeds);
    if (extraSources != null) {
      sources.addAll(extraSources);
    }

    await Future.wait(
      sources.entries.map((entry) async {
        try {
          final response = await _dio.get<String>(
            entry.value,
            options: Options(responseType: ResponseType.plain),
          );
          if (response.statusCode == 200) {
            final articles = await compute(DlpRssParser.parseXml, {
              'body': response.data.toString(),
              'source': entry.key,
            });
            allArticles.addAll(articles);
          }
        } catch (e) {
          // Log error but continue fetching other feeds
          await SystemHealthService().logFetchFailure(entry.key, e.toString());
          await MonitoringService().logError(e, null);
        }
      }),
    );

    // Sort by date desc
    allArticles.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return allArticles;
  }
}
