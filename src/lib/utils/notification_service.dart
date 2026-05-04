import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(settings);

    // Android 13+ runtime permission
    if (!kIsWeb && Platform.isAndroid) {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestNotificationsPermission();

      // Ensure a default channel exists
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'default_channel',
        'General',
        description: 'General notifications',
        importance: Importance.defaultImportance,
      );
      await androidImpl?.createNotificationChannel(channel);
    }

    _initialized = true;
  }

  Future<void> show({
    required String title,
    required String body,
    Importance importance = Importance.defaultImportance,
    Priority priority = Priority.defaultPriority,
  }) async {
    if (!_initialized) await init();

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'default_channel',
      'General',
      channelDescription: 'General notifications',
      importance: importance,
      priority: priority,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  /// Show a notification from a conveyance object
  Future<void> showConveyanceNotification({
    required String messageText,
    String? animalName,
  }) async {
    String title = 'Nieuwe melding';
    if (animalName != null && animalName.isNotEmpty) {
      title = 'Melding: $animalName';
    }

    await show(
      title: title,
      body: messageText,
      importance: Importance.high,
      priority: Priority.high,
    );
  }
}
