import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildgids/providers/map_provider.dart';
import 'package:wildgids/screens/game/challenge_screen.dart';

void main() {
  const locationChannel = MethodChannel('flutter.baseflow.com/geolocator');
  final locationCalls = <String>[];
  var permission = 0;

  setUp(() {
    permission = 0;
    locationCalls.clear();
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(locationChannel, (call) async {
          locationCalls.add(call.method);
          if (call.method == 'checkPermission') return permission;
          if (call.method == 'getLastKnownPosition') {
            return {'latitude': 37.7749, 'longitude': -122.4194};
          }
          throw PlatformException(code: 'Unexpected location access');
        });
  });

  Future<void> showHome(
    WidgetTester tester,
    http.Client client, {
    double textScale = 1,
    Key? screenKey,
  }) async {
    await http.runWithClient(
      () => tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => MapProvider(),
          child: MaterialApp(
            builder:
                (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(textScale)),
                  child: child!,
                ),
            home: ChallengeScreen(key: screenKey),
          ),
        ),
      ),
      () => client,
    );
    await tester.pump();
    await tester.pump();
  }

  for (final size in [
    const Size(320, 568),
    const Size(375, 667),
    const Size(430, 932),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'home fits $size with text scale $scale and denied location',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPhysicalSize);
          SharedPreferences.setMockInitialValues({
            'userName': 'Ivet Zhelyazkova',
          });
          await showHome(
            tester,
            MockClient((_) async => http.Response('', 503)),
            textScale: scale,
          );
          await tester.pumpAndSettle();
          expect(find.text('Ivet Zhelyazkova'), findsOneWidget);
          expect(find.text('Yvette'), findsNothing);
          expect(find.text('Eindhoven (standaardlocatie)'), findsOneWidget);
          expect(find.text('Weer niet beschikbaar'), findsOneWidget);
          expect(locationCalls, ['checkPermission']);
          expect(tester.takeException(), isNull);
          await tester.ensureVisible(find.text('Bezoek een nieuwe locatie'));
          await tester.pumpAndSettle();
          expect(
            find.text('Bezoek een nieuwe locatie').hitTestable(),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'does not guess a name from email; permanently denied is handled',
    (tester) async {
      permission = 1;
      SharedPreferences.setMockInitialValues({'email': 'ivet123@example.com'});
      await showHome(
        tester,
        MockClient((_) async => http.Response('invalid JSON', 200)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Yvette'), findsNothing);
      expect(find.textContaining('ivet123'), findsNothing);
      expect(find.text('Eindhoven (standaardlocatie)'), findsOneWidget);
      expect(find.text('Weer niet beschikbaar'), findsOneWidget);
      expect(locationCalls, ['checkPermission']);
    },
  );

  testWidgets('delays the spinner and stops loading after a network timeout', (
    tester,
  ) async {
    final pending = Completer<http.Response>();
    await showHome(tester, MockClient((_) => pending.future));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pump(const Duration(milliseconds: 650));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(seconds: 8));
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Weer niet beschikbaar'), findsOneWidget);
    pending.complete(http.Response('', 503));
    await tester.pump();
  });

  testWidgets('permitted location is used even when address lookup fails', (
    tester,
  ) async {
    permission = 2;
    Uri? requestedUri;
    await showHome(
      tester,
      MockClient((request) async {
        requestedUri = request.url;
        throw http.ClientException('Offline');
      }),
    );
    await tester.pumpAndSettle();
    expect(requestedUri?.queryParameters['latitude'], '37.7749');
    expect(requestedUri?.queryParameters['longitude'], '-122.4194');
    expect(find.text('37.7749, -122.4194'), findsOneWidget);
    expect(find.text('Weer niet beschikbaar'), findsOneWidget);
  });

  testWidgets(
    'reopening home reuses recent weather without another request or spinner',
    (tester) async {
      var requests = 0;
      final client = MockClient((request) async {
        requests++;
        expect(request.url.queryParameters['latitude'], '51.4416');
        expect(request.url.queryParameters['longitude'], '5.4697');
        return http.Response(
          '{"current":{"temperature_2m":16,"weather_code":0,"is_day":1}}',
          200,
        );
      });
      await showHome(tester, client, screenKey: const ValueKey('first'));
      await tester.pumpAndSettle();
      expect(find.text('16°'), findsOneWidget);
      await showHome(tester, client, screenKey: const ValueKey('second'));
      await tester.pumpAndSettle();
      expect(find.text('16°'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(requests, 1);
    },
  );
}
