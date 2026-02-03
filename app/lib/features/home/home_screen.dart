import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../feed/providers/feed_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar.large(
            title: const Text('Google Tech News'),
            floating: true,
            pinned: true,
            actions: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.account_circle),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'All News'),
                Tab(text: 'The OS Lab'),
                Tab(text: 'Model Tracker'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            const NewsFeed(filter: null),
            const NewsFeed(filter: 'Operating Systems'),
            const NewsFeed(filter: 'Generative AI'),
          ],
        ),
      ),
    );
  }
}

class NewsFeed extends ConsumerWidget {
  final String? filter;
  const NewsFeed({super.key, this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.only(top: 8),
          sliver: ref
              .watch(feedProvider)
              .when(
                data: (articles) {
                  final filtered = filter == null
                      ? articles
                      : articles.where((a) => a.tags.contains(filter)).toList();

                  if (filtered.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(child: Text('No updates in this lab yet.')),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final article = filtered[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        clipBehavior: Clip.antiAlias,
                        elevation: 2,
                        child: InkWell(
                          onTap: () {},
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (article.imageUrl != null)
                                SizedBox(
                                  height: 150,
                                  width: double.infinity,
                                  child: Image.network(
                                    article.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) =>
                                        Container(color: Colors.grey.shade300),
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primaryContainer,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            article.source.name.toUpperCase(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onPrimaryContainer,
                                                ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '${article.publishedAt.day}/${article.publishedAt.month}',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.labelSmall,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      article.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      article.summary,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 4,
                                      children: article.tags
                                          .map(
                                            (tag) => Chip(
                                              label: Text(
                                                tag,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                ),
                                              ),
                                              padding: EdgeInsets.zero,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }, childCount: filtered.length),
                  );
                },
                error: (err, stack) => SliverToBoxAdapter(
                  child: Center(child: Text('Error: $err')),
                ),
                loading: () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
        ),
      ],
    );
  }
}
