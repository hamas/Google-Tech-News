import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../../features/news/domain/entities/news_article.dart';
import '../../features/news/presentation/widgets/shareable_story_widget.dart';

class StoryShareService {
  final ScreenshotController _screenshotController = ScreenshotController();

  /// Captures a high-resolution story card and triggers the share sheet
  Future<void> shareStory(BuildContext context, NewsArticle article) async {
    try {
      // 1. Capture the widget off-screen
      final uint8List = await _screenshotController.captureFromWidget(
        ShareableStoryWidget(article: article),
        pixelRatio: 3.0, // High density for 1080x1920 feel
        context: context,
      );

      // 2. Save to temporary directory
      final tempDir = await getTemporaryDirectory();
      final file =
          await File('${tempDir.path}/news_story_${article.id}.png').create();
      await file.writeAsBytes(uint8List);

      // 3. Share via native share sheet (2026 Stable API)
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: article.title,
          text: 'Read more in Google Tech News!',
        ),
      );
    } catch (e) {
      debugPrint('Story Share Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate story: $e')),
        );
      }
    }
  }
}
