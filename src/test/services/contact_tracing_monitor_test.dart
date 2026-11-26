import 'dart:async';

// Use the BLE plugin's public platform interface to isolate these tests from
// device hardware; the interface is supplied by the existing BLE dependency.
// ignore: depend_on_referenced_packages
import 'package:flutter_blue_plus_platform_interface/flutter_blue_plus_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildgids/data_managers/api_client.dart';
import 'package:wildgids/data_managers/contact_api.dart';
import 'package:wildgids/models/api_models/contact_model.dart';
import 'package:wildgids/services/contact_tracing_monitor.dart';

final class UnavailableBlePlatform extends FlutterBluePlusPlatform {}

class RetryableContactApi extends ContactApi {
  RetryableContactApi() : super(ApiClient('https://example.test/'));
  bool fail = true;
  int attempts = 0;
  Completer<Contact>? pending;

  @override
  Future<Contact> endContact(String contactId) async {
    attempts++;
    if (pending != null) return pending!.future;
    if (fail) throw StateError('Current GPS position unavailable');
    return Contact(id: contactId, start: DateTime.now(), end: DateTime.now());
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late RetryableContactApi api;
  late ContactTracingMonitor monitor;
  final events = <bool>[];

  setUp(() {
    FlutterBluePlusPlatform.instance = UnavailableBlePlatform();
    api = RetryableContactApi();
    monitor = ContactTracingMonitor(api);
    events.clear();
    monitor.onContactEnded = (_, {required automatic}) => events.add(automatic);
  });

  Future<void> start() => monitor.start(
    contactId: 'contact-1',
    mac: 'AA:BB:CC:DD:EE:FF',
    contact: Contact(id: 'contact-1', start: DateTime.now()),
  );

  test(
    'failed manual ending keeps the active contact available for retry',
    () async {
      await start();
      await expectLater(monitor.endActiveContact(), throwsStateError);
      expect(monitor.hasActiveSession, isTrue);
      expect(monitor.activeContactId, 'contact-1');
      expect(monitor.busyEnding, isFalse);
      expect(events, isEmpty);

      api.fail = false;
      final ended = await monitor.endActiveContact();
      expect(ended?.id, 'contact-1');
      expect(monitor.hasActiveSession, isFalse);
      expect(api.attempts, 2);
      expect(events, [false]);
      await monitor.stop();
      monitor.dispose();
    },
  );

  test(
    'automatic signal-loss ending retries after GPS failure without an unhandled error',
    () async {
      monitor.applySettings(
        activeScanIntervalSeconds: 30,
        signalLossSeconds: 1,
      );
      final failed = Completer<void>();
      final ended = Completer<void>();
      monitor.addListener(() {
        if (monitor.lastAutoEndMessage?.contains('mislukt') == true &&
            !monitor.busyEnding &&
            !failed.isCompleted) {
          failed.complete();
        }
        if (!monitor.hasActiveSession && !ended.isCompleted) ended.complete();
      });
      await start();
      await failed.future.timeout(const Duration(seconds: 8));
      expect(api.attempts, 1);
      expect(monitor.hasActiveSession, isTrue);
      expect(
        monitor.lastAutoEndMessage,
        contains('Automatisch beëindigen mislukt'),
      );

      api.fail = false;
      await ended.future.timeout(const Duration(seconds: 8));
      expect(api.attempts, 2);
      expect(monitor.hasActiveSession, isFalse);
      expect(events, [true]);
      await monitor.stop();
      monitor.dispose();
    },
  );

  test('an in-flight end request prevents duplicate ending requests', () async {
    await start();
    api.pending = Completer<Contact>();
    final ending = monitor.endActiveContact();
    await Future<void>.delayed(Duration.zero);
    expect(monitor.busyEnding, isTrue);
    expect(await monitor.endActiveContact(), isNull);
    expect(api.attempts, 1);
    api.pending!.complete(
      Contact(id: 'contact-1', start: DateTime.now(), end: DateTime.now()),
    );
    await ending;
    expect(events, [false]);
    expect(monitor.hasActiveSession, isFalse);
    await monitor.stop();
    monitor.dispose();
  });
}
