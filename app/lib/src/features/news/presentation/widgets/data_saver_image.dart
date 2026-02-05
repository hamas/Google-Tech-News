import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/services/connectivity_service.dart';
import '../providers/news_providers.dart';

class DataSaverImage extends ConsumerStatefulWidget {
  final String imageUrl;
  final double? height;
  final double? width;
  final BoxFit? fit;

  const DataSaverImage({
    super.key,
    required this.imageUrl,
    this.height,
    this.width,
    this.fit,
  });

  @override
  ConsumerState<DataSaverImage> createState() => _DataSaverImageState();
}

class _DataSaverImageState extends ConsumerState<DataSaverImage> {
  bool _forceLoad = false;

  @override
  Widget build(BuildContext context) {
    final isDataSaver = ref.watch(dataSaverProvider).asData?.value ?? false;

    // We need real-time connectivity status.
    // Provider for it:
    final isMobileAsync = ref.watch(isMobileProvider);
    final isMobile = isMobileAsync.asData?.value ?? false;

    final shouldBlock = isDataSaver && isMobile && !_forceLoad;

    if (shouldBlock) {
      return Container(
        height: widget.height,
        width: widget.width,
        color: Colors.grey[200],
        child: InkWell(
          onTap: () {
            setState(() {
              _forceLoad = true;
            });
          },
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.grey,
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap to Load',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: widget.imageUrl,
      height: widget.height,
      width: widget.width,
      fit: widget.fit,
      placeholder: (context, url) => Container(color: Colors.grey[200]),
      errorWidget: (context, url, error) => const Icon(Icons.error),
    );
  }
}

final isMobileProvider = StreamProvider<bool>((ref) {
  return ref.watch(connectivityServiceProvider).isMobileStream;
});
