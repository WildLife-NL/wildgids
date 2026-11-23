import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/interfaces/reporting/interaction_interface.dart';
import 'package:wildgids/interfaces/reporting/reportable_interface.dart';
import 'package:wildgids/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:wildgids/managers/waarneming_flow/animal_sighting_reporting_manager.dart';
import 'package:wildgids/models/beta_models/interaction_response_model.dart';
import 'package:wildgids/models/beta_models/location_model.dart';
import 'package:wildgids/models/enums/interaction_type.dart';
import 'package:wildgids/models/enums/location_source.dart';
import 'package:wildgids/providers/app_state_provider.dart';
import 'package:wildgids/providers/map_provider.dart';
import 'package:wildgids/providers/walk_recorder.dart';
import 'package:wildgids/screens/location/location_screen.dart';
import 'package:wildgids/screens/waarneming/location_selection_screen.dart';
import 'package:wildgids/screens/waarneming/walk_sighting_flow.dart';
import 'package:wildgids/services/live_location_service.dart';
import 'package:wildgids/utils/sighting_submit_navigation.dart';
import 'package:wildgids/widgets/map/walk_map_widgets.dart';

import 'walk_recorder_test.dart' show MemoryWalkStore, fix;
import 'walk_widgets_test.dart' show settle;

class TestInteraction implements InteractionInterface {
  InteractionResponse? result;
  @override
  Future<InteractionResponse?> postInteraction(
    Reportable report,
    InteractionType type,
  ) async => result;
}

void main() {
  testWidgets(
    'open and cancel sighting preserves recording and captured point',
    (tester) async {
      final source = StreamController<Position>.broadcast();
      var now = DateTime.now();
      final recorder = WalkRecorder(
        store: MemoryWalkStore(),
        locations: LiveLocationService(source: (_) => source.stream),
        owner: () async => 'test',
        authorize: () async {},
        now: () => now,
      );
      final manager = AnimalSightingReportingManager();
      final app = AppStateProvider();
      final map = MapProvider();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: recorder),
            ChangeNotifierProvider.value(value: app),
            ChangeNotifierProvider.value(value: map),
            Provider<AnimalSightingReportingInterface>.value(value: manager),
          ],
          child: MaterialApp(
            home: Scaffold(bottomNavigationBar: WalkControls(onStarted: () {})),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await recorder.start();
      await tester.pump();
      source.add(fix(now, 52, 4));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('walk-sighting')));
      await tester.pumpAndSettle();
      final screen = tester.widget<LocationSelectionScreen>(
        find.byType(LocationSelectionScreen),
      );
      expect(screen.initialLocation!.latitude, 52);
      expect(screen.freezeInitialLocation, isTrue);
      now = now.add(const Duration(seconds: 10));
      source.add(fix(now, 52.0001, 4));
      await tester.pump();
      expect(recorder.current!.points, hasLength(2));
      expect(
        tester
            .widget<LocationSelectionScreen>(
              find.byType(LocationSelectionScreen),
            )
            .initialLocation!
            .latitude,
        52,
      );
      expect(find.text('Wandeling wordt opgenomen'), findsOneWidget);
      await tester.tap(find.byTooltip('Terug naar wandeling'));
      await tester.pumpAndSettle();
      expect(recorder.recording, isTrue);
      expect(recorder.current!.sightings, isEmpty);
      expect(find.byKey(const ValueKey('walk-sighting')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('walk-sighting')));
      await tester.pumpAndSettle();
      navigateAfterSightingSubmit(
        tester.element(find.byType(LocationSelectionScreen)),
        InteractionResponse.empty(interactionID: 'navigation-test'),
        showSuccessToast: false,
      );
      await tester.pumpAndSettle();
      expect(find.byType(LocationSelectionScreen), findsNothing);
      expect(recorder.recording, isTrue);
      final pause = recorder.pause();
      await settle(tester);
      await pause;
      await tester.pumpWidget(const SizedBox());
      recorder.dispose();
      app.dispose();
      map.dispose();
      await source.close();
    },
  );

  testWidgets(
    'existing submit pipeline links only successful reports at corrected location',
    (tester) async {
      final source = StreamController<Position>.broadcast();
      final recorder = WalkRecorder(
        store: MemoryWalkStore(),
        locations: LiveLocationService(source: (_) => source.stream),
        owner: () async => 'test',
        authorize: () async {},
      );
      final manager = AnimalSightingReportingManager();
      manager.createanimalSighting();
      manager.updateLocation(
        LocationModel(
          latitude: 52,
          longitude: 4,
          source: LocationSource.system,
        ),
      );
      manager.updateLocation(
        LocationModel(
          latitude: 52.0002,
          longitude: 4.0003,
          source: LocationSource.manual,
        ),
      );
      final moment = DateTime.utc(2026, 10, 24);
      manager.updateDateTime(moment);
      await recorder.start();
      await tester.pump();
      final session = WalkSightingSession(
        walkId: recorder.current!.id,
        recorder: recorder,
        close: () {},
      );
      late BuildContext reportContext;
      await tester.pumpWidget(
        Provider.value(
          value: session,
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                reportContext = context;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      final api = TestInteraction();
      expect(await submitReport(manager, api, reportContext), isNull);
      expect(recorder.current!.sightings, isEmpty);
      api.result = InteractionResponse.empty(interactionID: 'saved-report');
      await submitReport(manager, api, reportContext);
      final sighting = recorder.current!.sightings.single;
      expect(sighting.point.latitude, 52.0002);
      expect(sighting.point.longitude, 4.0003);
      expect(sighting.point.time, moment);
      expect(recorder.recording, isTrue);
      final pause = recorder.pause();
      await settle(tester);
      await pause;
      await tester.pumpWidget(const SizedBox());
      recorder.dispose();
      await source.close();
    },
  );
}
