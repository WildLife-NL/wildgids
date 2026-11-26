import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/data_managers/api_client.dart';
import 'package:wildgids/data_managers/contact_api.dart';
import 'package:wildgids/screens/profile/bluetooth_contact_settings_screen.dart';
import 'package:wildgids/services/contact_tracing_coordinator.dart';
import 'package:wildgids/services/contact_tracing_monitor.dart';

class ScreenTracing extends ContactTracingCoordinator {
  ScreenTracing({required super.contactApi, required super.monitor});
  bool scanning = false;
  bool permissionNeeded = true;
  String status =
      'Bluetooth-permissie nodig voor scannen (Instellingen → Wild Gids)';
  final results = <ScanResult>[];
  String? pairedAddress;
  @override
  bool get backgroundEnabled => true;
  @override
  bool get backgroundScanning => scanning;
  @override
  bool get needsBluetoothPermission => permissionNeeded;
  @override
  String get statusMessage => status;
  @override
  List<ScanResult> get discoveryDevicesSorted => results;
  @override
  String? hardwareAddressFor(ScanResult result) => null;
  @override
  Future<void> registerDevice(
    ScanResult result, {
    String? hardwareAddress,
  }) async {
    pairedAddress = hardwareAddress;
  }
}

void main() {
  late ScreenTracing tracing;
  late ContactTracingMonitor monitor;
  setUp(() {
    final api = ContactApi(ApiClient('https://example.test/'));
    monitor = ContactTracingMonitor(api);
    tracing = ScreenTracing(contactApi: api, monitor: monitor);
  });
  tearDown(() {
    tracing.dispose();
    monitor.dispose();
  });

  Future<void> show(
    WidgetTester tester, {
    Size size = const Size(375, 812),
    double scale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ChangeNotifierProvider<ContactTracingCoordinator>.value(
        value: tracing,
        child: MaterialApp(
          builder:
              (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                  disableAnimations: true,
                ),
                child: child!,
              ),
          home: const BluetoothContactSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final size in [const Size(375, 812), const Size(812, 375)]) {
    testWidgets('permission recovery fits $size at large text', (tester) async {
      await show(tester, size: size, scale: 2);
      final settings = find.text('Open telefooninstellingen');
      await tester.ensureVisible(settings);
      expect(settings.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      final semantics = tester.ensureSemantics();
      expect(
        tester.getSemantics(settings).label,
        contains('Open telefooninstellingen'),
      );
      semantics.dispose();
    });
  }

  testWidgets(
    'unknown iPhone tracker can be paired with a validated hardware address',
    (tester) async {
      tracing.permissionNeeded = false;
      tracing.status =
          'Tracker gevonden. Koppel de tracker hieronder om contact te starten.';
      tracing.results.add(
        ScanResult(
          device: BluetoothDevice.fromId(
            'e006b3a7-ef7b-4980-a668-1f8005f84383',
          ),
          advertisementData: AdvertisementData(
            advName: 'SP123456',
            txPowerLevel: null,
            appearance: null,
            connectable: true,
            manufacturerData: {
              0x0A61: [1],
            },
            serviceData: {},
            serviceUuids: [],
          ),
          rssi: -45,
          timeStamp: DateTime.now(),
        ),
      );
      await show(tester);
      await tester.scrollUntilVisible(find.text('Koppel tracker'), 400);
      await tester.ensureVisible(find.text('Koppel tracker'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Koppel tracker'));
      await tester.pumpAndSettle();
      expect(find.text('Koppel SP123456'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'AA:BB:CC:65:43:21');
      await tester.tap(find.text('Koppelen'));
      await tester.pumpAndSettle();
      expect(find.textContaining('hoort niet bij'), findsOneWidget);
      expect(tracing.pairedAddress, isNull);
      await tester.enterText(find.byType(TextFormField), 'AA:BB:CC:12:34:56');
      await tester.tap(find.text('Koppelen'));
      await tester.pumpAndSettle();
      expect(tracing.pairedAddress, 'AA:BB:CC:12:34:56');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('large text keeps the tracker name readable above pairing', (
    tester,
  ) async {
    tracing.permissionNeeded = false;
    tracing.results.add(
      ScanResult(
        device: BluetoothDevice.fromId('e006b3a7-ef7b-4980-a668-1f8005f84383'),
        advertisementData: AdvertisementData(
          advName: 'SP123456',
          txPowerLevel: null,
          appearance: null,
          connectable: true,
          manufacturerData: {
            0x0A61: [1],
          },
          serviceData: {},
          serviceUuids: [],
        ),
        rssi: -45,
        timeStamp: DateTime.now(),
      ),
    );
    await show(tester, scale: 2);
    final name = find.text('SP123456');
    final action = find.text('Koppel tracker');
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    expect(action.hitTestable(), findsOneWidget);
    expect(
      tester.getBottomLeft(name).dy,
      lessThan(tester.getTopLeft(action).dy),
    );
    expect(
      tester.getSize(name).height,
      lessThan(60),
      reason: 'Name fits on one line at 2x text',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a scan in progress has visible feedback and a disabled scan button',
    (tester) async {
      tracing.scanning = true;
      tracing.permissionNeeded = false;
      tracing.status = 'Scannen naar collars…';
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ChangeNotifierProvider<ContactTracingCoordinator>.value(
          value: tracing,
          child: const MaterialApp(home: BluetoothContactSettingsScreen()),
        ),
      );
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Scannen…'),
      );
      expect(button.onPressed, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}
