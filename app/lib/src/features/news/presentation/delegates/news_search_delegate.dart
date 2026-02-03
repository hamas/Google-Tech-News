import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/news_providers.dart';
import '../widgets/news_card.dart';

class NewsSearchDelegate extends SearchDelegate<void> {
  final WidgetRef ref;

  NewsSearchDelegate(this.ref);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.length < 2) {
      return const Center(
        child: Text('Search term must be longer than 1 character'),
      );
    }

    // Trigger search via repository
    // In a real app we might use a FutureProvider.family
    return FutureBuilder(
      future: ref.read(newsRepositoryProvider).searchNews(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final result = snapshot.data!;
        return result.fold(
          (failure) => Center(child: Text('Error: ${failure.error}')),
          (articles) {
            if (articles.isEmpty) {
              return const Center(child: Text('No articles found.'));
            }
            return ListView.builder(
              itemCount: articles.length,
              itemBuilder: (context, index) {
                return NewsCard(article: articles[index]);
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const Center(child: Text('Search for cache news...'));
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: theme.colorScheme.surface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}
