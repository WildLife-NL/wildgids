import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:wildgids/constants/app_colors.dart';
import 'package:wildgids/models/park_walking_route.dart';
import 'package:wildgids/models/park_boundary.dart';
import 'package:wildgids/services/park_walking_routes_controller.dart';
import 'package:wildgids/widgets/map/park_walking_routes.dart';
import '../models/park_walking_route_test.dart' show routeFixture;

Widget routesHarness(
  ParkWalkingRoutesController controller,
  ValueChanged<List<ParkWalkingRoute>> onShow, {
  ValueChanged<ParkBoundary>? onShowBoundary,
  double textScale = 1,
  bool dark = false,
}) => MaterialApp(
  theme: dark ? ThemeData.dark() : ThemeData.light(),
  builder:
      (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
        ),
        child: child!,
      ),
  home: Scaffold(
    body: Stack(
      children: [
        FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(52.4, 4.6),
            initialZoom: 14,
          ),
          children: [
            ZuidKennemerlandBoundaryLayer(controller: controller),
            ParkWalkingRoutesLayer(controller: controller),
          ],
        ),
        Positioned(
          top: 32,
          left: 14,
          right: 84,
          child: Align(
            alignment: Alignment.topLeft,
            child: ParkWalkingRoutesButton(
              controller: controller,
              onShowRoutes: onShow,
              onShowBoundary: onShowBoundary,
            ),
          ),
        ),
      ],
    ),
  ),
);

const boundaryFixture = ParkBoundary(
  name: 'Zuid-Kennemerland',
  rings: [
    [
      LatLng(52.39, 4.59),
      LatLng(52.39, 4.71),
      LatLng(52.51, 4.71),
      LatLng(52.51, 4.59),
      LatLng(52.39, 4.59),
    ],
  ],
);

Future<void> reveal(WidgetTester tester, Finder target) async {
  final scrollable =
      find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first;
  await tester.scrollUntilVisible(target, 120, scrollable: scrollable);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'the park border is visible without routes and can be hidden or fitted',
    (tester) async {
      final controller = ParkWalkingRoutesController(
        loader: () async => parseParkWalkingRoutes(routeFixture()),
        boundaryLoader: () async => boundaryFixture,
      );
      addTearDown(controller.dispose);
      await controller.loadBoundary();
      ParkBoundary? fitted;
      await tester.pumpWidget(
        routesHarness(
          controller,
          (_) {},
          onShowBoundary: (boundary) => fitted = boundary,
        ),
      );
      PolylineLayer border() => tester.widget<PolylineLayer>(
        find.descendant(
          of: find.byType(ZuidKennemerlandBoundaryLayer),
          matching: find.byType(PolylineLayer),
        ),
      );
      expect(controller.enabled, isFalse);
      expect(border().polylines, hasLength(1));
      expect(border().polylines.single.isDotted, isTrue);
      expect(
        border().polylines.single.points.first,
        border().polylines.single.points.last,
      );
      await tester.tap(find.text('Wandelroutes'));
      await tester.pumpAndSettle();
      expect(find.text('Zuid-Kennemerland'), findsOneWidget);
      await tester.tap(find.widgetWithText(SwitchListTile, 'Toon parkgrens'));
      await tester.pump();
      expect(border().polylines, isEmpty);
      await tester.tap(find.text('Bekijk het park op de kaart'));
      await tester.pumpAndSettle();
      expect(fitted?.name, 'Zuid-Kennemerland');
      expect(border().polylines, hasLength(1));
      expect(controller.enabled, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a supplied route can be chosen with large text and the keyboard open',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(375, 812);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final controller = ParkWalkingRoutesController(
        boundaryLoader: () async => boundaryFixture,
        loader:
            () async => parseParkWalkingRoutes(
              File(
                'assets/routes/park_walking_routes.geojson',
              ).readAsStringSync(),
            ),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(routesHarness(controller, (_) {}, textScale: 2));
      await tester.tap(find.text('Wandelroutes'));
      await tester.pumpAndSettle();
      await reveal(tester, find.byType(TextField));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Koevlak');
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pumpAndSettle();
      final scrollable =
          find
              .descendant(
                of: find.byType(CustomScrollView),
                matching: find.byType(Scrollable),
              )
              .first;
      await tester.scrollUntilVisible(
        find.text('Koevlak groen'),
        160,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Koevlak groen'));
      await tester.pumpAndSettle();
      expect(controller.selected?.name, 'Koevlak groen');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'search selects a real path; separate parts draw and the switch removes the layer',
    (tester) async {
      final controller = ParkWalkingRoutesController(
        boundaryLoader: () async => boundaryFixture,
        loader: () async => parseParkWalkingRoutes(routeFixture()),
      );
      addTearDown(controller.dispose);
      List<ParkWalkingRoute>? fitted;
      await tester.pumpWidget(
        routesHarness(controller, (routes) => fitted = routes),
      );
      expect(
        tester
            .widget<PolylineLayer>(
              find.descendant(
                of: find.byType(ParkWalkingRoutesLayer),
                matching: find.byType(PolylineLayer),
              ),
            )
            .polylines,
        isEmpty,
      );
      await tester.tap(find.text('Wandelroutes'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'does not exist');
      await tester.pump();
      expect(find.text('Geen routes gevonden.'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Duinpad');
      await tester.pump();
      final routeTile = find.widgetWithText(ListTile, 'Duinpad');
      await tester.ensureVisible(routeTile);
      await tester.tap(routeTile);
      await tester.pumpAndSettle();
      expect(fitted?.single.id, '1');
      expect(find.text('Wandelroutes aan'), findsOneWidget);
      final lines =
          tester
              .widget<PolylineLayer>(
                find.descendant(
                  of: find.byType(ParkWalkingRoutesLayer),
                  matching: find.byType(PolylineLayer),
                ),
              )
              .polylines;
      expect(lines, hasLength(2));
      expect(lines.first.points.last, const LatLng(52.4, 4.601));
      expect(lines.last.points.first, const LatLng(52.5, 4.7));
      await tester.tap(find.text('Wandelroutes aan'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(SwitchListTile, 'Toon wandelroutes'),
      );
      await tester.pump();
      await tester.tap(find.byTooltip('Sluiten'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<PolylineLayer>(
              find.descendant(
                of: find.byType(ParkWalkingRoutesLayer),
                matching: find.byType(PolylineLayer),
              ),
            )
            .polylines,
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('the sheet shows a recoverable error instead of an empty map', (
    tester,
  ) async {
    var attempts = 0;
    final controller = ParkWalkingRoutesController(
      boundaryLoader: () async => boundaryFixture,
      loader: () async {
        if (attempts++ == 0) throw StateError('Missing asset');
        return parseParkWalkingRoutes(routeFixture());
      },
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(routesHarness(controller, (_) {}));
    await tester.tap(find.text('Wandelroutes'));
    await tester.pumpAndSettle();
    expect(
      find.text('De wandelroutes konden niet worden geladen.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Opnieuw proberen'));
    await tester.pumpAndSettle();
    expect(find.text('Duinpad'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final scenario in [
    (const Size(375, 812), 1.0, false),
    (const Size(812, 375), 1.0, false),
    (const Size(375, 812), 2.0, false),
    (const Size(430, 932), 2.0, true),
  ]) {
    testWidgets(
      'routes are scrollable at ${scenario.$1}, text ${scenario.$2}, dark ${scenario.$3}',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = scenario.$1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = ParkWalkingRoutesController(
          boundaryLoader: () async => boundaryFixture,
          loader:
              () async => parseParkWalkingRoutes(
                routeFixture(
                  properties: {
                    'naam':
                        'Een lange wandelroute door de duinen en langs het bos',
                    'naamingang': 'Een uitgebreide ingangsnaam',
                  },
                ),
              ),
        );
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          routesHarness(
            controller,
            (_) {},
            textScale: scenario.$2,
            dark: scenario.$3,
          ),
        );
        await tester.tap(find.text('Wandelroutes'));
        await tester.pumpAndSettle();
        await reveal(
          tester,
          find.text('Kies een route om deze op de kaart te bekijken.'),
        );
        expect(
          DefaultTextStyle.of(
            tester.element(
              find.text('Kies een route om deze op de kaart te bekijken.'),
            ),
          ).style.color,
          AppColors.darkCharcoal,
        );
        await reveal(tester, find.byType(TextField));
        await tester.tap(find.byType(TextField));
        await tester.pump();
        await reveal(
          tester,
          find.text('Een lange wandelroute door de duinen en langs het bos'),
        );
        expect(tester.takeException(), isNull);
        await tester.tap(
          find.text('Een lange wandelroute door de duinen en langs het bos'),
        );
        await tester.pumpAndSettle();
        expect(controller.enabled, isTrue);
      },
    );
  }
}
