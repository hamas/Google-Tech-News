import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/news/presentation/widgets/branded_share_card.dart';

class ShareService {
  final ScreenshotController _screenshotController = ScreenshotController();

  Future<void> shareArticle(
    BuildContext context,
    String title,
    String source,
    String articleId, {
    String? imageUrl,
  }) async {
    try {
      await HapticFeedback.lightImpact(); // Immediate feedback

      final Uint8List image = await _screenshotController.captureFromWidget(
        BrandedShareCard(
          title: title,
          source: source,
          imageUrl: imageUrl,
          articleId: articleId,
        ),
        delay: const Duration(milliseconds: 100),
        pixelRatio: 3.0, // High-res for viral quality
      );

      final directory = await getTemporaryDirectory();
      final imagePath = await File(
        '${directory.path}/share_${DateTime.now().millisecondsSinceEpoch}.png',
      ).create();
      await imagePath.writeAsBytes(image);

      // Success Haptic
      await HapticFeedback.mediumImpact();

      // swiftlint:disable:next deprecated_member_use
      // swiftlint:disable:next deprecated_member_use
      // Use Share.share(params: ...) or similar?
      // Reverting to Share.shareXFiles with explicit ignore until exact v12 signature is verified
      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [XFile(imagePath.path)],
        text:
            'Stay ahead of the curve with Google Tech News. Download now for the latest on Gemini, Android, and Aluminum OS!\n\nRead more: https://googletechnews.app/article/$articleId',
      );
    } catch (e) {
      debugPrint('Error sharing: $e');
      // Fallback to text share
      // ignore: deprecated_member_use
      await Share.share(
        'Check out this news from Google Tech News!\n\n$title\nhttps://googletechnews.app/article/$articleId',
      );
    }
  }
}
