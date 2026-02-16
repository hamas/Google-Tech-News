import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/news_providers.dart';
import '../widgets/news_card.dart';
import '../../domain/entities/news_article.dart';

class SavedArticlesPage extends ConsumerWidget {
  const SavedArticlesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync =
        ref.watch<AsyncValue<List<NewsArticle>>>(bookmarksProvider);

    return Scaffold(
      body: bookmarksAsync.when(
        data: (articles) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                snap: true,
                title: const Text('Saved Articles'),
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                surfaceTintColor: Colors.transparent,
              ),
              ...SavedArticlesPage.buildSlivers(context, articles),
            ],
          );
        },
        error: (err, stack) => Center(child: Text('Error: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  static List<Widget> buildSlivers(
    BuildContext context,
    List<NewsArticle> articles,
  ) {
    if (articles.isEmpty) {
      return [
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bookmark_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'No saved articles yet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final article = articles[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: NewsCard(
                article: article,
                borderRadius: BorderRadius.circular(12),
              ).animate().fadeIn().slideX(begin: 0.1, end: 0),
            );
          }, childCount: articles.length),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 80)), // Bottom padding
    ];
  }
}
