import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class NewsImageCacheManager {
  static const key = 'news_image_cache';

  static final CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects:
          200, // Approximate limit, or uses disk space if supported
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
}
