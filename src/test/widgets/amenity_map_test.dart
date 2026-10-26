import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:wildgids/managers/map/amenity_map_controller.dart';
import 'package:wildgids/models/ui_models/map_amenity.dart';
import 'package:wildgids/widgets/map/amenity_map_widgets.dart';

class _Bundle extends CachingAssetBundle {
  _Bundle(this.source);
  String source;
  String kempenSource = '[]';
  Completer<String>? pending;
  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    expect(AmenityMapController.parkAssets.values, contains(key));
    if (key == AmenityMapController.parkAssets['grenspark-kempenbroek']) {
      return kempenSource;
    }
    return pending?.future ?? source;
  }

  @override
  Future<ByteData> load(String key) => throw UnimplementedError();
}

void main() {
  final sourcePath = AmenityMapController.parkAssets['np-zuid-kennemerland']!;
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Bundle bundle;
  late AmenityMapController controller;

  setUp(() {
    bundle = _Bundle(File(sourcePath).readAsStringSync());
    controller = AmenityMapController(bundle: bundle);
  });
  tearDown(() => controller.dispose());

  test(
    'categories have distinct high-contrast colours and mixed groups are neutral',
    () {
      final colors = AmenityCategory.values.map(amenityColor).toSet();
      expect(colors, hasLength(AmenityCategory.values.length));
      for (final color in colors) {
        expect(
          1.05 / (color.computeLuminance() + 0.05),
          greaterThanOrEqualTo(4.5),
        );
        expect(amenityClusterColor([color, color]), color);
      }
      expect(amenityClusterColor(colors), const Color(0xFF3E484D));
    },
  );

  test(
    'loads bundled data without networking or location; filters all categories',
    () async {
      await controller.load();
      expect(controller.error, isNull);
      expect(controller.visibleAmenities, hasLength(61));
      controller.setCategory(AmenityCategory.parking, false);
      expect(controller.visibleAmenities, hasLength(48));
      controller.setAllCategories(false);
      expect(controller.visibleAmenities, isEmpty);
      controller.setCategory(AmenityCategory.toilet, true);
      expect(controller.visibleAmenities, hasLength(2));
      controller.setAllCategories(true);
      expect(controller.visibleAmenities, hasLength(61));
    },
  );

  test('malformed JSON exposes a recoverable error without throwing', () async {
    bundle.source = '{broken';
    await controller.load();
    expect(controller.error, isNotNull);
    expect(controller.isLoading, isFalse);
    expect(controller.visibleAmenities, isEmpty);
    bundle.source = File(sourcePath).readAsStringSync();
    await controller.load();
    expect(controller.error, isNull);
    expect(controller.visibleAmenities, hasLength(61));
    bundle.source = '{}';
    await controller.load();
    expect(controller.error, isNotNull);
    expect(controller.visibleAmenities, hasLength(61));
  });

  test(
    'unsupported proposed category keeps previously loaded points',
    () async {
      await controller.load();
      bundle.kempenSource = '''[
      {"type":"Picknickplaats","name":"Picknickplek 1","latitude":51.2,"longitude":5.7}
    ]''';
      await controller.load();
      expect(controller.error, isNotNull);
      expect(controller.visibleAmenities, hasLength(61));
      bundle.kempenSource = '[]';
      await controller.load();
      expect(controller.error, isNull);
    },
  );

  test(
    'loads new KempenBroek entries and keeps valid data if either file breaks',
    () async {
      bundle.kempenSource = '''[
      {"type":"toilet","name":"Test toilet","latitude":51.2,"longitude":5.7}
    ]''';
      await controller.load();
      expect(controller.amenities, hasLength(62));
      expect(controller.amenities.last.livingLabId, 'grenspark-kempenbroek');
      expect(controller.amenities.last.name, 'Test toilet');
      expect(controller.amenities.map((a) => a.id).toSet(), hasLength(62));
      bundle.kempenSource = '{broken';
      await controller.load();
      expect(controller.error, isNotNull);
      expect(controller.amenities, hasLength(62));
    },
  );

  test('late asset load is safe after controller disposal', () async {
    final pendingController = AmenityMapController(bundle: bundle);
    bundle.pending = Completer<String>();
    final load = pendingController.load();
    pendingController.dispose();
    bundle.pending!.complete(bundle.source);
    await load;
  });

  Future<void> showMap(
    WidgetTester tester, {
    LatLng center = const LatLng(52.4114, 4.5733),
    double zoom = 12,
  }) async {
    await controller.load();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: zoom,
              maxZoom: 17.5,
            ),
            children: [AmenityMapLayer(controller: controller)],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('clusters amenities separately and removes filtered clusters', (
    tester,
  ) async {
    await showMap(tester);
    expect(find.byType(MarkerClusterLayerWidget), findsOneWidget);
    expect(find.byKey(const ValueKey('amenity-cluster')), findsWidgets);
    controller.setAllCategories(false);
    await tester.pumpAndSettle();
    expect(find.byType(MarkerClusterLayerWidget), findsNothing);
    controller.setCategory(AmenityCategory.toilet, true);
    await tester.pumpAndSettle();
    final layer = tester.widget<MarkerClusterLayerWidget>(
      find.byType(MarkerClusterLayerWidget),
    );
    expect(layer.options.markers, hasLength(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping an amenity shows its Dutch name and exact coordinates', (
    tester,
  ) async {
    await controller.load();
    controller.setAllCategories(false);
    controller.setCategory(AmenityCategory.toilet, true);
    await showMap(
      tester,
      center: const LatLng(52.3960819, 4.592633),
      zoom: 17.5,
    );
    final amenity = controller.amenities.singleWhere(
      (a) => a.name == 'Openbaar toilet Duincafé',
    );
    final face = find.byKey(ValueKey('amenity-face-${amenity.id}'));
    expect(tester.getSize(face), const Size(36, 36));
    expect(
      (tester.widget<Container>(face).decoration as BoxDecoration).shape,
      BoxShape.circle,
    );
    expect(
      tester.getSize(find.byKey(ValueKey('amenity-${amenity.id}'))),
      const Size(44, 44),
    );
    await tester.tap(find.byKey(ValueKey('amenity-${amenity.id}')));
    await tester.pumpAndSettle();
    expect(find.byType(AmenityDetailSheet), findsOneWidget);
    expect(find.text(amenity.name), findsOneWidget);
    expect(find.text('52.3960819, 4.592633'), findsOneWidget);
    await tester.tap(find.byTooltip('Sluiten'));
    await tester.pumpAndSettle();
    expect(find.byType(AmenityDetailSheet), findsNothing);
  });

  for (final size in [const Size(320, 568), const Size(430, 932)]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('filters and details fit $size at text scale $scale', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        await controller.load();
        String? chosenLab;
        await tester.pumpWidget(
          MaterialApp(
            builder:
                (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
            home: Scaffold(
              body: Center(
                child: AmenityMapControl(
                  controller: controller,
                  onViewLab: (lab) => chosenLab = lab.id,
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.byKey(const ValueKey('amenity-filters')));
        await tester.pumpAndSettle();
        expect(find.text('Voorzieningen'), findsOneWidget);
        expect(find.text('Bekijk op kaart'), findsNothing);
        expect(find.text('Nog geen voorzieningen toegevoegd'), findsNothing);
        for (final lab in controller.labs) {
          final labFinder = find.byKey(ValueKey('amenity-lab-${lab.id}'));
          await tester.scrollUntilVisible(
            labFinder,
            100,
            scrollable: find.byType(Scrollable),
          );
          final tile = tester.widget<ListTile>(labFinder);
          expect((tile.title! as Text).data, lab.name);
          expect(tile.subtitle, isNull);
        }
        expect(tester.takeException(), isNull);
        final toilet = find.byKey(const ValueKey('amenity-category-toilet'));
        await tester.scrollUntilVisible(
          toilet,
          150,
          scrollable: find.byType(Scrollable),
        );
        await Scrollable.ensureVisible(tester.element(toilet), alignment: 0.5);
        await tester.pumpAndSettle();
        await tester.tap(toilet);
        await tester.pumpAndSettle();
        expect(
          controller.enabledCategories,
          isNot(contains(AmenityCategory.toilet)),
        );
        final last = find.byKey(
          const ValueKey('amenity-category-point_of_interest'),
        );
        await tester.scrollUntilVisible(
          last,
          150,
          scrollable: find.byType(Scrollable),
        );
        await Scrollable.ensureVisible(tester.element(last), alignment: 0.5);
        await tester.pumpAndSettle();
        await tester.tap(last);
        await tester.pumpAndSettle();
        expect(
          controller.enabledCategories,
          isNot(contains(AmenityCategory.pointOfInterest)),
        );
        expect(tester.takeException(), isNull);
        final lab = find.byKey(
          const ValueKey('amenity-lab-grenspark-kempenbroek'),
        );
        await tester.scrollUntilVisible(
          lab,
          -150,
          scrollable: find.byType(Scrollable),
        );
        await Scrollable.ensureVisible(tester.element(lab), alignment: 0.5);
        await tester.pumpAndSettle();
        await tester.tap(lab);
        await tester.pumpAndSettle();
        expect(chosenLab, 'grenspark-kempenbroek');
        expect(find.byType(AmenityFilterSheet), findsNothing);
        await tester.pumpWidget(
          MaterialApp(
            builder:
                (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
            home: Scaffold(
              body: AmenityDetailSheet(amenity: controller.amenities.last),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
    'filter sheet shows errors and retries without blocking map controls',
    (tester) async {
      bundle.source = 'broken';
      await controller.load();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AmenityFilterSheet(controller: controller, onViewLab: (_) {}),
          ),
        ),
      );
      expect(
        find.text('Voorzieningen konden niet worden geladen.'),
        findsOneWidget,
      );
      bundle.source = File(sourcePath).readAsStringSync();
      await tester.tap(find.byTooltip('Opnieuw proberen'));
      await tester.pumpAndSettle();
      expect(controller.error, isNull);
      expect(
        find.text('Voorzieningen konden niet worden geladen.'),
        findsNothing,
      );
    },
  );
}
