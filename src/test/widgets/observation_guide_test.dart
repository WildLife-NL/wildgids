import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildgids/config/app_config.dart';
import 'package:wildgids/data_managers/api_client.dart';
import 'package:wildgids/interfaces/data_apis/species_api_interface.dart';
import 'package:wildgids/interfaces/state/navigation_state_interface.dart';
import 'package:wildgids/models/api_models/species.dart';
import 'package:wildgids/providers/app_state_provider.dart';
import 'package:wildgids/screens/logbook/logbook_screen.dart';
import 'package:wildgids/screens/species/species_list_screen.dart';
import 'package:wildgids/screens/waarneming/waarneming_start_screen.dart';
import 'package:wildgids/screens/waarneming/location_selection_screen.dart';
import 'package:wildgids/utils/species_click_tracker.dart';
import 'wildlife_pages_test.dart' show diaryFixtures, guideFixture;

class PreviewApi extends ApiClient {
  PreviewApi() : super('https://example.invalid');
  @override
  Future<http.Response> get(
    String url, {
    Map<String, String>? headers,
    bool authenticated = true,
  }) async => http.Response(
    jsonEncode(diaryFixtures().map((item) => item.toJson()).toList()),
    200,
  );
}

class PreviewAppState extends AppStateProvider {
  @override
  Future<void> updateLocationCache() async {}
}

class PreviewNavigation implements NavigationStateInterface {
  Widget? destination;
  @override
  void pushForward(BuildContext context, Widget screen) => destination = screen;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class PreviewSpeciesApi implements SpeciesApiInterface {
  int calls = 0;
  bool failFirst = false;
  @override
  Future<List<Species>> getAllSpecies() async {
    if (calls++ == 0 && failFirst) throw Exception('offline');
    return [
      guideFixture,
      Species(id: 'hedgehog', commonName: 'Egel', category: 'Zoogdier'),
      Species(id: 'wolf', commonName: 'Wolf', category: 'Roofdieren'),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget observationHarness({PreviewNavigation? navigation, double scale = 1}) =>
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppStateProvider>(
          create: (_) => PreviewAppState(),
        ),
        Provider<NavigationStateInterface>.value(
          value: navigation ?? PreviewNavigation(),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(fontFamily: 'Overpass'),
        builder:
            (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
        home: const WaarnemmingStartScreen(showBottomNav: false),
      ),
    );

void main() {
  setUp(
    () => dotenv.loadFromString(
      envString: 'DEV_BASE_URL=https://example.invalid',
    ),
  );
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'Observation preserves start route, shows older recent sightings and opens diary',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 740));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final original = AppConfig.shared;
      AppConfig.shared = AppConfig(PreviewApi());
      addTearDown(() => AppConfig.shared = original);
      final nav = PreviewNavigation();
      await tester.pumpWidget(observationHarness(navigation: nav, scale: 1.4));
      await tester.pumpAndSettle();
      expect(find.text('Wat heb je gezien?'), findsOneWidget);
      expect(find.text('Damhert'), findsNWidgets(3));
      await tester.ensureVisible(find.text('Waarneming vastleggen'));
      await tester.tap(find.text('Waarneming vastleggen'));
      expect(nav.destination, isA<LocationSelectionScreen>());
      await tester.ensureVisible(find.text('Bekijk je wildlife diary'));
      await tester.tap(find.text('Bekijk je wildlife diary'));
      expect(nav.destination, isA<LogbookScreen>());
      expect((nav.destination as LogbookScreen).openRecentSightings, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Library retries real load and retains filtering, selection and visited tracking',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = PreviewSpeciesApi()..failFirst = true;
      await tester.pumpWidget(
        Provider<SpeciesApiInterface>.value(
          value: api,
          child: const MaterialApp(
            home: SpeciesListScreen(showBottomNav: false),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Opnieuw proberen'));
      await tester.pumpAndSettle();
      expect(api.calls, 2);
      expect(find.text('Damhert'), findsOneWidget);
      expect(find.text('Roofdieren'), findsNothing);
      await tester.tap(find.text('Categorie'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Roofdieren'));
      await tester.pumpAndSettle();
      expect(find.text('Damhert'), findsNothing);
      expect(find.text('Wolf'), findsOneWidget);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Roofdieren'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Zoogdier'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Damhert'));
      await tester.pumpAndSettle();
      expect(find.byType(SpeciesDetailScreen), findsOneWidget);
      expect(find.text(guideFixture.behaviour!), findsOneWidget);
      expect(await SpeciesClickTracker.isClicked('deer'), isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
