import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/filter_providers.dart';
import '../../../../core/constants/news_sources.dart';

class NewsFilterBar extends ConsumerWidget {
  const NewsFilterBar({super.key});

  List<String> get _filters => ['All', ...NewsSources.feeds.keys];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFilter = ref.watch<String?>(activeFilterProvider) ?? 'All';
    final filters = _filters;

    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = activeFilter == filter;

          return FilterChip(
            label: Text(
              filter,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onSecondaryContainer
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            selected: isSelected,
            onSelected: (selected) {
              ref
                  .read<ActiveFilter>(activeFilterProvider.notifier)
                  .setFilter(filter == 'All' ? null : filter);
            },
            showCheckmark: false,
            // Customizing for the "Glass" theme
            backgroundColor: Colors.transparent,
            selectedColor: Theme.of(context).colorScheme.secondaryContainer,
            side: BorderSide(
              color: isSelected
                  ? Colors.transparent
                  : Theme.of(context).colorScheme.outlineVariant,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            visualDensity: VisualDensity.compact,
            // Material 3 refinement
            elevation: 0,
            pressElevation: 0,
          );
        },
      ),
    );
  }
}
