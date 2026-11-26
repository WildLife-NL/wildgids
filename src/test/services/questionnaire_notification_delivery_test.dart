import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildgids/utils/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'initialize') return true;
          if (call.method == 'getNotificationAppLaunchDetails') {
            return {'notificationLaunchedApp': false};
          }
          return null;
        });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    test(
      'sends a single native schedule and cancellation on $platform',
      () async {
        debugDefaultTargetPlatformOverride = platform;
        if (platform == TargetPlatform.android) {
          AndroidFlutterLocalNotificationsPlugin.registerWith();
        } else {
          IOSFlutterLocalNotificationsPlugin.registerWith();
        }
        final notifications = NotificationService();
        final at = DateTime.now().toUtc().add(const Duration(hours: 1));
        await notifications.schedule(
          id: 1073741824,
          title: 'Nieuwe vragenlijst',
          body: 'Je vragenlijst staat klaar.',
          scheduledAt: at,
          payload: 'questionnaire:interaction-1',
        );
        final request = calls.singleWhere((c) => c.method == 'zonedSchedule');
        final args = Map<String, dynamic>.from(request.arguments as Map);
        expect(args['id'], 1073741824);
        expect(args['timeZoneName'], 'Etc/UTC');
        final scheduled = DateTime.parse('${args['scheduledDateTime']}Z');
        expect(scheduled.isBefore(at), isFalse);
        expect(scheduled.difference(at), lessThan(const Duration(seconds: 1)));
        expect(args['payload'], 'questionnaire:interaction-1');
        expect(args['matchDateTimeComponents'], isNull);
        if (platform == TargetPlatform.android) {
          expect(
            (args['platformSpecifics'] as Map)['scheduleMode'],
            'inexactAllowWhileIdle',
          );
        }

        notifications.setPushEnabled(false);
        await notifications.schedule(
          id: 1073741825,
          title: 'Uitgeschakeld',
          body: '',
          scheduledAt: at,
          payload: 'questionnaire:interaction-2',
        );
        expect(calls.where((c) => c.method == 'zonedSchedule'), hasLength(1));
        await notifications.cancel(1073741824);
        final cancelled = calls.singleWhere((c) => c.method == 'cancel');
        expect(
          cancelled.arguments is Map
              ? (cancelled.arguments as Map)['id']
              : cancelled.arguments,
          1073741824,
        );
      },
    );
  }
}
