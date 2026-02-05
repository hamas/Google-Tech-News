import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/news_providers.dart';
import '../../../../../core/services/tts_service.dart';
import '../../domain/entities/news_article.dart';
import '../../domain/models/parsed_article.dart';
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
    _loadArticle();
  }

  Future<void> _loadArticle() async {
    if (widget.article != null) {
      final repository = ref.read(newsRepositoryProvider);

      // 1. Check DB first
      final cachedContent =
          await repository.getFullContent(widget.article!.localId!);
      if (cachedContent != null) {
        final blocks =
            (jsonDecode(cachedContent) as List).cast<Map<String, dynamic>>();
        // Convert to ParsedArticle format for UI compatibility
        setState(() {
          _articleFuture = Future.value(_blocksToParsed(blocks));
        });
      } else {
        // 2. Scrape and Save
        final scraper = ref.read(newsScraperServiceProvider);
        setState(() {
          _articleFuture = scraper.scrape(widget.article!.url).then((blocks) {
            if (blocks.isNotEmpty) {
              repository.saveFullContent(
                  widget.article!.localId!, jsonEncode(blocks));
            }
            return _blocksToParsed(blocks.cast<Map<String, dynamic>>());
          });
        });
      }
    }
  }

  ParsedArticle _blocksToParsed(List<Map<String, dynamic>> blocks) {
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
    final title = widget.article?.title ?? 'Article Detail';
    final url = widget.article?.url ?? 'https://blog.google';

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontSize: 14)),
        leading: const BackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.headphones),
            onPressed: () {
              if (widget.article != null) {
                // If we have parsed content, speak that. Otherwise summary.
                // We don't have access to parsed content synchronously here easily unless we store it.
                // For now, adhere to existing behavior (summary/title).
                final text = widget.article!.summary.isNotEmpty
                    ? widget.article!.summary
                    : widget.article!.title;
                ref.read<TtsService>(ttsServiceProvider.notifier).speak(text);
              }
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (widget.article == null) return;
              final exportService = ref.read(exportServiceProvider);

              switch (value) {
                case 'share_image':
                  if (widget.article != null) {
                    await showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) =>
                          ShareEditor(article: widget.article!),
                    );
                  }
                  break;
                case 'browser':
                  final uri = Uri.parse(url);
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                  break;
                case 'share_pdf':
                  await exportService.sharePdf(widget.article!);
                  break;
                case 'share_markdown':
                  await exportService.shareMarkdown(widget.article!);
                  break;
                case 'copy_markdown':
                  await exportService.copyMarkdownToClipboard(widget.article!);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Markdown copied')),
                    );
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share_image',
                child: Row(
                  children: [
                    Icon(Icons.image, color: Colors.black87),
                    SizedBox(width: 12),
                    Text('Share Image'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'browser',
                child: Row(
                  children: [
                    Icon(Icons.open_in_browser, color: Colors.black87),
                    SizedBox(width: 12),
                    Text('Open in Browser'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share_pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.black87),
                    SizedBox(width: 12),
                    Text('Export PDF'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share_markdown',
                child: Row(
                  children: [
                    Icon(Icons.share, color: Colors.black87),
                    SizedBox(width: 12),
                    Text('Share Markdown'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'copy_markdown',
                child: Row(
                  children: [
                    Icon(Icons.copy, color: Colors.black87),
                    SizedBox(width: 12),
                    Text('Copy Markdown'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: widget.article == null
          ? const Center(child: Text('Article not found'))
          : FutureBuilder<ParsedArticle>(
              future: _articleFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Could not load reader mode',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: () {
                              final uri = Uri.parse(url);
                              launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            },
                            icon: const Icon(Icons.open_in_browser),
                            label: const Text('Open in Browser'),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                final contentService =
                                    ref.read(newsContentServiceProvider);
                                _articleFuture = contentService.extractContent(
                                  widget.article!.url,
                                );
                              });
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                } else if (snapshot.hasData) {
                  return Markdown(
                    data: snapshot.data!.markdown,
                    selectable: true,
                    onTapLink: (text, href, title) {
                      if (href != null) {
                        launchUrl(
                          Uri.parse(href),
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                        .copyWith(
                      h1: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      h2: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      p: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(height: 1.6),
                      blockquote: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                      blockquoteDecoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 4,
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
    );
  }
}
