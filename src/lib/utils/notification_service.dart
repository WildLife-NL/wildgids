// name=src/lib/utils/notification_service.dart url=https://github.com/WildLife-NL/wildgids/blob/653781fbe36a823ce6f8bcbf286b4c3b3f806bdc/src/lib/utils/notification_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService();
  static final NotificationService instance = NotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _pushEnabled = true;
  ValueChanged<String>? onNotificationTap;
  String? launchPayload;

  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  bool get pushEnabled => _pushEnabled;

  void setPushEnabled(bool enabled) {
    _pushEnabled = enabled;
  }

  Future<void> init() async {
    if (_initialized || !_supported) return;

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
      macOS: iosInit,
    );

    // Initialize on each platform separately (v22.3.0 pattern)
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          onNotificationTap?.call(payload);
        }
      },
    );

    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) {
      launchPayload = launch?.notificationResponse?.payload;
    }

    // Android 13+ runtime permission
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final androidImpl =
          _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
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

  Future<void> requestAndroidNotificationPermission() async {
    if (!_initialized) await init();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final androidImpl =
          _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      await androidImpl?.requestNotificationsPermission();
    }
  }

  Future<void> show({
    required String title,
    required String body,
    Importance importance = Importance.defaultImportance,
    Priority priority = Priority.defaultPriority,
  }) async {
    if (!_pushEnabled || !_supported) return;
    if (!_initialized) await init();

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
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

    // Use named parameters for show()
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  /// One local reminder at an absolute instant, including after app termination.
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    required String payload,
  }) async {
    if (!_pushEnabled || !_supported) return;
    if (!_initialized) await init();
    // The native plugin has second precision. Round up, rather than notifying
    // slightly before a backend time that includes fractional seconds.
    final utc = scheduledAt.toUtc();
    final notificationTime =
        utc.millisecond == 0 && utc.microsecond == 0
            ? utc
            : DateTime.utc(
              utc.year,
              utc.month,
              utc.day,
              utc.hour,
              utc.minute,
              utc.second + 1,
            );
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      // UTC preserves the already resolved instant and explicit backend offset.
      scheduledDate: tz.TZDateTime.from(notificationTime, tz.UTC),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'questionnaire_channel',
          'Vragenlijsten',
          channelDescription: 'Herinneringen voor ontvangen vragenlijsten',
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
      // Does not require the alarm-clock permission. Android may defer delivery
      // during battery-saving modes; the notification is never requested early.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  Future<void> cancel(int id) async {
    if (!_supported) return;
    if (!_initialized) await init();
    await _plugin.cancel(id: id);
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
