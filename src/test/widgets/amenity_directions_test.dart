import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildgids/models/ui_models/map_amenity.dart';
import 'package:wildgids/widgets/map/amenity_map_widgets.dart';

void main() {
  const channel = MethodChannel('plugins.flutter.io/url_launcher');
  const amenity = MapAmenity(
    id: 'test-toilet',
    livingLabId: 'np-zuid-kennemerland',
    name: 'Openbaar toilet Duincafé',
    category: AmenityCategory.toilet,
    latitude: 52.3960819,
    longitude: 4.592633,
  );
  final calls = <MethodCall>[];
  var succeeds = true;
  var throwsError = false;
  Completer<bool>? pending;

  setUp(() {
    calls.clear();
    succeeds = true;
    throwsError = false;
    pending = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (throwsError) throw PlatformException(code: 'launch_failed');
          return pending?.future ?? succeeds;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<void> showDetails(WidgetTester tester) => tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(body: AmenityDetailSheet(amenity: amenity)),
    ),
  );
  final button = find.byKey(const ValueKey('open-google-maps'));
  const error = 'Google Maps kon niet worden geopend. Probeer het opnieuw.';

  testWidgets('fictional locations are labelled and cannot launch directions', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AmenityDetailSheet(
            amenity: MapAmenity(
              id: 'example',
              livingLabId: 'grenspark-kempenbroek',
              name: 'Voorbeeldtoilet 1',
              category: AmenityCategory.toilet,
              latitude: 51.193,
              longitude: 5.68,
              isExample: true,
            ),
          ),
        ),
      ),
    );
    expect(find.textContaining('Fictieve voorbeeldlocatie'), findsOneWidget);
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(calls, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'opens external Google Maps walking directions without an origin or key',
    (tester) async {
      await showDetails(tester);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(calls, hasLength(1));
      expect(calls.single.method, 'launch');
      final arguments = calls.single.arguments as Map;
      final uri = Uri.parse(arguments['url'] as String);
      expect(uri.scheme, 'https');
      expect(uri.host, 'www.google.com');
      expect(uri.path, '/maps/dir/');
      expect(uri.queryParameters, {
        'api': '1',
        'destination': '52.3960819,4.592633',
        'travelmode': 'walking',
      });
      expect(arguments['useSafariVC'], isFalse);
      expect(arguments['useWebView'], isFalse);
      expect(arguments['universalLinksOnly'], isFalse);
      expect(find.text(error), findsNothing);
      expect(find.text(amenity.name), findsOneWidget);
    },
  );

  for (final exception in [false, true]) {
    testWidgets(
      'failed launch (exception: $exception) stays open and can retry',
      (tester) async {
        succeeds = false;
        throwsError = exception;
        await showDetails(tester);
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(find.text(error), findsOneWidget);
        expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
        succeeds = true;
        throwsError = false;
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(calls, hasLength(2));
        expect(find.text(error), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'prevents duplicate launches and tolerates closing during launch',
    (tester) async {
      pending = Completer<bool>();
      await showDetails(tester);
      await tester.tap(button);
      await tester.pump();
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      await tester.tap(button);
      expect(calls, hasLength(1));
      await tester.pumpWidget(const SizedBox.shrink());
      pending!.complete(true);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
