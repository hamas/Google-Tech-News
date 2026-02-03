import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/news_article.dart';
import '../providers/news_providers.dart';
import '../widgets/news_card.dart';

class SavedArticlesPage extends ConsumerWidget {
  final ScrollController? scrollController;

  const SavedArticlesPage({super.key, this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(bookmarksProvider);

    return bookmarksAsync.when(
      data: (articles) => CustomScrollView(
        controller: scrollController,
        slivers: buildSlivers(context, articles),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  static List<Widget> buildSlivers(
    BuildContext context,
    List<NewsArticle> articles,
  ) {
    if (articles.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bookmark_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'No saved articles yet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return [
      SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final article = articles[index];
          final totalCount = articles.length;

          BorderRadius radius;
          if (totalCount == 1) {
            radius = BorderRadius.circular(16);
          } else if (index == 0) {
            radius = const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(4),
            );
          } else if (index == totalCount - 1) {
            radius = const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            );
          } else {
            radius = BorderRadius.circular(4);
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1.0),
            child: NewsCard(article: article, borderRadius: radius),
          );
        }, childCount: articles.length),
      ),
    ];
  }
}
