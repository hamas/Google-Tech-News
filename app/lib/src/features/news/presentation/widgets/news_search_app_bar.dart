import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/news_providers.dart';
import '../delegates/news_search_delegate.dart';

class NewsSearchAppBar extends ConsumerWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const NewsSearchAppBar({super.key, required this.scaffoldKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Harmonized background color
    final barColor = isDark
        ? Color.alphaBlend(
            colorScheme.primary.withValues(alpha: 0.12),
            colorScheme.surfaceContainerHighest,
          )
        : colorScheme.surface;

    return SliverAppBar(
      floating: true,
      snap: true,
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () => scaffoldKey.currentState?.openDrawer(),
        tooltip: 'Open Menu',
      ),
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: GestureDetector(
          onTap: () {
            showSearch(context: context, delegate: NewsSearchDelegate(ref));
          },
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Center(
              child: Text(
                'Search News',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w400,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: IconButton(
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? HSLColor.fromColor(
                      colorScheme.primary,
                    ).withLightness(0.74).toColor()
                  : HSLColor.fromColor(
                      colorScheme.primary,
                    ).withLightness(0.65).toColor(),
              foregroundColor: colorScheme.surface,
            ),
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => ref.read(fetchNewsProvider).call(),
            tooltip: 'Refresh Feed',
          ),
        ),
      ],
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: kToolbarHeight + 16,
    );
  }
}
