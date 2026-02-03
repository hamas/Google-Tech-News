import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animations/animations.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/news_article.dart';
import '../pages/article_detail_page.dart';
import '../../../../core/services/share_service.dart';
import '../../../../core/services/tagging_service.dart';
import '../../../../core/utils/news_utils.dart';
import '../providers/news_providers.dart';

class NewsCard extends ConsumerWidget {
  final NewsArticle article;
  final BorderRadius? borderRadius;

  const NewsCard({super.key, required this.article, this.borderRadius});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(12);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: OpenContainer(
        openBuilder: (context, _) =>
            ArticleDetailPage(articleId: article.id, article: article),
        closedElevation: 0,
        closedShape: RoundedRectangleBorder(borderRadius: effectiveRadius),
        closedColor: Theme.of(context).cardColor,
        // Material 3 Card style validation
        closedBuilder: (context, openContainer) => Card.filled(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: effectiveRadius),
          child: InkWell(
            onTap: openContainer,
            borderRadius: effectiveRadius,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          article.category,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onTertiaryContainer,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        DateFormat(
                          'h:mm a • MMM d',
                        ).format(article.publishedAt),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    article.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    () {
                      final words = article.summary.split(RegExp(r'\s+'));
                      if (words.length <= 80) return article.summary;
                      return '${words.take(80).join(' ')}...';
                    }(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: TaggingService.extractTags(article.title)
                              .take(4)
                              .map((tag) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '#$tag',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSecondaryContainer,
                                          fontSize: 10,
                                        ),
                                  ),
                                );
                              })
                              .toList(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${NewsUtils.calculateReadingTime(article.summary)} min read',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                  fontSize: 10,
                                ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            style: IconButton.styleFrom(
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              minimumSize: Size.zero,
                            ),
                            icon: Icon(
                              article.isBookmarked
                                  ? Icons.bookmark
                                  : Icons.bookmark_outline,
                              size: 18,
                              color: article.isBookmarked
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                            onPressed: () {
                              ref
                                  .read(newsRepositoryProvider)
                                  .toggleBookmark(article.id);
                            },
                            tooltip: 'Bookmark',
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            style: IconButton.styleFrom(
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              minimumSize: Size.zero,
                            ),
                            icon: const Icon(Icons.share_outlined, size: 18),
                            onPressed: () {
                              ShareService().shareArticle(
                                context,
                                article.title,
                                article.source,
                                article.id,
                                imageUrl: article.imageUrl,
                              );
                            },
                            tooltip: 'Share',
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
