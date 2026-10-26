import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildgids/data_managers/api_client.dart';
import 'package:wildgids/providers/map_provider.dart';
import 'package:wildgids/screens/game/challenge_screen.dart';

// Synthetic rectangular boundaries keep existing weather-coordinate assertions exact.
Map<String, Object?> testLab(String id, String name, double lat, double lng) =>
    {
      'ID': id,
      'name': name,
      'definition': [
        {'latitude': lat - .001, 'longitude': lng - .001},
        {'latitude': lat + .001, 'longitude': lng - .001},
        {'latitude': lat + .001, 'longitude': lng + .001},
        {'latitude': lat - .001, 'longitude': lng + .001},
      ],
    };

final testLabs = [
  testLab(
    'e376995e-5a79-413c-8906-4640dfc2f472',
    'Nationaal Park Zuid-Kennemerland',
    52.4114,
    4.5733,
  ),
  testLab(
    '72797cde-25d9-4a36-8b77-7f8d50691ac7',
    'KempenBroek',
    51.1950,
    5.7230,
  ),
];

void main() {
  http.Response weatherResponse(int temperature) => http.Response(
    jsonEncode({
      'current': {
        'temperature_2m': temperature,
        'weather_code': 0,
        'is_day': 1,
      },
    }),
    200,
  );

  const locationChannel = MethodChannel('flutter.baseflow.com/geolocator');
  final locationCalls = <String>[];
  var permission = 0;
  Completer<int>? pendingPermission;
  var positionAge = Duration.zero;
  Map<String, double>? position;

  setUp(() {
    permission = 0;
    pendingPermission = null;
    positionAge = Duration.zero;
    position = {'latitude': 51.4416, 'longitude': 5.4697};
    locationCalls.clear();
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(locationChannel, (call) async {
          locationCalls.add(call.method);
          if (call.method == 'checkPermission') {
            return pendingPermission?.future ?? permission;
          }
          if (call.method == 'getLastKnownPosition') {
            return position == null
                ? null
                : {
                  ...position!,
                  'timestamp':
                      DateTime.now()
                          .subtract(positionAge)
                          .millisecondsSinceEpoch,
                };
          }
          throw PlatformException(code: 'Unexpected location access');
        });
  });

  Future<void> showHome(
    WidgetTester tester,
    http.Client client, {
    double textScale = 1,
    Key? screenKey,
    Future<http.Response> Function()? fetchLabs,
  }) async {
    await http.runWithClient(
      () => tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ApiClient>(create: (_) => ApiClient('https://labs.test')),
            ChangeNotifierProvider(create: (_) => MapProvider()),
          ],
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
      () => MockClient((request) async {
        if (request.url.host == 'labs.test') {
          expect(request.url.path, '/livinglabs/');
          return fetchLabs == null
              ? http.Response(jsonEncode(testLabs), 200)
              : fetchLabs();
        }
        return client.get(request.url, headers: request.headers);
      }),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('all six backend labs are selectable on a small screen', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.reset);
    permission = 2;
    final labs = [
      ...testLabs,
      testLab('botanical', 'Botanische Tuinen', 52.088, 5.171),
      testLab('eindhoven', 'Stadswandelpark Eindhoven', 51.426, 5.482),
      testLab('schutskamp', 'Schutskamppark', 51.698, 5.269),
      testLab('philips', 'Philips de Jongh Wandelpark', 51.457, 5.444),
    ];
    final requestedLatitudes = <String>[];
    final weather = MockClient((request) async {
      requestedLatitudes.add(request.url.queryParameters['latitude']!);
      return weatherResponse(12);
    });
    await showHome(
      tester,
      weather,
      textScale: 2,
      fetchLabs: () async => http.Response(jsonEncode(labs), 200),
    );
    await tester.pumpAndSettle();
    expect(find.text('Stadswandelpark Eindhoven'), findsOneWidget);
    expect(requestedLatitudes, ['51.4260']);
    await tester.ensureVisible(
      find.byKey(const ValueKey('living-lab-selector')),
    );
    await tester.tap(find.byKey(const ValueKey('living-lab-selector')));
    await tester.pumpAndSettle();
    for (final lab in labs) {
      expect(find.byKey(ValueKey('choose-${lab['ID']}')), findsOneWidget);
    }
    final last = find.byKey(const ValueKey('choose-philips'));
    await tester.ensureVisible(last);
    await http.runWithClient(() async {
      await tester.tap(last);
      await tester.pumpAndSettle();
    }, () => weather);
    expect(requestedLatitudes.last, '51.4570');
    expect(
      (await SharedPreferences.getInstance()).getString(
        'home_preferred_living_lab',
      ),
      'philips',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('migrates an existing local selection to the backend ID', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'home_preferred_living_lab': 'grenspark-kempenbroek',
    });
    await showHome(tester, MockClient((_) async => weatherResponse(12)));
    await tester.pumpAndSettle();
    expect(find.text('KempenBroek'), findsOneWidget);
    expect(
      (await SharedPreferences.getInstance()).getString(
        'home_preferred_living_lab',
      ),
      '72797cde-25d9-4a36-8b77-7f8d50691ac7',
    );
  });

  testWidgets(
    'lab without a boundary remains selectable without invented weather',
    (tester) async {
      var weatherCalls = 0;
      await showHome(
        tester,
        MockClient((_) async {
          weatherCalls++;
          return weatherResponse(12);
        }),
        fetchLabs:
            () async => http.Response(
              jsonEncode([
                {
                  'ID': 'missing-location',
                  'name': 'Nieuw living lab',
                  'definition': null,
                },
              ]),
              200,
            ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Nieuw living lab'), findsOneWidget);
      expect(find.text('Gebiedslocatie niet beschikbaar'), findsOneWidget);
      expect(find.text('Weer niet beschikbaar'), findsOneWidget);
      expect(weatherCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'backend failure has a retry and does not fall back to hardcoded labs',
    (tester) async {
      await showHome(
        tester,
        MockClient((_) async => weatherResponse(12)),
        fetchLabs: () async => http.Response('', 503),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Living labs konden niet worden geladen.'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('living-lab-selector')), findsNothing);
      await http.runWithClient(
        () async {
          await tester.tap(find.text('Opnieuw proberen'));
          await tester.pumpAndSettle();
        },
        () => MockClient(
          (request) async =>
              request.url.host == 'labs.test'
                  ? http.Response(jsonEncode(testLabs), 200)
                  : weatherResponse(12),
        ),
      );
      expect(
        find.text('Living labs konden niet worden geladen.'),
        findsNothing,
      );
      expect(find.text('12°'), findsOneWidget);
    },
  );

  testWidgets('empty backend list stays empty', (tester) async {
    await showHome(
      tester,
      MockClient((_) async => weatherResponse(12)),
      fetchLabs: () async => http.Response('[]', 200),
    );
    await tester.pumpAndSettle();
    expect(find.text('Geen living labs beschikbaar.'), findsOneWidget);
    expect(find.byKey(const ValueKey('living-lab-selector')), findsNothing);
  });

  testWidgets('offline list uses labelled backend cache', (tester) async {
    final client = MockClient((_) async => weatherResponse(12));
    await showHome(tester, client);
    await tester.pumpAndSettle();
    await showHome(
      tester,
      client,
      screenKey: const ValueKey('offline'),
      fetchLabs: () async => http.Response('', 503),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Opgeslagen living labs; bijwerken mislukt.'),
      findsOneWidget,
    );
    expect(find.text('Nationaal Park Zuid-Kennemerland'), findsOneWidget);
    expect(find.text('12°'), findsOneWidget);
  });

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
            'userName': 'ivetojeliazkova9 Lange Gebruikersnaam',
          });
          await showHome(
            tester,
            MockClient((_) async => http.Response('', 503)),
            textScale: scale,
          );
          await tester.pumpAndSettle();
          expect(
            find.text('ivetojeliazkova9 Lange Gebruikersnaam'),
            findsOneWidget,
          );
          expect(find.text('Yvette'), findsNothing);
          expect(find.text('Wild Gids'), findsOneWidget);
          final badgeColors = <Color>{};
          for (final label in ['Bos', 'Dieren', 'Foto', 'Vergrendeld']) {
            final badge = find.byKey(ValueKey('home-badge-$label'));
            final surface = tester.widget<Container>(badge);
            final decoration = surface.decoration! as BoxDecoration;
            final icon = tester.widget<Icon>(
              find.descendant(of: badge, matching: find.byType(Icon)),
            );
            badgeColors.add(decoration.color!);
            expect(decoration.shape, BoxShape.circle);
            expect(
              (decoration.color!.computeLuminance() + 0.05) /
                  (icon.color!.computeLuminance() + 0.05),
              greaterThanOrEqualTo(3),
            );
            if (label == 'Vergrendeld') {
              expect(icon.icon, Icons.lock_outline_rounded);
            }
          }
          expect(badgeColors.length, 4);
          expect(find.text('Locked'), findsNothing);
          for (final label in ['Waarneming', 'Leer over dieren']) {
            final title = find.text(label);
            final foreground = tester.widget<Text>(title).style!.color!;
            final ink = tester.widget<Ink>(
              find.ancestor(of: title, matching: find.byType(Ink)).first,
            );
            final gradient =
                (ink.decoration! as BoxDecoration).gradient! as LinearGradient;
            expect(foreground, ChallengeScreen.deepGreen);
            expect(gradient.colors.first, const Color(0xFFF0F5E9));
            for (final background in gradient.colors) {
              final light = foreground.computeLuminance();
              final dark = background.computeLuminance();
              final contrast =
                  light > dark
                      ? (light + 0.05) / (dark + 0.05)
                      : (dark + 0.05) / (light + 0.05);
              expect(contrast, greaterThanOrEqualTo(4.5));
            }
          }
          for (final action in [
            ('Waarneming', 'assets/real_animal_pics_no_bg/real_eekhoorn.png'),
            ('Leer over dieren', 'assets/real_animal_pics_no_bg/real_egel.png'),
          ]) {
            final animal = find.byWidgetPredicate(
              (widget) =>
                  widget is Image &&
                  widget.image is AssetImage &&
                  (widget.image as AssetImage).assetName == action.$2,
            );
            expect(tester.widget<Image>(animal).opacity?.value, 1.0);
            expect(
              tester
                  .getRect(find.text(action.$1))
                  .overlaps(tester.getRect(animal)),
              isFalse,
            );
          }
          expect(find.text('Nationaal Park Zuid-Kennemerland'), findsOneWidget);
          expect(find.text('Locatie niet beschikbaar'), findsOneWidget);
          expect(find.text('Weer niet beschikbaar'), findsOneWidget);
          expect(locationCalls, ['checkPermission']);
          expect(tester.takeException(), isNull);
          await tester.ensureVisible(
            find.byKey(const ValueKey('living-lab-selector')),
          );
          await tester.tap(find.byKey(const ValueKey('living-lab-selector')));
          await tester.pumpAndSettle();
          expect(find.text('KempenBroek'), findsOneWidget);
          expect(
            find.descendant(
              of: find.byKey(
                const ValueKey('choose-e376995e-5a79-413c-8906-4640dfc2f472'),
              ),
              matching: find.text('Nationaal Park Zuid-Kennemerland'),
            ),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          Navigator.of(tester.element(find.text('Kies je living lab'))).pop();
          await tester.pumpAndSettle();
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
      expect(find.text('Locatie niet beschikbaar'), findsOneWidget);
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

  testWidgets('Eindhoven selects KempenBroek and requests weather at the lab', (
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
    expect(requestedUri?.queryParameters['latitude'], '51.1950');
    expect(requestedUri?.queryParameters['longitude'], '5.7230');
    expect(find.text('KempenBroek'), findsOneWidget);
    expect(find.textContaining('km hemelsbreed'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            (widget.properties.label?.startsWith(
                  'Dichtstbijzijnde living lab:',
                ) ??
                false),
      ),
      findsOneWidget,
    );
    expect(find.text('Weer niet beschikbaar'), findsOneWidget);
  });

  testWidgets(
    'reopening home reuses recent weather without another request or spinner',
    (tester) async {
      var requests = 0;
      final client = MockClient((request) async {
        requests++;
        expect(request.url.queryParameters['latitude'], '52.4114');
        expect(request.url.queryParameters['longitude'], '4.5733');
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

  Future<void> chooseLab(
    WidgetTester tester,
    http.Client client,
    String id,
  ) async {
    await tester.ensureVisible(
      find.byKey(const ValueKey('living-lab-selector')),
    );
    await tester.tap(find.byKey(const ValueKey('living-lab-selector')));
    await tester.pumpAndSettle();
    await http.runWithClient(() async {
      final option = find.byKey(ValueKey('choose-$id'));
      await tester.ensureVisible(option);
      await tester.tap(option);
      await tester.pump();
    }, () => client);
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('Haarlem selects Zuid-Kennemerland', (tester) async {
    permission = 2;
    position = {'latitude': 52.3874, 'longitude': 4.6462};
    await showHome(
      tester,
      MockClient((request) async {
        expect(request.url.queryParameters['latitude'], '52.4114');
        expect(request.url.queryParameters['longitude'], '4.5733');
        return weatherResponse(14);
      }),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nationaal Park Zuid-Kennemerland'), findsOneWidget);
    expect(find.text('± 6 km hemelsbreed'), findsOneWidget);
  });

  testWidgets(
    'selection works without GPS, remembers preference and caches each lab',
    (tester) async {
      var requests = 0;
      final client = MockClient((request) async {
        requests++;
        return weatherResponse(
          request.url.queryParameters['latitude'] == '52.4114' ? 14 : 19,
        );
      });
      await showHome(tester, client);
      await tester.pumpAndSettle();
      expect(find.text('14°'), findsOneWidget);
      await chooseLab(tester, client, '72797cde-25d9-4a36-8b77-7f8d50691ac7');
      expect(find.text('19°'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              (widget.properties.label?.startsWith('Jouw living lab:') ??
                  false),
        ),
        findsOneWidget,
      );
      expect(
        (await SharedPreferences.getInstance()).getString(
          'home_preferred_living_lab',
        ),
        '72797cde-25d9-4a36-8b77-7f8d50691ac7',
      );
      await showHome(tester, client, screenKey: const ValueKey('reopen'));
      await tester.pumpAndSettle();
      expect(find.text('KempenBroek'), findsOneWidget);
      expect(find.text('19°'), findsOneWidget);
      await chooseLab(tester, client, 'e376995e-5a79-413c-8906-4640dfc2f472');
      expect(find.text('14°'), findsOneWidget);
      expect(requests, 2);
    },
  );

  testWidgets(
    'manual choice overrides nearest until automatic mode is selected',
    (tester) async {
      permission = 2;
      SharedPreferences.setMockInitialValues({
        'home_preferred_living_lab': 'e376995e-5a79-413c-8906-4640dfc2f472',
      });
      final client = MockClient(
        (request) async => weatherResponse(
          request.url.queryParameters['latitude'] == '52.4114' ? 14 : 19,
        ),
      );
      await showHome(tester, client);
      await tester.pumpAndSettle();
      expect(find.text('Nationaal Park Zuid-Kennemerland'), findsOneWidget);
      await chooseLab(tester, client, 'nearest-lab');
      expect(find.text('KempenBroek'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              (widget.properties.label?.startsWith(
                    'Dichtstbijzijnde living lab:',
                  ) ??
                  false),
        ),
        findsOneWidget,
      );
      expect(
        (await SharedPreferences.getInstance()).containsKey(
          'home_preferred_living_lab',
        ),
        isFalse,
      );
    },
  );

  testWidgets(
    'late response from previous lab cannot replace selected lab weather',
    (tester) async {
      final first = Completer<http.Response>();
      final second = Completer<http.Response>();
      final client = MockClient(
        (request) =>
            request.url.queryParameters['latitude'] == '52.4114'
                ? first.future
                : second.future,
      );
      await showHome(tester, client);
      await chooseLab(tester, client, '72797cde-25d9-4a36-8b77-7f8d50691ac7');
      second.complete(weatherResponse(19));
      await tester.pumpAndSettle();
      expect(find.text('19°'), findsOneWidget);
      first.complete(weatherResponse(14));
      await tester.pumpAndSettle();
      expect(find.text('KempenBroek'), findsOneWidget);
      expect(find.text('19°'), findsOneWidget);
      expect(find.text('14°'), findsNothing);
    },
  );

  for (final age in [20, 120]) {
    testWidgets('failed refresh handles a $age minute old cache honestly', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'home_lab_weather_e376995e-5a79-413c-8906-4640dfc2f472': jsonEncode({
          'temperature': 14,
          'code': 0,
          'isDay': true,
          'fetchedAt':
              DateTime.now().subtract(Duration(minutes: age)).toIso8601String(),
        }),
      });
      await showHome(tester, MockClient((_) async => http.Response('', 503)));
      await tester.pumpAndSettle();
      if (age == 20) {
        expect(find.text('14°'), findsOneWidget);
        expect(
          find.text('Laatst opgehaald; bijwerken mislukt'),
          findsOneWidget,
        );
      } else {
        expect(find.text('14°'), findsNothing);
        expect(find.text('Weer niet beschikbaar'), findsOneWidget);
      }
    });
  }

  testWidgets('invalid saved lab and cache recover to a real lab', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'home_preferred_living_lab': 'removed-lab',
      'home_lab_weather_e376995e-5a79-413c-8906-4640dfc2f472': 'broken json',
    });
    await showHome(tester, MockClient((_) async => weatherResponse(14)));
    await tester.pumpAndSettle();
    expect(find.text('Nationaal Park Zuid-Kennemerland'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            (widget.properties.label?.startsWith(
                  'Living lab · standaardkeuze:',
                ) ??
                false),
      ),
      findsOneWidget,
    );
    expect(find.text('14°'), findsOneWidget);
  });

  testWidgets('manual choice is not overwritten when location arrives later', (
    tester,
  ) async {
    pendingPermission = Completer<int>();
    final client = MockClient((request) async => weatherResponse(14));
    await showHome(tester, client);
    await chooseLab(tester, client, 'e376995e-5a79-413c-8906-4640dfc2f472');
    pendingPermission!.complete(2);
    await tester.pumpAndSettle();
    expect(find.text('Nationaal Park Zuid-Kennemerland'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            (widget.properties.label?.startsWith('Jouw living lab:') ?? false),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('km hemelsbreed'), findsOneWidget);
  });

  testWidgets('stale location does not pretend to be the current location', (
    tester,
  ) async {
    permission = 2;
    positionAge = const Duration(days: 2);
    await showHome(tester, MockClient((_) async => weatherResponse(14)));
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            (widget.properties.label?.startsWith(
                  'Living lab · standaardkeuze:',
                ) ??
                false),
      ),
      findsOneWidget,
    );
    expect(find.text('Locatie niet beschikbaar'), findsOneWidget);
    expect(find.text('14°'), findsOneWidget);
  });

  for (final scenario in [
    (code: 0, day: 1, icon: Icons.wb_sunny_rounded, label: 'Zonnig'),
    (code: 0, day: 0, icon: Icons.nightlight_round, label: 'Helder'),
    (code: 3, day: 1, icon: Icons.cloud_rounded, label: 'Bewolkt'),
    (code: 61, day: 1, icon: Icons.water_drop_rounded, label: 'Regenachtig'),
    (code: 45, day: 1, icon: Icons.foggy, label: 'Mistig'),
    (code: 71, day: 1, icon: Icons.ac_unit_rounded, label: 'Sneeuw'),
    (code: 95, day: 1, icon: Icons.thunderstorm_rounded, label: 'Onweer'),
  ]) {
    testWidgets('weather displays ${scenario.label} from the API', (
      tester,
    ) async {
      await showHome(
        tester,
        MockClient(
          (_) async => http.Response(
            jsonEncode({
              'current': {
                'temperature_2m': 12,
                'weather_code': scenario.code,
                'is_day': scenario.day,
              },
            }),
            200,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(scenario.label), findsOneWidget);
      expect(
        tester
            .widget<Icon>(find.byKey(const ValueKey('home-weather-icon')))
            .icon,
        scenario.icon,
      );
      expect(find.text('Wild Gids'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsNothing);
    });
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets('example notice opens and closes on a small screen at $scale', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await showHome(
        tester,
        MockClient((_) async => weatherResponse(14)),
        textScale: scale,
      );
      await tester.pumpAndSettle();
      final notice = find.byKey(const ValueKey('home-announcement'));
      await tester.ensureVisible(notice);
      await tester.tap(notice);
      await tester.pumpAndSettle();
      expect(find.text('Voorbeeldmelding'), findsOneWidget);
      expect(
        find.textContaining('De afsluiting is niet bevestigd'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Sluiten'));
      await tester.pumpAndSettle();
      expect(find.text('Voorbeeldmelding'), findsNothing);
      expect(find.byType(ChallengeScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
