import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:core/models/news_article.dart';
import '../services/local_news_service.dart';

final localNewsService = LocalNewsService();

final feedProvider = FutureProvider<List<NewsArticle>>((ref) async {
  try {
    // 1. Try fetching from network
    // For Windows development, localhost works if backend is running locally.
    final response = await http
        .get(Uri.parse('http://localhost:8080/news'))
        .timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> articlesJson = data['articles'] as List<dynamic>;
      final articles = articlesJson
          .map((json) => NewsArticle.fromJson(json as Map<String, dynamic>))
          .toList();

      // 2. Save to cache
      await localNewsService.saveArticles(articles);

      return articles;
    } else {
      throw Exception('Failed to load news');
    }
  } catch (e) {
    // 3. Fallback to cache
    debugPrint('Network error: $e. Falling back to cache.');
    final cached = await localNewsService.getArticles();
    if (cached.isNotEmpty) {
      return cached;
    }
    // Re-throw if cache is also empty so UI shows error
    rethrow;
  }
});
