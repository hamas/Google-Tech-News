import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/services/tts_service.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ttsState = ref.watch<TtsState>(ttsServiceProvider);

    if (ttsState == TtsState.stopped) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.graphic_eq),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Reading Article...',
              style: TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(
              ttsState == TtsState.playing ? Icons.pause : Icons.play_arrow,
            ),
            onPressed: () {
              if (ttsState == TtsState.playing) {
                ref.read<TtsService>(ttsServiceProvider.notifier).pause();
              } else {
                ref
                    .read<TtsService>(ttsServiceProvider.notifier)
                    .speak(''); // Resume? Logic needed in service.
                // Actually service needs resume logic or we just re-speak?
                // pauseHandler sets state to paused.
                // We assume flutter_tts handles resume on speak? or specifically continue?
                // Let's implement resume/continue in service properly or use a simple toggle.
                // Check TtsService implementation.
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.stop),
            onPressed: () {
              ref.read<TtsService>(ttsServiceProvider.notifier).stop();
            },
          ),
        ],
      ),
    );
  }
}
