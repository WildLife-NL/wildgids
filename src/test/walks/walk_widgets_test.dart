import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/models/walk_recording.dart';
import 'package:wildgids/providers/walk_recorder.dart';
import 'package:wildgids/services/live_location_service.dart';
import 'package:wildgids/widgets/map/walk_map_widgets.dart';

import 'walk_recorder_test.dart' show MemoryWalkStore, fix;

Future<void> settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  // Stream cancellation may complete in the root zone outside Flutter's fake clock.
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 5)),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final size in [const Size(320, 568), const Size(393, 852)]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'walk controls fit $size text $scale; pause, resume and save',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final source = StreamController<Position>.broadcast();
          final recorder = WalkRecorder(
            store: MemoryWalkStore(),
            locations: LiveLocationService(source: (_) => source.stream),
            owner: () async => 'test',
            authorize: () async {},
          );
          await tester.pumpWidget(
            ChangeNotifierProvider.value(
              value: recorder,
              child: MaterialApp(
                builder:
                    (context, child) => MediaQuery(
                      data: MediaQuery.of(
                        context,
                      ).copyWith(textScaler: TextScaler.linear(scale)),
                      child: child!,
                    ),
                home: Scaffold(
                  body: const Placeholder(),
                  bottomNavigationBar: WalkControls(onStarted: () {}),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('start-walk')));
          await tester.pumpAndSettle();
          await tester.tap(
            find.widgetWithText(FilledButton, 'Start wandeling').last,
          );
          await tester.pumpAndSettle();
          expect(recorder.recording, isTrue);
          expect(find.byKey(const ValueKey('walk-sighting')), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.ensureVisible(find.byKey(const ValueKey('stop-walk')));
          await tester.pumpAndSettle();
          expect(
            tester.getRect(find.byKey(const ValueKey('stop-walk'))).bottom,
            lessThanOrEqualTo(size.height),
          );
          await tester.ensureVisible(find.byKey(const ValueKey('pause-walk')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('pause-walk')));
          await settle(tester);
          expect(recorder.recording, isFalse);
          await tester.ensureVisible(find.byKey(const ValueKey('pause-walk')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('pause-walk')));
          await settle(tester);
          expect(recorder.recording, isTrue);
          await tester.ensureVisible(find.byKey(const ValueKey('stop-walk')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('stop-walk')));
          await settle(tester);
          await tester.tap(find.text('Bewaren'));
          await tester.pumpAndSettle();
          expect(recorder.saved, hasLength(1));
          expect(recorder.current, isNull);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          recorder.dispose();
          await source.close();
        },
      );
    }
  }

  for (final zoom in [11.0, 17.0]) {
    testWidgets(
      'route layer keeps matching animal silhouette pins visible at zoom $zoom',
      (tester) async {
        final time = DateTime.utc(2026);
        final walk = WalkRecording(
          id: 'test',
          startedAt: time,
          points: [
            WalkPoint(52, 4, time, newSegment: true),
            WalkPoint(52.0001, 4, time.add(const Duration(seconds: 10))),
            WalkPoint(
              53,
              5,
              time.add(const Duration(minutes: 5)),
              newSegment: true,
            ),
            WalkPoint(53.0001, 5, time.add(const Duration(minutes: 6))),
          ],
          sightings: [
            WalkSighting(id: 's1', name: 'Vos', point: WalkPoint(52, 4, time)),
          ],
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FlutterMap(
                options: MapOptions(
                  initialCenter: walk.points.first.latLng,
                  initialZoom: zoom,
                ),
                children: [WalkMapLayer(walk: walk)],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.widget<PolylineLayer>(find.byType(PolylineLayer)).polylines,
          hasLength(2),
        );
        expect(find.byTooltip('Vos'), findsOneWidget);
        expect(find.byType(Image), findsOneWidget);
        expect(tester.getSize(find.byTooltip('Vos')), const Size(56, 56));
        final image = tester.widget<Image>(find.byType(Image));
        final asset =
            image.image is ResizeImage
                ? (image.image as ResizeImage).imageProvider as AssetImage
                : image.image as AssetImage;
        expect(asset.assetName, contains('icons/animals/'));
        final pin = tester.widget<Material>(
          find.descendant(
            of: find.byTooltip('Vos'),
            matching: find.byType(Material),
          ),
        );
        expect(pin.color, Colors.white);
        expect(
          (pin.shape! as CircleBorder).side,
          const BorderSide(color: Color(0xFF8613A8), width: 3),
        );
        expect(find.byIcon(Icons.visibility), findsNothing);
        await tester.tap(find.byTooltip('Vos'));
        await tester.pumpAndSettle();
        expect(find.text('Vos'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('background lifecycle and another screen do not stop recording', (
    tester,
  ) async {
    final source = StreamController<Position>.broadcast();
    var time = DateTime.now();
    final recorder = WalkRecorder(
      store: MemoryWalkStore(),
      locations: LiveLocationService(source: (_) => source.stream),
      owner: () async => 'test',
      authorize: () async {},
      now: () => time,
    );
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: recorder,
        child: MaterialApp(
          navigatorKey: navigator,
          home: Scaffold(bottomNavigationBar: WalkControls(onStarted: () {})),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await recorder.start();
    await tester.pump();
    source.add(fix(time, 52, 4));
    await tester.pump();
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Formulier')),
      ),
    );
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    time = time.add(const Duration(seconds: 10));
    source.add(fix(time, 52.0001, 4));
    await tester.pump();
    expect(recorder.current!.points, hasLength(2));
    expect(recorder.recording, isTrue);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('walk-sighting')), findsOneWidget);
    final pausing = recorder.pause();
    await settle(tester);
    await pausing;
    await tester.pumpWidget(const SizedBox());
    recorder.dispose();
    await source.close();
  });
}
