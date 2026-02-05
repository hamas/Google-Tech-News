import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/news_providers.dart';

class ManageSourcesPage extends ConsumerStatefulWidget {
  const ManageSourcesPage({super.key});

  @override
  ConsumerState<ManageSourcesPage> createState() => _ManageSourcesPageState();
}

class _ManageSourcesPageState extends ConsumerState<ManageSourcesPage> {
  final _urlController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isValidating = false;

  @override
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addSource() async {
    final url = _urlController.text.trim();
    final name = _nameController.text.trim();

    if (url.isEmpty || name.isEmpty) return;

    setState(() => _isValidating = true);

    try {
      // Basic validation
      final uri = Uri.tryParse(url);
      if (uri == null || !uri.hasScheme) {
        throw Exception('Invalid URL');
      }

      // Check if reachable and looks like XML/RSS using Dio
      final dio = ref.read(dioProvider);
      final response = await dio.get<String>(url);
      if (response.statusCode != 200) {
        throw Exception('Failed to reach URL (Status: ${response.statusCode})');
      }

      // Simple check for RSS/XML signature
      if (response.data == null || !response.data!.trimLeft().startsWith('<')) {
        throw Exception('Content does not verify as XML/RSS');
      }

      await ref.read(newsRepositoryProvider).addNewsSource(name, url);

      if (mounted) {
        _urlController.clear();
        _nameController.clear();
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Source added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  void _showAddDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add RSS Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Source Name',
                hintText: 'e.g. The Verge',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'RSS URL',
                hintText: 'https://...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _isValidating ? null : _addSource,
            child: _isValidating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sourcesAsync = ref.watch(newsSourcesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Sources')),
      body: sourcesAsync.when(
        data: (sources) {
          if (sources.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.rss_feed, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No custom sources',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text('Add your favorite RSS feeds to get more news.'),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: sources.length,
            itemBuilder: (context, index) {
              final source = sources[index];
              return ListTile(
                title: Text(source.name),
                subtitle: Text(source.url),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: source.isEnabled,
                      onChanged: (val) {
                        ref
                            .read(newsRepositoryProvider)
                            .toggleNewsSource(source.id, val);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        ref
                            .read(newsRepositoryProvider)
                            .deleteNewsSource(source.id);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        error: (err, _) => Center(child: Text('Error: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Source'),
      ),
    );
  }
}
