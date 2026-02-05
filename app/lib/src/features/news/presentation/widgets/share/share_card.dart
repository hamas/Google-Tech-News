import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'share_theme.dart';
import '../../../domain/entities/news_article.dart';

/// A 9:16 aspect ratio widget designed to be captured as an image.
class ShareCard extends StatelessWidget {
  final NewsArticle article;
  final ShareTheme theme;
  final double scale;

  const ShareCard({
    super.key,
    required this.article,
    required this.theme,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    // 1080x1920 base resolution logic.
    // When showing in preview, we scale this down.
    // When capturing, we render at 1.0 or pixelRatio 3.0.
    const double width = 1080;
    const double height = 1920;

    return Transform.scale(
      scale: scale,
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            // 1. Background
            Positioned.fill(child: _buildBackground()),

            // 2. Content
            Padding(
              padding: const EdgeInsets.all(80.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 120),
                  // Hero Image Area
                  Center(
                    child: Container(
                      width: 920,
                      height: 920,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(48),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 60,
                            offset: const Offset(0, 30),
                          ),
                        ],
                        image: article.imageUrl != null
                            ? DecorationImage(
                                image: NetworkImage(article.imageUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: Colors.grey.shade900,
                      ),
                      child: article.imageUrl == null
                          ? const Center(
                              child: Icon(
                                Icons.article,
                                size: 200,
                                color: Colors.white24,
                              ),
                            )
                          : null,
                    ),
                  ),

                  const Spacer(),

                  // Typography
                  Text(
                    article.source.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 40,
                      fontWeight: FontWeight.w600,
                      color: _getTextColor().withValues(alpha: 0.7),
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    article.title,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 96,
                      height: 1.1,
                      fontWeight: FontWeight.bold,
                      color: _getTextColor(),
                    ),
                  ),
                  const SizedBox(height: 48),
                  Text(
                    article.publishedAt.toString().split(' ')[0], // Simple date
                    style: GoogleFonts.inter(
                      fontSize: 36,
                      color: _getTextColor().withValues(alpha: 0.5),
                    ),
                  ),

                  const SizedBox(height: 120),

                  // Footer / Branding
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Google Tech News',
                              style: GoogleFonts.outfit(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: _getTextColor(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Get the app on Play Store',
                              style: GoogleFonts.inter(
                                fontSize: 32,
                                color: _getTextColor().withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _getTextColor(),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: QrImageView(
                          data:
                              'https://play.google.com/store/apps/details?id=com.hamas.google_tech_news',
                          version: QrVersions.auto,
                          size: 160,
                          eyeStyle: QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: _getBgColor(),
                          ),
                          dataModuleStyle: QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: _getBgColor(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    switch (theme) {
      case ShareTheme.dark:
        return Container(color: const Color(0xFF121212));
      case ShareTheme.minimal:
        return Container(color: const Color(0xFFF5F5F7));
      case ShareTheme.colorful:
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6750A4), // M3 Purple
                Color(0xFFB00020), // Error Red ish
                Color(0xFF006C51), // Teal
              ],
            ),
          ),
        );
      case ShareTheme.glass:
        // For glass, we ideally want a blurred version of the article image
        // covered by a translucent gradient.
        return Stack(
          children: [
            if (article.imageUrl != null)
              Positioned.fill(
                child: Image.network(article.imageUrl!, fit: BoxFit.cover),
              ),
            Positioned.fill(
              child: Container(color: Colors.black.withValues(alpha: 0.6)),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
    }
  }

  Color _getTextColor() {
    return theme == ShareTheme.minimal ? Colors.black : Colors.white;
  }

  Color _getBgColor() {
    return theme == ShareTheme.minimal ? Colors.white : Colors.black;
  }
}
