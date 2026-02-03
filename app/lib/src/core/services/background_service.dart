import 'package:workmanager/workmanager.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../features/news/data/datasources/dlp_rss_fetcher.dart';

const String kBackgroundFetchTask = 'com.googletechnews.app.backgroundFetch';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case kBackgroundFetchTask:
        try {
          if (kDebugMode) {
            print('Background Fetch Started');
          }

          // Re-instantiate Fetcher in Isolate
          final dio = Dio();
          final fetcher = DlpRssFetcher(dio);

          final articles = await fetcher.fetchAll();

          if (kDebugMode) {
            print(
              'Background Fetch Success: ${articles.length} articles found.',
            );
          }

          // Note: In a full app, we would open Isar here and save.
          // For MVP, we verify the network call succeeds.

          return Future.value(true);
        } catch (e) {
          if (kDebugMode) {
            print('Background Fetch Failed: $e');
          }
          return Future.value(false);
        }
      default:
        return Future.value(true);
    }
  });
}

class BackgroundService {
  static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher);

    await Workmanager().registerPeriodicTask(
      '1',
      kBackgroundFetchTask,
      frequency: const Duration(hours: 1), // Minimum 15 mins on Android
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
    );
  }
}
