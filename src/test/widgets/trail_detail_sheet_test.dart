import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:wildgids/models/confirmed_trail_entrance.dart';
import 'package:wildgids/models/park_walking_route.dart';
import 'package:wildgids/services/park_walking_routes_controller.dart';
import 'package:wildgids/widgets/map/trail_detail_sheet.dart';
import '../models/confirmed_trail_entrance_test.dart' show entranceRecord;
import '../models/park_walking_route_test.dart' show routeFixture;

void main() {
  late ParkWalkingRoutesController controller;
  final route = parseParkWalkingRoutes(routeFixture()).single;
  final approved = parseConfirmedTrailEntrances(
    jsonEncode({
      'entrances': [entranceRecord()],
    }),
  );

  setUp(() {
    controller = ParkWalkingRoutesController(
      entranceLoader: () async => approved,
    );
  });
  tearDown(() => controller.dispose());

  Widget app({
    LatLng? location = const LatLng(52.4, 4.6),
    ParkWalkingRoute? selected,
    Future<bool> Function(Uri)? launch,
    Future<bool> Function()? start,
    VoidCallback? close,
    double scale = 1,
  }) => MaterialApp(
    builder:
        (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
    home: Scaffold(
      body: TrailDetailSheet(
        route: selected ?? route,
        controller: controller,
        userLocation: location,
        onClose: close ?? () {},
        launchDirections: launch,
        onStartWalk: start,
      ),
    ),
  );

  Future<void> reveal(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'directions use the confirmed entrance coordinate, never a trail endpoint',
    (tester) async {
      await controller.loadEntrances();
      Uri? launched;
      await tester.pumpWidget(
        app(
          launch: (uri) async {
            launched = uri;
            return true;
          },
        ),
      );
      await reveal(tester, find.byKey(const ValueKey('trail-directions')));
      await tester.tap(find.byKey(const ValueKey('trail-directions')));
      await tester.pumpAndSettle();
      expect(launched?.host, 'www.google.com');
      expect(launched?.queryParameters['destination'], '52.3948644,4.5941305');
      expect(launched?.queryParameters.containsKey('origin'), isFalse);
      expect(launched?.queryParameters['destination'], isNot('52.4,4.6'));
    },
  );

  testWidgets(
    'unmatched paths have distance but no directions, even beside an approved pin',
    (tester) async {
      await controller.loadEntrances();
      final unnamed =
          parseParkWalkingRoutes(
            routeFixture(
              properties: {'OBJECTID': 61, 'naam': 'Onbevestigde route'},
            ),
          ).single;
      await tester.pumpWidget(
        app(selected: unnamed, location: approved.single.point),
      );
      expect(find.text('Geen bevestigde ingang beschikbaar.'), findsOneWidget);
      expect(
        tester
            .widget<OutlinedButton>(
              find.byKey(const ValueKey('trail-directions')),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('trail-user-distance')))
            .data,
        contains('Tot route: circa'),
      );
    },
  );

  testWidgets('missing GPS is honest and a new GPS fix updates distance', (
    tester,
  ) async {
    await tester.pumpWidget(app(location: null));
    expect(
      find.text('Afstand tot route: locatie niet beschikbaar'),
      findsOneWidget,
    );
    await tester.pumpWidget(app(location: const LatLng(51.4416, 5.4697)));
    final far =
        tester
            .widget<Text>(find.byKey(const ValueKey('trail-user-distance')))
            .data;
    await tester.pumpWidget(app(location: const LatLng(52.4, 4.6)));
    final near =
        tester
            .widget<Text>(find.byKey(const ValueKey('trail-user-distance')))
            .data;
    expect(far, isNot(near));
    expect(near, 'Tot route: circa 0 m');
  });

  testWidgets(
    'failed directions stay retryable and repeated taps cannot launch twice',
    (tester) async {
      await controller.loadEntrances();
      final pending = Completer<bool>();
      var calls = 0;
      await tester.pumpWidget(
        app(
          launch: (_) {
            calls++;
            return pending.future;
          },
        ),
      );
      final button = find.byKey(const ValueKey('trail-directions'));
      await reveal(tester, button);
      await tester.tap(button);
      await tester.pump();
      expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
      expect(calls, 1);
      pending.complete(false);
      await tester.pumpAndSettle();
      expect(
        find.text('Google Maps kon niet worden geopend. Probeer opnieuw.'),
        findsOneWidget,
      );
      expect(tester.widget<OutlinedButton>(button).onPressed, isNotNull);
    },
  );

  testWidgets('starting closes only after the shared recorder succeeds', (
    tester,
  ) async {
    var calls = 0;
    var closed = 0;
    await tester.pumpWidget(
      app(start: () async => ++calls > 1, close: () => closed++),
    );
    final button = find.byKey(const ValueKey('trail-start-walk'));
    await reveal(tester, button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(closed, 0);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(closed, 1);
  });

  testWidgets(
    'a narrow phone with large text keeps long names and actions scrollable',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await controller.loadEntrances();
      final long =
          parseParkWalkingRoutes(
            routeFixture(
              properties: {
                'naam': 'Een lange wandelroute door de duinen en langs het bos',
              },
            ),
          ).single;
      await tester.pumpWidget(
        app(selected: long, scale: 2, start: () async => false),
      );
      final button = find.byKey(const ValueKey('trail-start-walk'));
      await reveal(tester, button);
      expect(button.hitTestable(), findsOneWidget);
      expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('the user can choose between explicitly confirmed entrances', (
    tester,
  ) async {
    controller.dispose();
    final entries = parseConfirmedTrailEntrances(
      jsonEncode({
        'entrances': [
          entranceRecord(),
          {
            ...entranceRecord(id: 'bleek'),
            'latitude': 52.4165882,
            'longitude': 4.615041,
          },
        ],
      }),
    );
    controller = ParkWalkingRoutesController(
      entranceLoader: () async => entries,
    );
    await controller.loadEntrances();
    Uri? launched;
    await tester.pumpWidget(
      app(
        launch: (uri) async {
          launched = uri;
          return true;
        },
      ),
    );
    await reveal(tester, find.byKey(const ValueKey('trail-entrance-choice')));
    await tester.tap(find.byKey(const ValueKey('trail-entrance-choice')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ingang bleek').last);
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const ValueKey('trail-directions')));
    await tester.tap(find.byKey(const ValueKey('trail-directions')));
    await tester.pumpAndSettle();
    expect(launched?.queryParameters['destination'], '52.4165882,4.615041');
  });

  testWidgets(
    'entrance loading failure disables directions until a successful retry',
    (tester) async {
      controller.dispose();
      var fail = true;
      controller = ParkWalkingRoutesController(
        entranceLoader: () async {
          if (fail) throw StateError('Asset unavailable');
          return approved;
        },
      );
      await controller.loadEntrances();
      await tester.pumpWidget(app());
      expect(
        tester
            .widget<OutlinedButton>(
              find.byKey(const ValueKey('trail-directions')),
            )
            .onPressed,
        isNull,
      );
      fail = false;
      await tester.tap(find.text('Ingangen opnieuw laden'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<OutlinedButton>(
              find.byKey(const ValueKey('trail-directions')),
            )
            .onPressed,
        isNotNull,
      );
    },
  );
}
