import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/news_providers.dart';
import '../widgets/news_search_app_bar.dart';
import 'news_feed_page.dart';
import 'saved_articles_page.dart';
import '../../../../core/generated/app_localizations.dart';

class NewsShellPage extends ConsumerStatefulWidget {
  const NewsShellPage({super.key});

  @override
  ConsumerState<NewsShellPage> createState() => _NewsShellPageState();
}

class _NewsShellPageState extends ConsumerState<NewsShellPage> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
      _showBackToTop = false; // Reset for new page
    });
    _scaffoldKey.currentState?.closeDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: NavigationDrawer(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
            child: Text(
              AppLocalizations.of(context)!.appTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.newspaper_outlined),
            selectedIcon: const Icon(Icons.newspaper),
            label: Text(AppLocalizations.of(context)!.latestNews),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.bookmark_outline),
            selectedIcon: const Icon(Icons.bookmark),
            label: Text(AppLocalizations.of(context)!.savedArticles),
          ),
          const Divider(indent: 28, endIndent: 28),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
            child: Text(
              AppLocalizations.of(context)!.settings,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: Text(AppLocalizations.of(context)!.settings),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (_selectedIndex == 0) {
            await ref.read(fetchNewsProvider).call();
          }
        },
        notificationPredicate: (notification) =>
            _selectedIndex == 0 && notification.depth == 0,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollUpdateNotification &&
                notification.metrics.axis == Axis.vertical) {
              final metrics = notification.metrics;
              final pixels = metrics.pixels;
              final delta = notification.scrollDelta ?? 0;

              bool shouldShow = _showBackToTop;

              if (delta > 2 && pixels > 80) {
                shouldShow = true;
              } else if (delta < -2 || pixels < 50) {
                shouldShow = false;
              }

              if (shouldShow != _showBackToTop) {
                setState(() => _showBackToTop = shouldShow);
              }
            }
            return false;
          },
          child: Stack(
            children: [
              CustomScrollView(
                controller: _scrollController,
                slivers: [
                  NewsSearchAppBar(scaffoldKey: _scaffoldKey),
                  ..._buildSlivers(context),
                ],
              ),
              // Persistent Top Tint Overlay (80dp, Tone 90 @ 50% LM / Tone Surface @ 40% DM)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 80,
                child: IgnorePointer(
                  child: Container(
                    color: Theme.of(context).brightness == Brightness.light
                        ? Theme.of(
                            context,
                          ).scaffoldBackgroundColor.withValues(alpha: 0.5)
                        : Theme.of(
                            context,
                          ).colorScheme.surface.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 8),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: _showBackToTop
              ? FloatingActionButton(
                  key: const ValueKey('back_to_top_fab'),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                          ? HSLColor.fromColor(
                              Theme.of(context).colorScheme.primary,
                            ).withLightness(0.74).toColor()
                          : HSLColor.fromColor(
                              Theme.of(context).colorScheme.primary,
                            ).withLightness(0.65).toColor(),
                  onPressed: () {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                    );
                  },
                  child: Icon(
                    Icons.keyboard_arrow_up,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).scaffoldBackgroundColor
                        : Theme.of(context).colorScheme.primary,
                    size: 29,
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('empty_fab')),
        ),
      ),
    );
  }

  List<Widget> _buildSlivers(BuildContext context) {
    switch (_selectedIndex) {
      case 0:
        final newsAsync = ref.watch(newsFeedProvider);
        return newsAsync.when(
          data: (articles) => NewsFeedPage.buildSlivers(context, ref, articles),
          loading: () => [
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
          error: (err, _) => [
            SliverFillRemaining(child: Center(child: Text('Error: $err'))),
          ],
        );
      case 1:
        final bookmarksAsync = ref.watch(bookmarksProvider);
        return bookmarksAsync.when(
          data: (articles) => SavedArticlesPage.buildSlivers(context, articles),
          loading: () => [
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
          error: (err, _) => [
            SliverFillRemaining(child: Center(child: Text('Error: $err'))),
          ],
        );
      case 2:
        return [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  AppLocalizations.of(context)!.settings,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.feedback_outlined),
                  title: Text(AppLocalizations.of(context)!.sendFeedback),
                  subtitle: Text(
                    AppLocalizations.of(context)!.sendFeedbackSubtitle,
                  ),
                  onTap: () async {
                    const url =
                        'https://github.com/hamas/GoogleTechNews/issues/new';
                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(
                        Uri.parse(url),
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(
                    Icons.security_outlined,
                    color: Colors.green,
                  ),
                  title: Text(AppLocalizations.of(context)!.localPrivate),
                  subtitle: Text(
                    AppLocalizations.of(context)!.localPrivateSubtitle,
                  ),
                  onTap: () {},
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(AppLocalizations.of(context)!.version),
                  subtitle: Text(AppLocalizations.of(context)!.versionSubtitle),
                ),
              ]),
            ),
          ),
        ];
      default:
        return [const SliverToBoxAdapter(child: SizedBox.shrink())];
    }
  }
}
