import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  final ScreenshotController _screenshotController = ScreenshotController();

  ScreenshotController get screenshotController => _screenshotController;

  /// Captures a specific widget (off-screen) and shares it.
  Future<void> captureWidgetAndShare(Widget widget, String title) async {
    try {
      final Uint8List imageBytes = await _screenshotController
          .captureFromWidget(
            widget,
            pixelRatio: 3.0,
            delay: const Duration(milliseconds: 100), // Ensure layout
            context: null, // Can be null for off-screen
          );

      final directory = await getTemporaryDirectory();
      final imagePath = await File(
        '${directory.path}/${_sanitizeFilename(title)}.png',
      ).create();

      await imagePath.writeAsBytes(imageBytes);

      // ignore: deprecated_member_use
      await Share.shareXFiles([
        XFile(imagePath.path),
      ], text: 'Check out this article from Google Tech News: $title');
    } catch (e) {
      rethrow;
    }
  }

  /// Captures the widget associated with [_screenshotController] and shares it.
  Future<void> captureAndShare(String title) async {
    try {
      final Uint8List? imageBytes = await _screenshotController.capture(
        pixelRatio: 3.0, // High res for share
      );

      if (imageBytes != null) {
        final directory = await getTemporaryDirectory();
        final imagePath = await File(
          '${directory.path}/${_sanitizeFilename(title)}.png',
        ).create();

        await imagePath.writeAsBytes(imageBytes);

        // ignore: deprecated_member_use
        await Share.shareXFiles([
          XFile(imagePath.path),
        ], text: 'Check out this article from Google Tech News: $title');
      }
    } catch (e) {
      // Handle error (maybe rethrow for UI to show snackbar)
      rethrow;
    }
  }

  String _sanitizeFilename(String title) {
    return title.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
  }

  /// Original text sharing method for NewsCard
  Future<void> shareArticle(
    BuildContext context,
    String title,
    String source,
    String id, {
    String? imageUrl,
  }) async {
    // ignore: deprecated_member_use
    await Share.share(
      '$title\n$source\n\nRead more: https://google.com/news/$id',
      subject: title,
    );
  }
}
