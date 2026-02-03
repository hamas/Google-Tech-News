import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../features/news/presentation/pages/news_shell_page.dart';
import '../../features/news/presentation/pages/article_detail_page.dart';
import '../../features/news/domain/entities/news_article.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const NewsShellPage(),
      routes: [
        GoRoute(
          path: 'article/:id',
          builder: (context, state) {
            final articleId = state.pathParameters['id']!;
            final article = state.extra as NewsArticle?;
            return ArticleDetailPage(articleId: articleId, article: article);
          },
        ),
      ],
    ),
  ],
);
