import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:wildgids/models/walk_recording.dart';
import 'package:wildgids/widgets/map/walk_map_widgets.dart';

void main() {
  final start = DateTime.utc(2026, 11, 8, 12);

  WalkRecording kilometreWalk() {
    final end = const Distance().offset(const LatLng(52, 4), 1000, 0);
    return WalkRecording(
      id: 'pace',
      startedAt: start,
      finishedAt: start.add(const Duration(hours: 1)),
      activeMilliseconds: const Duration(minutes: 20).inMilliseconds,
      points: [
        WalkPoint(52, 4, start, newSegment: true),
        WalkPoint(
          end.latitude,
          end.longitude,
          start.add(const Duration(minutes: 20)),
        ),
      ],
    );
  }

  test(
    'Pace uses active time rather than the hour between start and finish',
    () {
      final walk = kilometreWalk();
      expect(walk.averagePace!.inSeconds, closeTo(1200, 1));
      expect(walkPace(walk), '20:00 min/km');
      final restored = WalkRecording.fromJson(walk.toJson());
      expect(restored.averagePace, walk.averagePace);
    },
  );

  test(
    'Missing, short and zero-duration routes do not show an invented pace',
    () {
      final empty = WalkRecording(id: 'empty', startedAt: start);
      final short = WalkRecording(
        id: 'short',
        startedAt: start,
        activeMilliseconds: 60000,
        points: [WalkPoint(52, 4, start), WalkPoint(52.0001, 4, start)],
      );
      expect(walkPace(empty), '—');
      expect(walkPace(short), '—');
      final zero = WalkRecording(
        id: 'zero',
        startedAt: start,
        points: kilometreWalk().points,
      );
      expect(walkPace(zero), '—');
    },
  );

  for (final scale in [1.0, 2.0]) {
    testWidgets('Finish summary fits a narrow dialog at text scale $scale', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          builder:
              (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
          home: Builder(
            builder:
                (context) => Scaffold(
                  body: TextButton(
                    onPressed:
                        () => showDialog<void>(
                          context: context,
                          builder:
                              (_) => AlertDialog(
                                scrollable: true,
                                title: const Text('Wandeling afronden'),
                                content: SizedBox(
                                  width: 340,
                                  child: WalkStats(
                                    walk: kilometreWalk(),
                                    elapsed: const Duration(minutes: 20),
                                    summary: true,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Bewaren'),
                                  ),
                                ],
                              ),
                        ),
                    child: const Text('Afronden'),
                  ),
                ),
          ),
        ),
      );
      await tester.tap(find.text('Afronden'));
      await tester.pumpAndSettle();
      expect(find.text('Gemiddeld tempo'), findsOneWidget);
      expect(find.text('20:00 min/km'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Bewaren'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });
  }
}
