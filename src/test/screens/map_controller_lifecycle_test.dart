import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/providers/app_state_provider.dart';
import 'package:wildgids/providers/map_provider.dart';
import 'package:wildgids/screens/location/kaart_overview_screen.dart';

void main() {
  testWidgets('Overview camera survives a nested location map and reopening', (
    tester,
  ) async {
    const location = MethodChannel('flutter.baseflow.com/geolocator');
    const updates = MethodChannel('flutter.baseflow.com/geolocator_updates');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(location, (call) async {
      if (call.method == 'isLocationServiceEnabled') return true;
      if (call.method == 'checkPermission') return 1;
      throw PlatformException(code: 'PERMISSION_DENIED');
    });
    messenger.setMockMethodCallHandler(updates, (call) async => null);
    final client = MockClient(
      (request) async => http.Response.bytes(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aHfoAAAAASUVORK5CYII=',
        ),
        200,
        headers: {'content-type': 'image/png'},
      ),
    );
    addTearDown(() {
      messenger.setMockMethodCallHandler(location, null);
      messenger.setMockMethodCallHandler(updates, null);
      client.close();
    });
    final map = MapProvider();
    final app = AppStateProvider();
    final navigator = GlobalKey<NavigatorState>();
    Widget harness() => MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: map),
        ChangeNotifierProvider.value(value: app),
      ],
      child: MaterialApp(
        navigatorKey: navigator,
        home: const KaartOverviewScreen(showBottomNav: false),
      ),
    );

    await http.runWithClient(() async {
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();
      final original =
          tester.widget<FlutterMap>(find.byType(FlutterMap)).mapController!;
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder:
              (_) => Scaffold(
                body: FlutterMap(
                  mapController: map.mapController,
                  options: const MapOptions(
                    initialCenter: LatLng(51.44, 5.47),
                    initialZoom: 15,
                  ),
                  children: const [],
                ),
              ),
        ),
      );
      await tester.pumpAndSettle();
      navigator.currentState!.pop();
      await tester.pumpAndSettle();

      // A reporting map must not replace the overview's underlying camera.
      original.move(const LatLng(51.442, 5.472), 16);
      await tester.pumpAndSettle();
      expect(original.camera.center.latitude, closeTo(51.442, 0.00001));
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();
      final reopened =
          tester.widget<FlutterMap>(find.byType(FlutterMap)).mapController!;
      expect(identical(reopened, original), isFalse);
      reopened.move(const LatLng(51.443, 5.473), 16);
      await tester.pumpAndSettle();
      expect(reopened.camera.center.latitude, closeTo(51.443, 0.00001));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    }, () => client);
    map.dispose();
    app.dispose();
  });
}
