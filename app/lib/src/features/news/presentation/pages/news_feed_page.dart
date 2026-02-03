import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/news_providers.dart';
import '../providers/filter_providers.dart';
import '../widgets/news_card.dart';
import '../widgets/news_filter_bar.dart';
import '../../../../core/services/tagging_service.dart';

import '../../domain/entities/news_article.dart';

class NewsFeedPage extends ConsumerWidget {
  final ScrollController? scrollController;

  const NewsFeedPage({super.key, this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(newsFeedProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Offline mode: Showing cached news. Error: ${next.error}',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    final newsAsync = ref.watch(newsFeedProvider);

    return newsAsync.when(
      data: (articles) => CustomScrollView(
        controller: scrollController,
        slivers: buildSlivers(context, ref, articles),
      ),
      error: (err, stack) => _buildError(ref, err),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  static List<Widget> buildSlivers(
    BuildContext context,
    WidgetRef ref,
    List<NewsArticle> articles,
  ) {
    final activeFilter = ref.watch(activeFilterProvider);

    // Featured exclusively shows Google DeepMind articles
    final featured = articles
        .where((a) => a.source == 'Google DeepMind' && a.imageUrl != null)
        .take(6)
        .toList();

    // Fallback: If no DeepMind articles with images, show latest breaking news
    if (featured.isEmpty) {
      featured.addAll(articles.where((a) => a.isBreaking).take(3));
    }
    if (featured.isEmpty && articles.isNotEmpty) {
      featured.add(articles.first);
    }

    // Standard list is filtered
    var standard = articles.where((a) => !featured.contains(a)).toList();

    if (activeFilter != null && activeFilter != 'All') {
      standard = standard.where((article) {
        // Priority 1: Exact Source Match (Synchronized with chips)
        if (article.source == activeFilter) return true;

        final filterLower = activeFilter.toLowerCase();

        // Fallback 1: Source keyword
        if (article.source.toLowerCase().contains(filterLower)) return true;

        // Fallback 2: Tag Extraction (Metadata)
        final tags = TaggingService.extractTags(
          article.title,
        ).map((e) => e.toLowerCase());
        if (tags.contains(filterLower)) return true;

        // Fallback 3: Title Keyword
        if (article.title.toLowerCase().contains(filterLower)) return true;

        return false;
      }).toList();
    }

    return [
      if (featured.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: SizedBox(
              height: 240,
              child:
                  CarouselView(
                        itemExtent: 320,
                        itemSnapping: true,
                        children: featured.map((article) {
                          return GestureDetector(
                            onTap: () async {
                              final uri = Uri.parse(article.url);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                              ),
                              child: Stack(
                                children: [
                                  if (article.imageUrl != null)
                                    Positioned.fill(
                                      child: CachedNetworkImage(
                                        imageUrl: article.imageUrl!,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            Container(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                            ),
                                        errorWidget: (context, url, error) =>
                                            Container(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primaryContainer,
                                            ),
                                      ),
                                    ),
                                  // Premium Gradient Overlay
                                  Positioned.fill(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withValues(alpha: 0.1),
                                            Colors.black.withValues(alpha: 0.7),
                                          ],
                                          stops: const [0.0, 0.4, 1.0],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Align(
                                      alignment: Alignment.bottomLeft,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            article.source,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium
                                                ?.copyWith(
                                                  color: Colors.white70,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            article.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
            ),
          ),
        ),
      const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(top: 0, bottom: 8.0),
          child: NewsFilterBar(),
        ),
      ),
      SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final article = standard[index];
          final totalCount = standard.length;

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
            child: NewsCard(article: article, borderRadius: radius)
                .animate(delay: (50 * index).ms)
                .fadeIn(duration: 400.ms)
                .slideX(begin: 0.1, end: 0),
          );
        }, childCount: standard.length),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 120)),
    ];
  }

  Widget _buildError(WidgetRef ref, Object err) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.red),
        const SizedBox(height: 16),
        Text('Unable to load feed.\n$err', textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => ref.refresh(newsFeedProvider),
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    ),
  );
}
