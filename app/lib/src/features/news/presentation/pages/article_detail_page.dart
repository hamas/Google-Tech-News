import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/news_providers.dart';
import '../../../../../core/services/tts_service.dart';
import '../../domain/entities/news_article.dart';
import '../../domain/models/parsed_article.dart';
import '../../../../core/services/tagging_service.dart';
import 'package:intl/intl.dart';
import '../widgets/share/share_editor.dart';

class ArticleDetailPage extends ConsumerStatefulWidget {
  final String articleId;
  final NewsArticle? article;

  const ArticleDetailPage({super.key, required this.articleId, this.article});

  @override
  ConsumerState<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends ConsumerState<ArticleDetailPage> {
  Future<ParsedArticle>? _articleFuture;

  @override
  void initState() {
    super.initState();
    _articleFuture = _getParsedArticle();
  }

  Future<ParsedArticle> _getParsedArticle() async {
    if (widget.article == null) {
      throw Exception('Article data missing');
    }

    final repository = ref.read(newsRepositoryProvider);

    // 1. Check local cache
    try {
      final cachedContent =
          await repository.getFullContent(widget.article!.localId!);
      if (cachedContent != null) {
        final List<dynamic> blocks = jsonDecode(cachedContent) as List<dynamic>;
        return _blocksToParsed(blocks.cast<Map<String, dynamic>>());
      }
    } catch (e) {
      debugPrint('Cache Load Error: $e');
    }

    // 2. Scrape from Web
    final scraper = ref.read(newsScraperServiceProvider);
    try {
      final blocks = await scraper
          .scrape(widget.article!.url, skipImageUrl: widget.article!.imageUrl)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException('Scraping timed out'),
          );

      if (blocks.isNotEmpty) {
        await repository.saveFullContent(
          widget.article!.localId!,
          jsonEncode(blocks),
        );
      } else {
        throw Exception('Reader Mode: No content extracted from this article.');
      }
      return _blocksToParsed(blocks.cast<Map<String, dynamic>>());
    } catch (e) {
      debugPrint('Scrape Error: $e');
      rethrow;
    }
  }

  ParsedArticle _blocksToParsed(List<Map<String, dynamic>> rawBlocks) {
    final blocks = List<Map<String, dynamic>>.from(rawBlocks);

    // Filter out duplicate feature image within content
    if (widget.article?.imageUrl != null && blocks.isNotEmpty) {
      final firstBlock = blocks.first;
      if (firstBlock['type'] == 'image') {
        final url = firstBlock['url'] as String;
        final featureUrl = widget.article!.imageUrl!;

        // Normalize URLs for comparison (ignore query params)
        final cleanUrl = url.split('?').first;
        final cleanFeature = featureUrl.split('?').first;

        if (cleanUrl == cleanFeature ||
            cleanFeature.contains(cleanUrl) ||
            cleanUrl.contains(cleanFeature)) {
          blocks.removeAt(0);
        }
      }
    }

    final elements = blocks.map((b) {
      final type = b['type'] as String;
      if (type == 'image') {
        return ImageElement(b['url'] as String);
      } else {
        return TextElement(b['value'] as String);
      }
    }).toList();

    final markdown = blocks.map((b) {
      final type = b['type'] as String;
      if (type == 'image') return '![](${b['url']})';
      return b['value'] as String;
    }).join('\n\n');

    return ParsedArticle(
      title: widget.article!.title,
      author: widget.article!.source,
      content: elements,
      sourceUrl: widget.article!.url,
      markdown: markdown,
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.article?.url ?? 'https://blog.google';

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                snap: true,
                titleSpacing: 0,
                leading: const BackButton(),
                title: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Color.alphaBlend(
                              Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.12),
                              Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                            )
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Center(
                      child: Text(
                        'Search News',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontWeight: FontWeight.w400,
                              fontSize: 15,
                            ),
                      ),
                    ),
                  ),
                ),
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                elevation: 0,
                scrolledUnderElevation: 0,
                surfaceTintColor: Colors.transparent,
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).brightness == Brightness.dark
                                ? HSLColor.fromColor(
                                    Theme.of(context).colorScheme.primary,
                                  ).withLightness(0.74).toColor()
                                : HSLColor.fromColor(
                                    Theme.of(context).colorScheme.primary,
                                  ).withLightness(0.65).toColor(),
                        foregroundColor: Theme.of(context).colorScheme.surface,
                      ),
                      icon: const Icon(Icons.headphones, size: 20),
                      onPressed: () {
                        if (widget.article != null) {
                          final text = widget.article!.summary.isNotEmpty
                              ? widget.article!.summary
                              : widget.article!.title;
                          ref
                              .read<TtsService>(ttsServiceProvider.notifier)
                              .speak(text);
                        }
                      },
                    ),
                  ),
                ],
              ),
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                sliver: SliverToBoxAdapter(
                  child: widget.article == null
                      ? const Center(child: Text('Article not found'))
                      : FutureBuilder<ParsedArticle>(
                          future: _articleFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                    ConnectionState.waiting ||
                                snapshot.connectionState ==
                                    ConnectionState.none) {
                              return const SizedBox(
                                height: 400,
                                child:
                                    Center(child: CircularProgressIndicator()),
                              );
                            } else if (snapshot.hasError) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.error_outline,
                                          size: 48, color: Colors.red),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Could not load reader mode',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        snapshot.error.toString(),
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                      const SizedBox(height: 24),
                                      FilledButton.icon(
                                        onPressed: () {
                                          final uri = Uri.parse(url);
                                          launchUrl(uri,
                                              mode: LaunchMode
                                                  .externalApplication);
                                        },
                                        icon: const Icon(Icons.open_in_browser),
                                        label: const Text('Open in Browser'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            _articleFuture =
                                                _getParsedArticle();
                                          });
                                        },
                                        child: const Text('Retry'),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            } else if (snapshot.hasData) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.article!.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          height: 1.3,
                                        ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Left Column: Time & Read Time
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            DateFormat('MMM d').format(
                                                widget.article!.publishedAt),
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            DateFormat('h:mm a').format(
                                                widget.article!.publishedAt),
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .outline,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${(widget.article!.summary.split(' ').length / 200).ceil()} min read',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .outline,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 16),
                                      // Right Column: Source & Tags
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .tertiaryContainer,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                widget.article!.source,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelMedium
                                                    ?.copyWith(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onTertiaryContainer,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Wrap(
                                              spacing: 4,
                                              runSpacing: 4,
                                              children:
                                                  TaggingService.extractTags(
                                                          widget.article!.title)
                                                      .take(5)
                                                      .map((tag) {
                                                return Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .outlineVariant,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: Text(
                                                    '#$tag',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .labelSmall
                                                        ?.copyWith(
                                                          color: Theme.of(
                                                                  context)
                                                              .colorScheme
                                                              .onSurfaceVariant,
                                                        ),
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  // Action Button Group (Scrollable Row)
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        FilledButton.tonalIcon(
                                          onPressed: () async {
                                            if (widget.article != null) {
                                              await showModalBottomSheet<void>(
                                                context: context,
                                                isScrollControlled: true,
                                                backgroundColor:
                                                    Colors.transparent,
                                                builder: (context) =>
                                                    ShareEditor(
                                                        article:
                                                            widget.article!),
                                              );
                                            }
                                          },
                                          icon: const Icon(Icons.ios_share,
                                              size: 18),
                                          label: const Text('Story'),
                                        ),
                                        const SizedBox(width: 8),
                                        OutlinedButton.icon(
                                          onPressed: () async {
                                            final uri = Uri.parse(url);
                                            await launchUrl(uri,
                                                mode: LaunchMode
                                                    .externalApplication);
                                          },
                                          icon: const Icon(
                                              Icons.open_in_browser,
                                              size: 18),
                                          label: const Text('Web'),
                                        ),
                                        const SizedBox(width: 8),
                                        OutlinedButton.icon(
                                          onPressed: () async {
                                            final exportService =
                                                ref.read(exportServiceProvider);
                                            await exportService
                                                .shareMarkdown(widget.article!);
                                          },
                                          icon:
                                              const Icon(Icons.share, size: 18),
                                          label: const Text('Share MD'),
                                        ),
                                        const SizedBox(width: 8),
                                        OutlinedButton.icon(
                                          onPressed: () async {
                                            final exportService =
                                                ref.read(exportServiceProvider);
                                            await exportService
                                                .copyMarkdownToClipboard(
                                                    widget.article!);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        'Markdown copied')),
                                              );
                                            }
                                          },
                                          icon:
                                              const Icon(Icons.copy, size: 18),
                                          label: const Text('Copy MD'),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  if (widget.article?.imageUrl != null) ...[
                                    Builder(builder: (context) {
                                      final borderRadius =
                                          BorderRadius.circular(12);
                                      return ClipRRect(
                                        borderRadius: borderRadius,
                                        child: Image.network(
                                          widget.article!.imageUrl!,
                                          width: double.infinity,
                                          height: 220,
                                          fit: BoxFit.cover,
                                        ),
                                      );
                                    }),
                                    const SizedBox(height: 16),
                                  ],
                                  Card.filled(
                                    margin: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: MarkdownBody(
                                        data: snapshot.data!.markdown,
                                        selectable: true,
                                        onTapLink: (text, href, title) {
                                          if (href != null) {
                                            launchUrl(
                                              Uri.parse(href),
                                              mode: LaunchMode
                                                  .externalApplication,
                                            );
                                          }
                                        },
                                        styleSheet:
                                            MarkdownStyleSheet.fromTheme(
                                                    Theme.of(context))
                                                .copyWith(
                                          h1: Theme.of(context)
                                              .textTheme
                                              .headlineMedium
                                              ?.copyWith(
                                                  fontWeight: FontWeight.bold),
                                          h2: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                          p: Theme.of(
                                            context,
                                          )
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(height: 1.6),
                                          blockquote: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          blockquoteDecoration: BoxDecoration(
                                            border: Border(
                                              left: BorderSide(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                width: 4,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 120),
                                ],
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                ),
              ),
            ],
          ),
          // Persistent Top Tint Overlay (80dp, Tone 90 @ 50% LM / Tone Surface @ 40% DM)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 80,
            child: IgnorePointer(
              child: Container(
                color: Theme.of(context).brightness == Brightness.light
                    ? Theme.of(
                        context,
                      ).scaffoldBackgroundColor.withValues(alpha: 0.5)
                    : Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
