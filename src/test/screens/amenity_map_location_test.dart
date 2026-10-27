import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wildgids/managers/map/amenity_map_controller.dart';
import 'package:wildgids/providers/app_state_provider.dart';
import 'package:wildgids/providers/map_provider.dart';
import 'package:wildgids/screens/location/kaart_overview_screen.dart';
import 'package:wildgids/widgets/map/amenity_map_widgets.dart';

void main() {
  test('map initialization does not notify after disposal', () async {
    final map = MapProvider();
    var notifications = 0;
    map.addListener(() => notifications++);

    final initialization = map.initialize();
    expect(notifications, 0);
    map.dispose();
    await initialization;

    expect(notifications, 0);
  });

  testWidgets('map and bundled amenities remain usable with location denied', (
    tester,
  ) async {
    const location = MethodChannel('flutter.baseflow.com/geolocator');
    const updates = MethodChannel('flutter.baseflow.com/geolocator_updates');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(location, (call) async {
      if (call.method == 'isLocationServiceEnabled') return true;
      if (call.method == 'checkPermission') return 1; // denied forever
      throw PlatformException(code: 'PERMISSION_DENIED');
    });
    messenger.setMockMethodCallHandler(updates, (call) async => null);
    final catalogBytes = {
      for (final path in AmenityMapController.parkAssets.values)
        path: File(path).readAsBytesSync(),
    };
    for (final path in catalogBytes.keys) {
      rootBundle.evict(path);
    }
    messenger.setMockMessageHandler('flutter/assets', (message) async {
      if (message != null) {
        final bytes = catalogBytes[utf8.decode(message.buffer.asUint8List())];
        if (bytes != null) return ByteData.sublistView(bytes);
      }
      return null;
    });
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
      messenger.setMockMessageHandler('flutter/assets', null);
      for (final path in catalogBytes.keys) {
        rootBundle.evict(path);
      }
      client.close();
    });
    final map = MapProvider();
    final app = AppStateProvider();
    await http.runWithClient(
      () => tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: map),
            ChangeNotifierProvider.value(value: app),
          ],
          child: const MaterialApp(
            home: KaartOverviewScreen(showBottomNav: false),
          ),
        ),
      ),
      () => client,
    );
    await tester.pumpAndSettle();
    expect(map.currentPosition, isNull);
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.tap(find.byKey(const ValueKey('amenity-filters')));
    await tester.pumpAndSettle();
    expect(find.byType(AmenityFilterSheet), findsOneWidget);
    final filters = tester.widget<AmenityFilterSheet>(
      find.byType(AmenityFilterSheet),
    );
    expect(filters.controller.amenities, hasLength(66));
    await http.runWithClient(
      () => tester.tap(
        find.byKey(const ValueKey('amenity-lab-np-zuid-kennemerland')),
      ),
      () => client,
    );
    await tester.pumpAndSettle();
    expect(map.mapController.camera.center.latitude, closeTo(52.4114, 0.001));
    expect(map.currentPosition, isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    map.dispose();
    app.dispose();
  });
}
