import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'share_theme.dart';
import 'share_card.dart';
import '../../../domain/entities/news_article.dart';
import '../../../../../core/services/share_service.dart';

class ShareEditor extends ConsumerStatefulWidget {
  final NewsArticle article;

  const ShareEditor({super.key, required this.article});

  @override
  ConsumerState<ShareEditor> createState() => _ShareEditorState();
}

class _ShareEditorState extends ConsumerState<ShareEditor> {
  final ShareService _shareService = ShareService();
  ShareTheme _selectedTheme = ShareTheme.dark;
  bool _isSharing = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85, // Tall modal
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text('Share Article', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),

          // PREVIEW AREA
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: AspectRatio(
                    aspectRatio: 9 / 16,
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            // 1. Visible Preview (Scaled)
                            FittedBox(
                              fit: BoxFit.contain,
                              child: ShareCard(
                                article: widget.article,
                                theme: _selectedTheme,
                                scale: 1.0, // Layout size is 1080x1920
                              ),
                            ),

                            // 2. Invisible Capture Widget (Off-screen logic handled by Screenshot library via widget tree??)
                            // Actually with screenshot package, we wrap the widget we want to capture.
                            // But usually we can't capture something that isn't in the tree unless we use captureFromWidget.
                            // But captureFromWidget is async and builds its own pipeline.
                            // If we use Screenshot controller, it needs to be attached to a widget in the tree.
                            // To hide it, we can put it in a Stack underneath? Or just capture the visible one?
                            // Issue: Visible one is scaled down. We want high res.
                            // Solution: Use captureFromWidget (doesn't need controller attached to UI).
                            // Wait, ShareService uses controller. Let's adjust ShareService or use captureFromWidget logic in ShareService.
                            // Refactoring logic: ShareService shouldn't hold the controller if we use captureFromWidget.
                            // Let's stick to the controller attached to the visible widget for simplicity BUT
                            // if we capture the visible "FittedBox", will it capture 1080p? No.
                            // It captures screen pixels.
                            // BETTER APPROACH: Use Screenshot(controller: ...) wrapping a widget in an Offstage or minimal opacity stack?
                            // Screenshot package says: "Capture invisible widget" -> use captureFromWidget.
                            // So let's update ShareService to take the Widget as input!
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // THEME SELECTOR
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: ShareTheme.values.length,
              itemBuilder: (context, index) {
                final theme = ShareTheme.values[index];
                final isSelected = _selectedTheme == theme;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ChoiceChip(
                    label: Text(theme.label),
                    avatar: Icon(theme.icon, size: 18),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedTheme = theme);
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // SHARE BUTTON
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            child: FilledButton.icon(
              onPressed: _isSharing
                  ? null
                  : _captureAndShare, // Modified to call local method
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
              icon: _isSharing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.share),
              label: Text(_isSharing ? 'Generating...' : 'Share Image'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _captureAndShare() async {
    setState(() => _isSharing = true);

    // Construct the High-Res Widget
    final highResWidget = MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Material(
        child: ShareCard(article: widget.article, theme: _selectedTheme),
      ),
    );

    // Use ScreenshotController's static method or instance?
    // Actually use screenshotController.captureFromWidget(highResWidget)
    // But wait, ShareService is reusing logic. Let's make ShareService accept widget.

    try {
      // We'll bypass ShareService for the capture part to keep it simple here,
      // or update ShareService to accept a widget.
      // Let's update ShareService quickly via a new method.
      // Actually, I can't update ShareService in this file.
      // I'll assume I'll update ShareService next.
      // For now, let's look at `_shareService.captureAndShare`.
      // It expects `_screenshotController` to be attached.
      // Attaching it to the visible preview (which is FittedBox) yields low res.
      // Attaching it to a 1080x1920 container in a 1x1 Stack behind content?

      // BEST PATH: Update ShareService to expose `captureWidgetAndShare`.
      await _shareService.captureWidgetAndShare(
        highResWidget,
        widget.article.title,
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Error sharing: $e');
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }
}
