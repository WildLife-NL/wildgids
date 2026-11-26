import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// The existing BLE dependency exposes a hardware-free platform implementation.
// ignore: depend_on_referenced_packages
import 'package:flutter_blue_plus_platform_interface/flutter_blue_plus_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildgids/data_managers/api_client.dart';
import 'package:wildgids/data_managers/contact_api.dart';
import 'package:wildgids/models/api_models/contact_model.dart';
import 'package:wildgids/services/contact_tracing_coordinator.dart';
import 'package:wildgids/services/contact_tracing_monitor.dart';
import 'package:wildgids/services/contact_tracing_preferences.dart';
import 'package:wildgids/utils/notification_service.dart';

final class TestCollarRadio extends FlutterBluePlusPlatform {
  final advertisements = StreamController<BmScanResponse>.broadcast();
  int starts = 0;
  bool failStart = false;

  @override
  Future<bool> isSupported(BmIsSupportedRequest request) async => true;
  @override
  Future<BmBluetoothAdapterState> getAdapterState(
    BmBluetoothAdapterStateRequest request,
  ) async => BmBluetoothAdapterState(adapterState: BmAdapterStateEnum.on);
  @override
  Stream<BmScanResponse> get onScanResponse => advertisements.stream;
  @override
  Future<bool> startScan(BmScanSettings settings) async {
    starts++;
    if (failStart) throw StateError('Radio unavailable');
    return true;
  }

  @override
  Future<bool> stopScan(BmStopScanRequest request) async => true;

  void advertise(String id, {String name = 'SP123456', int rssi = -45}) {
    advertisements.add(
      BmScanResponse(
        advertisements: [
          BmScanAdvertisement(
            remoteId: DeviceIdentifier(id),
            platformName: name,
            advName: name,
            connectable: true,
            txPowerLevel: null,
            appearance: null,
            manufacturerData: {
              0x0A61: [1, 2, 3],
            },
            serviceData: {},
            serviceUuids: [],
            rssi: rssi,
          ),
        ],
        success: true,
        errorCode: 0,
        errorString: '',
      ),
    );
  }
}

class TestContacts extends ContactApi {
  TestContacts() : super(ApiClient('https://example.test/'));
  final startedAddresses = <String>[];
  bool failEnd = false;
  bool conflictOnStart = false;
  List<Contact> contacts = [];
  @override
  Future<List<Contact>> getMyContacts() async => contacts;
  @override
  Future<({String? id, String? mac})> loadActiveSession() async => (
    id: null,
    mac: null,
  );
  @override
  Future<Contact> startContact(String mac) async {
    startedAddresses.add(mac);
    if (conflictOnStart) {
      throw const ContactRequestException('Existing contact', statusCode: 409);
    }
    return Contact(
      id: 'contact-1',
      start: DateTime.now(),
      contactHardwareAddress: mac,
      collarAnimalName: 'Testtracker',
    );
  }

  @override
  Future<Contact> endContact(String id) async {
    if (failEnd) throw StateError('Current GPS unavailable');
    return Contact(id: id, start: DateTime.now(), end: DateTime.now());
  }
}

Future<void> until(bool Function() ready) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (ready()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Expected Bluetooth state was not reached');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final radio = TestCollarRadio();
  FlutterBluePlusPlatform.instance = radio;
  final permissionRequests = <List<int>>[];
  var allowBluetooth = true;
  late TestContacts api;
  late ContactTracingMonitor monitor;
  late ContactTracingCoordinator coordinator;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    radio.starts = 0;
    radio.failStart = false;
    allowBluetooth = true;
    permissionRequests.clear();
    SharedPreferences.setMockInitialValues({
      ContactTracingPreferences.backgroundEnabledKey: true,
    });
    NotificationService.instance.setPushEnabled(false);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter.baseflow.com/permissions/methods'),
          (call) async {
            if (call.method == 'requestPermissions') {
              final ids = List<int>.from(call.arguments as List);
              permissionRequests.add(ids);
              return {for (final id in ids) id: allowBluetooth ? 1 : 4};
            }
            return null;
          },
        );
    api = TestContacts();
    monitor = ContactTracingMonitor(api);
    coordinator = ContactTracingCoordinator(contactApi: api, monitor: monitor);
  });

  tearDown(() async {
    coordinator.dispose();
    await monitor.stop(notify: false);
    await FlutterBluePlus.stopScan();
    monitor.dispose();
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'iPhone requests Apple permission, stays busy and pairs a UUID using a real MAC',
    () async {
      await coordinator.initialize();
      await until(() => radio.starts == 1);
      await coordinator.triggerBackgroundScanNow(force: true);
      expect(
        radio.starts,
        1,
        reason: 'Repeated taps cannot start overlapping scans',
      );
      expect(coordinator.backgroundScanning, isTrue);
      expect(permissionRequests.first, [
        21,
      ], reason: 'Only Apple Bluetooth permission');
      const id = 'e006b3a7-ef7b-4980-a668-1f8005f84383';
      radio.advertise(id);
      await until(() => coordinator.discoveryDevicesSorted.isNotEmpty);
      await FlutterBluePlus.stopScan();
      await until(() => !coordinator.backgroundScanning);
      expect(
        api.startedAddresses,
        isEmpty,
        reason: 'A UUID must never be sent as an EUI-48',
      );
      expect(coordinator.statusMessage, contains('Koppel'));

      final result = coordinator.discoveryDevicesSorted.single;
      await coordinator.registerDevice(
        result,
        hardwareAddress: 'AA:BB:CC:12:34:56',
      );
      expect(api.startedAddresses, ['AA:BB:CC:12:34:56']);
      expect(monitor.hasActiveSession, isTrue);
      expect(monitor.activeDeviceId, id.toUpperCase());
      await until(() => radio.starts >= 2);
      expect(
        monitor.lastSeenAt,
        isNull,
        reason: 'A replay from before contact start is not live evidence',
      );
      radio.advertise(id, rssi: -38);
      await until(() => monitor.lastSeenAt != null);
      expect(monitor.lastAdvertisementRssi, -38);
      expect(monitor.activeContactMac, 'AA:BB:CC:12:34:56');
      final seen = monitor.lastSeenAt;
      radio.advertise('00000000-0000-0000-0000-000000000001', name: 'SP654321');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(
        monitor.lastSeenAt,
        seen,
        reason: 'Another tracker cannot refresh this contact',
      );

      api.failEnd = true;
      await expectLater(coordinator.endAllActiveContacts(), throwsStateError);
      expect(
        monitor.hasActiveSession,
        isTrue,
        reason: 'A failed end cannot hide an active contact',
      );
    },
  );

  test(
    'Android still requests scan/connect/location and auto-registers an EUI-48',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await coordinator.initialize();
      await until(() => radio.starts == 1);
      expect(permissionRequests.first, [28, 30, 5]);
      radio.advertise('AA:BB:CC:12:34:56');
      await until(() => coordinator.discoveryDevicesSorted.isNotEmpty);
      await FlutterBluePlus.stopScan();
      await until(() => monitor.hasActiveSession);
      expect(api.startedAddresses, ['AA:BB:CC:12:34:56']);
    },
  );

  test(
    'denied permission leaves a recoverable status without starting a scan',
    () async {
      allowBluetooth = false;
      await coordinator.initialize();
      await until(
        () =>
            coordinator.needsBluetoothPermission &&
            !coordinator.backgroundScanning,
      );
      expect(radio.starts, 0);
      expect(coordinator.statusMessage, contains('Bluetooth-permissie nodig'));
      expect(api.startedAddresses, isEmpty);
    },
  );

  test(
    'native scan failure remains visible instead of becoming an empty-scan message',
    () async {
      radio.failStart = true;
      await coordinator.initialize();
      await until(() => radio.starts == 1 && !coordinator.backgroundScanning);
      expect(coordinator.statusMessage, contains('Scannen mislukt'));
      expect(coordinator.statusMessage, isNot(contains('Geen collar')));
    },
  );

  test(
    'a server contact without an Apple identity is paired before resuming on conflict',
    () async {
      api.contacts = [
        Contact(
          id: 'existing',
          start: DateTime.now(),
          contactHardwareAddress: 'AA:BB:CC:12:34:56',
          collarAnimalName: 'Testtracker',
        ),
      ];
      api.conflictOnStart = true;
      await coordinator.initialize();
      await until(() => radio.starts == 1);
      expect(monitor.hasActiveSession, isFalse);
      radio.advertise('e006b3a7-ef7b-4980-a668-1f8005f84383');
      await until(() => coordinator.discoveryDevicesSorted.isNotEmpty);
      await FlutterBluePlus.stopScan();
      await until(() => !coordinator.backgroundScanning);
      await coordinator.registerDevice(
        coordinator.discoveryDevicesSorted.single,
        hardwareAddress: 'AA:BB:CC:12:34:56',
      );
      expect(monitor.activeContactId, 'existing');
      expect(monitor.activeDeviceId, 'E006B3A7-EF7B-4980-A668-1F8005F84383');
    },
  );
}
