import 'package:url_launcher/url_launcher.dart';

enum LinkAction { internalWebView, externalBrowser, genericExternal }

class LinkResolver {
  static Future<LinkAction> resolve(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return LinkAction.externalBrowser;

    if (uri.path.toLowerCase().endsWith('.pdf')) {
      return LinkAction.externalBrowser; // Chrome/System PDF viewer
    }

    if (uri.host.contains('youtube.com') || uri.host.contains('youtu.be')) {
      return LinkAction.genericExternal; // Youtube App
    }

    return LinkAction.internalWebView;
  }

  static Future<void> launchExternal(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }
}
