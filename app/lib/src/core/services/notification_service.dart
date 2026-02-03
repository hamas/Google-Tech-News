import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // 1. Init Local Notifications
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(settings: initSettings);

    // 2. Setup Channels (Android)
    // Breaking News (High)
    const breakingChannel = AndroidNotificationChannel(
      'breaking_news',
      'Breaking News',
      description: 'Notifications for high priority breaking news',
      importance: Importance.high,
    );

    // Daily Digest (Low)
    const digestChannel = AndroidNotificationChannel(
      'daily_digest',
      'Daily Digest',
      description: 'Daily summary of tech news',
      importance: Importance.low,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(breakingChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(digestChannel);

    // 3. Init Firebase (Mock-safe)
    try {
      // Logic would go here. Skipping actual init call to avoid crash without google-services.json
      // FirebaseMessaging.instance.onMessage.listen(...)
    } catch (e) {
      debugPrint('Firebase init failed (expected locally): $e');
    }
  }

  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'breaking_news',
          'Breaking News',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: payload,
    );
  }
}
