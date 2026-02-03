import 'dart:io';
import 'package:path_provider/path_provider.dart';

class SystemHealthService {
  static final SystemHealthService _instance = SystemHealthService._internal();
  factory SystemHealthService() => _instance;
  SystemHealthService._internal();

  /// Log a fetch failure locally for debugging
  Future<void> logFetchFailure(String source, String error) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/system_health.log');
      final timestamp = DateTime.now().toCloserString();
      await file.writeAsString(
        '[$timestamp] FETCH_FAILURE: $source | Error: $error\n',
        mode: FileMode.append,
      );
    } catch (e) {
      // Silently fail to avoid recursion
    }
  }

  Future<String> getLogs() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/system_health.log');
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (_) {}
    return 'No logs found.';
  }
}

extension on DateTime {
  String toCloserString() =>
      toIso8601String().substring(0, 19).replaceAll('T', ' ');
}
