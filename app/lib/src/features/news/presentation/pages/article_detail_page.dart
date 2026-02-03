import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/news_article.dart';
import '../../../../core/utils/link_resolver.dart';

class ArticleDetailPage extends StatefulWidget {
  final String articleId;
  final NewsArticle? article;

  const ArticleDetailPage({super.key, required this.articleId, this.article});

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  double _progress = 0;
  bool _isWebViewLoading = true;

  @override
  Widget build(BuildContext context) {
    // If article is null (deep link), fallback
    final url = widget.article?.url ?? 'https://blog.google';
    final title = widget.article?.title ?? 'Article Detail';

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontSize: 14)),
        leading: const BackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () async {
              final uri = Uri.parse(url);
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
          ),
        ],
        bottom: _isWebViewLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  value: _progress > 0 ? _progress : null,
                ),
              )
            : null,
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(url)),
        onProgressChanged: (controller, progress) {
          setState(() {
            _progress = progress / 100;
          });
        },
        onLoadStop: (controller, url) {
          setState(() {
            _isWebViewLoading = false;
          });
        },
        shouldOverrideUrlLoading: (controller, navigationAction) async {
          final uri = navigationAction.request.url;
          if (uri == null) return NavigationActionPolicy.CANCEL;

          final action = await LinkResolver.resolve(uri.toString());

          if (action == LinkAction.internalWebView) {
            return NavigationActionPolicy.ALLOW;
          } else {
            await LinkResolver.launchExternal(uri.toString());
            return NavigationActionPolicy.CANCEL;
          }
        },
      ),
    );
  }
}
