import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class MonitoringService {
  static final MonitoringService _instance = MonitoringService._internal();

  factory MonitoringService() => _instance;

  MonitoringService._internal();

  bool _initialized = false;

  Future<void> initialize() async {
    try {
      // Mock-Safe Init: Used because we might not have google-services.json locally
      // In a real release build, user provides the JSON.
      if (kReleaseMode) {
        await Firebase.initializeApp();
        FlutterError.onError =
            FirebaseCrashlytics.instance.recordFlutterFatalError;
        _initialized = true;
      }
    } catch (e) {
      debugPrint('MonitoringService Warning: Firebase not configured ($e)');
    }
  }

  Future<void> logError(dynamic exception, StackTrace? stack) async {
    if (_initialized) {
      await FirebaseCrashlytics.instance.recordError(exception, stack);
    } else {
      debugPrint('Non-Fatal Error: $exception');
    }
  }

  Future<void> logEvent(String name) async {
    // Placeholder for Analytics
    debugPrint('Analytics Event: $name');
  }
}
