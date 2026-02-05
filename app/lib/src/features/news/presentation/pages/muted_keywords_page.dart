import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/news_providers.dart';

class MutedKeywordsPage extends ConsumerWidget {
  const MutedKeywordsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keywordsAsync = ref.watch(mutedKeywordsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Muted Keywords')),
      body: keywordsAsync.when(
        data: (keywords) {
          if (keywords.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.filter_list_off,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No keywords muted',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text('Add keywords to filter articles'),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: keywords.length,
            itemBuilder: (context, index) {
              final item = keywords[index];
              return Dismissible(
                key: Key('mute_${item.id}'),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  ref.read(newsRepositoryProvider).deleteMutedKeyword(item.id);
                },
                child: ListTile(
                  title: Text(item.keyword),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      ref
                          .read(newsRepositoryProvider)
                          .deleteMutedKeyword(item.id);
                    },
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddDialog(context, ref);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Mute Keyword'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Keyword',
              hintText: 'e.g. Crypto, Sport',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  ref.read(newsRepositoryProvider).addMutedKeyword(text);
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
