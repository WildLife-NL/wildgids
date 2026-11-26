import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wildgids/providers/app_state_provider.dart';
import 'package:wildgids/providers/map_provider.dart';
import 'package:wildgids/screens/location/kaart_overview_screen.dart';
import 'package:wildgids/widgets/map/park_walking_routes.dart';
import 'package:wildgids/models/park_boundary.dart';
import 'package:wildgids/models/park_walking_route.dart';
import 'package:wildgids/services/park_walking_routes_controller.dart';
import 'package:wildgids/widgets/map/trail_detail_sheet.dart';
import 'package:wildgids/utils/trail_geometry.dart';
import 'package:wildgids/providers/walk_recorder.dart';
import 'package:wildgids/models/walk_recording.dart';

class _TrailRecorder extends WalkRecorder {
  bool allowed = false;
  bool running = false;
  WalkRecording? walk;
  @override
  Future<void> initialize() async {}
  @override
  bool get recording => running;
  @override
  WalkRecording? get current => walk;
  @override
  Future<void> start() async {
    if (!allowed) return;
    walk ??= WalkRecording(id: 'local-test', startedAt: DateTime(2026, 11, 22));
    running = true;
    notifyListeners();
  }
}

void main() {
  testWidgets('Overview camera survives a nested location map and reopening', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
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
    final tile = File('assets/app-icon.png').readAsBytesSync();
    final client = MockClient(
      (request) async => http.Response.bytes(
        tile,
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
    final recorder = _TrailRecorder();
    addTearDown(recorder.dispose);
    final app = AppStateProvider();
    final navigator = GlobalKey<NavigatorState>();
    final routes = parseParkWalkingRoutes(
      File('assets/routes/park_walking_routes.geojson').readAsStringSync(),
    );
    final boundary = parseParkBoundary(
      File(
        'assets/routes/zuid_kennemerland_boundary.geojson',
      ).readAsStringSync(),
    );
    Widget harness() => MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: map),
        ChangeNotifierProvider.value(value: app),
        ChangeNotifierProvider<WalkRecorder>.value(value: recorder),
      ],
      child: MaterialApp(
        navigatorKey: navigator,
        home: KaartOverviewScreen(
          showBottomNav: false,
          walkingRoutesController: ParkWalkingRoutesController(
            loader: () async => routes,
            boundaryLoader: () async => boundary,
            entranceLoader: () async => [],
          ),
        ),
      ),
    );

    await http.runWithClient(() async {
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();
      final original =
          tester.widget<FlutterMap>(find.byType(FlutterMap)).mapController!;
      final position = map.currentPosition;
      final selectedPosition = map.selectedPosition;
      expect(find.byType(ParkWalkingRoutesButton), findsNothing);
      await tester.tap(find.byKey(const ValueKey('amenity-filters')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('amenity-lab-np-zuid-kennemerland')),
      );
      await tester.pumpAndSettle();
      final routeControl = tester.widget<ParkWalkingRoutesButton>(
        find.byType(ParkWalkingRoutesButton),
      );
      expect(routeControl.controller.visibleRoutes, hasLength(38));
      await tester.tap(find.byKey(const ValueKey('toggle-park-trails')));
      await tester.pumpAndSettle();
      expect(routeControl.controller.visibleRoutes, isEmpty);
      await tester.tap(find.byKey(const ValueKey('toggle-park-trails')));
      await tester.pumpAndSettle();
      expect(routeControl.controller.visibleRoutes, hasLength(38));
      routeControl.onShowBoundary!(boundary);
      await tester.pumpAndSettle();
      expect(original.camera.center.latitude, inInclusiveRange(52.36, 52.46));
      expect(original.camera.center.longitude, inInclusiveRange(4.52, 4.64));
      final parkZoom = original.camera.zoom;

      final route = parseParkWalkingRoutes(
        File('assets/routes/park_walking_routes.geojson').readAsStringSync(),
      ).firstWhere((route) => route.name == 'Koevlak groen');
      routeControl.controller.showRoute(route);
      routeControl.onShowRoutes([route]);
      await tester.pumpAndSettle();
      expect(routeControl.controller.selected?.name, 'Koevlak groen');
      expect(original.camera.zoom, greaterThan(parkZoom));
      // Browsing the park and a route must never teleport report/tracking GPS.
      expect(map.currentPosition, same(position));
      expect(map.selectedPosition, same(selectedPosition));
      expect(tester.takeException(), isNull);

      final gps = Position(
        latitude: 51.4416,
        longitude: 5.4697,
        timestamp: DateTime.now(),
        accuracy: 5,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      map.currentPosition = gps;
      // A camera/report position in the park must not become the user's distance.
      map.selectedPosition = Position(
        latitude: 52.4,
        longitude: 4.6,
        timestamp: DateTime.now(),
        accuracy: 5,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      final tapPoint = route.segments.first[route.segments.first.length ~/ 3];
      tester.widget<FlutterMap>(find.byType(FlutterMap)).options.onTap!(
        const TapPosition(Offset.zero, Offset.zero),
        tapPoint,
      );
      await tester.pumpAndSettle();
      if (find.text('Welke wandelroute?').evaluate().isNotEmpty) {
        await tester.scrollUntilVisible(
          find.text(route.name),
          120,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(route.name));
        await tester.pumpAndSettle();
      }
      expect(find.byType(TrailDetailSheet), findsOneWidget);
      expect(
        find.text(
          'Tot route: circa ${trailDistanceLabel(distanceToTrailMeters(const LatLng(51.4416, 5.4697), route))}',
        ),
        findsOneWidget,
      );
      expect(routeControl.controller.visibleRoutes, [route]);
      expect(map.currentPosition, same(gps));
      final trailSheet = tester.widget<TrailDetailSheet>(
        find.byType(TrailDetailSheet),
      );
      final beforeStart = original.camera.center;
      final beforeZoom = original.camera.zoom;
      var start = trailSheet.onStartWalk!();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annuleren'));
      await tester.pumpAndSettle();
      expect(await start, isFalse);
      expect(original.camera.center, beforeStart);
      expect(original.camera.zoom, beforeZoom);
      // A failed recorder start also leaves the camera and selection intact.
      start = trailSheet.onStartWalk!();
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(FilledButton, 'Start wandeling'),
        ),
      );
      await tester.pumpAndSettle();
      expect(await start, isFalse);
      expect(original.camera.center, beforeStart);
      expect(original.camera.zoom, beforeZoom);
      // GPS may arrive after recording starts. Never use the park report pin.
      map.currentPosition = null;
      recorder.allowed = true;
      start = trailSheet.onStartWalk!();
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(FilledButton, 'Start wandeling'),
        ),
      );
      await tester.pumpAndSettle();
      expect(await start, isTrue);
      expect(original.camera.center, beforeStart);
      await map.updatePosition(gps, '');
      await tester.pumpAndSettle();
      expect(original.camera.center.latitude, closeTo(gps.latitude, 0.00001));
      expect(original.camera.center.longitude, closeTo(gps.longitude, 0.00001));
      expect(original.camera.zoom, beforeZoom);
      expect(routeControl.controller.visibleRoutes, [route]);
      await tester.tap(find.byTooltip('Sluiten'));
      await tester.pumpAndSettle();
      // Resuming follows GPS while preserving the chosen zoom and existing walk.
      final walk = recorder.current;
      recorder.running = false;
      original.move(const LatLng(52.4, 4.6), 11);
      routeControl.onSelectRoute!(route);
      await tester.pumpAndSettle();
      final resumeSheet = tester.widget<TrailDetailSheet>(
        find.byType(TrailDetailSheet),
      );
      expect(await resumeSheet.onStartWalk!(), isTrue);
      await tester.pumpAndSettle();
      expect(recorder.current, same(walk));
      expect(original.camera.center.latitude, closeTo(gps.latitude, 0.00001));
      expect(original.camera.zoom, 11);
      await tester.tap(find.byTooltip('Sluiten'));
      await tester.pumpAndSettle();
      final movedGps = Position(
        latitude: gps.latitude + 0.0005,
        longitude: gps.longitude,
        timestamp: DateTime.now(),
        accuracy: 5,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 1.4,
        speedAccuracy: 0,
      );
      await map.updatePosition(movedGps, '');
      await tester.pumpAndSettle();
      expect(
        original.camera.center.latitude,
        closeTo(movedGps.latitude, 0.00001),
      );
      expect(original.camera.zoom, 11);
      // A manual pan releases follow, so later GPS cannot pull the camera back.
      await tester.drag(find.byType(FlutterMap), const Offset(90, 0));
      await tester.pumpAndSettle();
      final pannedCenter = original.camera.center;
      expect(pannedCenter, isNot(LatLng(gps.latitude, gps.longitude)));
      await map.updatePosition(gps, '');
      await tester.pumpAndSettle();
      expect(original.camera.center, pannedCenter);
      await tester.tap(find.text('Alle routes'));
      await tester.pumpAndSettle();
      expect(routeControl.controller.visibleRoutes, hasLength(38));
      expect(routeControl.controller.selected, isNull);
      expect(recorder.current, same(walk));
      expect(recorder.recording, isTrue);
      final overviewCenter = original.camera.center;
      await map.updatePosition(gps, '');
      await tester.pumpAndSettle();
      expect(original.camera.center, overviewCenter);
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
      SharedPreferences.setMockInitialValues({
        'home_preferred_living_lab': 'e376995e-5a79-413c-8906-4640dfc2f472',
      });
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ParkWalkingRoutesButton>(
              find.byType(ParkWalkingRoutesButton),
            )
            .controller
            .visibleRoutes,
        hasLength(38),
      );
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
