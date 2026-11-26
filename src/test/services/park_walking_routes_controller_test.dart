import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildgids/models/park_walking_route.dart';
import 'package:wildgids/models/park_boundary.dart';
import 'package:wildgids/models/confirmed_trail_entrance.dart';
import 'package:wildgids/services/park_walking_routes_controller.dart';
import '../models/park_walking_route_test.dart' show routeFixture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'the production boundary loader reads the bundled official polygon',
    () async {
      final bytes =
          await File(
            'assets/routes/zuid_kennemerland_boundary.geojson',
          ).readAsBytes();
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMessageHandler('flutter/assets', (message) async {
        expect(
          const StringCodec().decodeMessage(message),
          'assets/routes/zuid_kennemerland_boundary.geojson',
        );
        return ByteData.sublistView(bytes);
      });
      addTearDown(
        () => messenger.setMockMessageHandler('flutter/assets', null),
      );
      final boundary = await loadZuidKennemerlandBoundary();
      expect(boundary.rings, hasLength(6));
      expect(boundary.name, 'Zuid-Kennemerland');
    },
  );

  test('boundary loading retries independently of route visibility', () async {
    var attempts = 0;
    final controller = ParkWalkingRoutesController(
      boundaryLoader: () async {
        if (attempts++ == 0) throw StateError('Unavailable');
        return const ParkBoundary(name: 'Zuid-Kennemerland', rings: []);
      },
    );
    addTearDown(controller.dispose);
    await controller.loadBoundary();
    expect(controller.boundaryFailed, isTrue);
    await controller.loadBoundary();
    expect(controller.boundaryFailed, isFalse);
    expect(controller.boundary?.name, 'Zuid-Kennemerland');
    expect(controller.boundaryEnabled, isTrue);
    expect(controller.enabled, isFalse);
    controller.setBoundaryEnabled(false);
    expect(controller.boundaryEnabled, isFalse);
  });

  test(
    'the production asset loader parses the supplied file in a background isolate',
    () async {
      final bytes =
          await File('assets/routes/park_walking_routes.geojson').readAsBytes();
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMessageHandler('flutter/assets', (message) async {
        final key = const StringCodec().decodeMessage(message);
        expect(key, 'assets/routes/park_walking_routes.geojson');
        return ByteData.sublistView(bytes);
      });
      addTearDown(
        () => messenger.setMockMessageHandler('flutter/assets', null),
      );
      final routes = await loadParkWalkingRoutes();
      expect(routes, hasLength(38));
      expect(routes.first.name, 'Bleek en Berg groen');
    },
  );

  test(
    'concurrent opening loads once; hiding and showing keeps the chosen route',
    () async {
      final pending = Completer<List<ParkWalkingRoute>>();
      var calls = 0;
      final controller = ParkWalkingRoutesController(
        loader: () {
          calls++;
          return pending.future;
        },
      );
      addTearDown(controller.dispose);
      final first = controller.load();
      final second = controller.load();
      pending.complete(parseParkWalkingRoutes(routeFixture()));
      await Future.wait([first, second]);
      expect(calls, 1);
      expect(controller.visibleRoutes, isEmpty);
      controller.showRoute(controller.routes.single);
      expect(controller.visibleRoutes, controller.routes);
      controller.setEnabled(false);
      expect(controller.visibleRoutes, isEmpty);
      controller.setEnabled(true);
      expect(controller.selected, controller.routes.single);
      controller.showRoute(null);
      expect(controller.selected, isNull);
      expect(controller.visibleRoutes, controller.routes);
    },
  );

  test(
    'a failed load can be retried, including a synchronous loader failure',
    () async {
      var calls = 0;
      final controller = ParkWalkingRoutesController(
        loader: () {
          if (calls++ == 0) throw StateError('Unavailable asset');
          return Future.value(parseParkWalkingRoutes(routeFixture()));
        },
      );
      addTearDown(controller.dispose);
      await controller.load();
      expect(controller.failed, isTrue);
      expect(controller.loading, isFalse);
      await controller.load();
      expect(controller.failed, isFalse);
      expect(controller.routes, hasLength(1));
    },
  );

  test(
    'leaving the map during loading does not notify a disposed controller',
    () async {
      final pending = Completer<List<ParkWalkingRoute>>();
      final controller = ParkWalkingRoutesController(
        loader: () => pending.future,
      );
      final loading = controller.load();
      controller.dispose();
      pending.complete(parseParkWalkingRoutes(routeFixture()));
      await loading;
    },
  );
  test(
    'selecting the park shows all trails and selection isolates a trail until returning to all routes',
    () async {
      final routes = [
        ...parseParkWalkingRoutes(routeFixture()),
        ...parseParkWalkingRoutes(
          routeFixture(properties: {'OBJECTID': 2, 'naam': 'Tweede pad'}),
        ),
      ];
      final controller = ParkWalkingRoutesController(
        loader: () async => routes,
        boundaryLoader:
            () async =>
                const ParkBoundary(name: 'Zuid-Kennemerland', rings: []),
        entranceLoader: () async => [],
      );
      addTearDown(controller.dispose);
      await controller.selectLivingLab(
        ParkWalkingRoutesController.zuidKennemerlandId,
      );
      expect(controller.visibleRoutes, routes);
      expect(controller.boundaryEnabled, isTrue);
      controller.showRoute(routes.first);
      expect(controller.visibleRoutes, [routes.first]);
      controller.setEnabled(false);
      expect(controller.visibleRoutes, isEmpty);
      controller.setEnabled(true);
      expect(controller.visibleRoutes, [routes.first]);
      controller.showRoute(null);
      expect(controller.visibleRoutes, routes);
      await controller.selectLivingLab('grenspark-kempenbroek');
      expect(controller.visibleRoutes, isEmpty);
      expect(controller.boundaryEnabled, isFalse);
    },
  );

  test(
    'a late park load cannot reactivate trails after selecting another lab',
    () async {
      final loaded = Completer<List<ParkWalkingRoute>>();
      final controller = ParkWalkingRoutesController(
        loader: () => loaded.future,
        boundaryLoader:
            () async =>
                const ParkBoundary(name: 'Zuid-Kennemerland', rings: []),
        entranceLoader: () async => [],
      );
      addTearDown(controller.dispose);
      final pending = controller.selectLivingLab(
        ParkWalkingRoutesController.zuidKennemerlandId,
      );
      await controller.selectLivingLab('grenspark-kempenbroek');
      loaded.complete(parseParkWalkingRoutes(routeFixture()));
      await pending;
      expect(controller.activeLabId, 'grenspark-kempenbroek');
      expect(controller.visibleRoutes, isEmpty);
    },
  );

  test(
    'entrances require explicit route membership even for neighbouring paths',
    () async {
      final entries = parseConfirmedTrailEntrances(
        File('assets/routes/confirmed_entrances.json').readAsStringSync(),
      );
      final controller = ParkWalkingRoutesController(
        entranceLoader: () async => entries,
      );
      addTearDown(controller.dispose);
      await controller.loadEntrances();
      expect(
        controller
            .entrancesFor(
              parseParkWalkingRoutes(
                routeFixture(properties: {'OBJECTID': 45}),
              ).single,
            )
            .single
            .id,
        'koevlak',
      );
      expect(
        controller.entrancesFor(
          parseParkWalkingRoutes(
            routeFixture(properties: {'OBJECTID': 61}),
          ).single,
        ),
        isEmpty,
      );
    },
  );
}
