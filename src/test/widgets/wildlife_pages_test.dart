import 'package:wildgids/models/enums/animal_count_mode.dart';
import 'package:wildgids/screens/shared/interaction_detail_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:wildgids/data_managers/api_client.dart';
import 'package:wildgids/screens/logbook/logbook_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildgids/models/api_models/my_interaction.dart';
import 'package:wildgids/models/api_models/species.dart';
import 'package:wildgids/screens/logbook/wildlife_diary_screen.dart';
import 'package:wildgids/screens/species/species_detail_screen.dart';

List<MyInteraction> diaryFixtures() {
  final now = DateTime.now();
  return [
    for (var i = 0; i < 4; i++)
      MyInteraction.fromJson({
        'ID': 'sighting-$i',
        'moment': DateTime(now.year, now.month, 2, 12).toIso8601String(),
        'species': {
          'ID': 'deer',
          'commonName': 'Damhert',
          'category': 'Zoogdier',
        },
        'type': {'ID': 1},
        'reportOfSighting': {
          'involvedAnimals': [<String, dynamic>{}, <String, dynamic>{}],
        },
        'place': {'latitude': 52.3, 'longitude': 4.8},
      }),
    MyInteraction.fromJson({
      'ID': 'previous',
      'moment': DateTime(now.year, now.month - 1, 2, 12).toIso8601String(),
      'species': {'ID': 'fox', 'commonName': 'Vos'},
      'type': {'ID': 1},
    }),
    MyInteraction.fromJson({
      'ID': 'damage',
      'moment': DateTime(now.year, now.month, 2).toIso8601String(),
      'species': {'ID': 'wolf', 'commonName': 'Wolf'},
      'type': {'ID': 2},
    }),
  ];
}

final guideFixture = Species(
  id: 'deer',
  commonName: 'Damhert',
  category: 'Zoogdier',
  latinName: 'Dama dama',
  behaviour: 'Gedrag uit de bestaande informatie.',
  description: 'Omschrijving uit de bestaande informatie.',
  roleInNature: 'Rol uit de bestaande informatie.',
  advice: 'Advies uit de bestaande informatie.',
);

class _DiaryApiClient extends ApiClient {
  _DiaryApiClient() : super('https://example.invalid');

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

void main() {
  testWidgets(
    'Recent reports opens diary directly and returns to the same logbook',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        Provider<ApiClient>.value(
          value: _DiaryApiClient(),
          child: const MaterialApp(home: LogbookScreen(showBottomNav: false)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Your Wildlife Diary'), findsNothing);
      expect(find.text('Open je dagboek'), findsNothing);
      expect(find.text('Recente meldingen'), findsOneWidget);
      expect(find.text('Contacten'), findsOneWidget);
      expect(find.text('Mijn antwoorden'), findsOneWidget);
      expect(find.text('Opgeslagen'), findsOneWidget);
      await tester.tap(find.text('Recente meldingen'));
      await tester.pumpAndSettle();
      expect(find.text('Your Wildlife Diary'), findsOneWidget);
      expect(find.text('Damhert · 2 dieren'), findsNWidgets(3));
      expect(find.byType(ChoiceChip), findsNothing);
      expect(find.text('Schade'), findsNothing);
      await tester.tap(find.byTooltip('Type melding: Waarnemingen').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Schade'));
      await tester.pumpAndSettle();
      expect(find.text('Wolf'), findsOneWidget);
      expect(find.text('Schademelding'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Recente meldingen'), findsOneWidget);
      expect(find.text('Your Wildlife Diary'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Compact diary filter and entry navigation retain an uncertain count',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 740));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final original = diaryFixtures().first;
      final uncertain = MyInteraction.fromJson({
        ...original.toJson(),
        'notes': AnimalCountMode.unsure.note,
        'reportOfSighting': {'involvedAnimals': []},
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'Overpass'),
          builder:
              (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.4)),
                child: child!,
              ),
          home: WildlifeDiaryScreen(
            onTabSelected: (_) {},
            showReportFilters: true,
            loadSightings: () async => [uncertain],
          ),
        ),
      );
      await tester.pumpAndSettle();
      final semantics = tester.ensureSemantics();
      try {
        await tester.pump();
        expect(
          find.bySemanticsLabel('Type melding: Waarnemingen'),
          findsOneWidget,
        );
      } finally {
        semantics.dispose();
      }
      final filter = find.byTooltip('Type melding: Waarnemingen').last;
      await tester.tap(filter);
      await tester.pumpAndSettle();
      expect(find.text('Alle meldingen'), findsOneWidget);
      await tester.tap(find.byTooltip('Sluiten'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Type melding: Waarnemingen'), findsWidgets);
      await tester.ensureVisible(find.text('Damhert · Onzeker'));
      await tester.tap(find.text('Damhert · Onzeker'));
      await tester.pumpAndSettle();
      expect(find.byType(InteractionDetailScreen), findsOneWidget);
      expect(find.text('Aantal onbekend'), findsOneWidget);
      expect(find.text('Aantal: 1'), findsNothing);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Damhert · Onzeker'), findsOneWidget);
      expect(find.byTooltip('Type melding: Waarnemingen'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Diary filters sightings and months, and expands the full diary',
    (tester) async {
      tester.view.resetPhysicalSize();
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: WildlifeDiaryScreen(
            onTabSelected: (_) {},
            loadSightings: () async => diaryFixtures(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Damhert · 2 dieren'), findsNWidgets(3));
      expect(find.text('Wolf'), findsNothing);
      expect(find.text('4 ontmoetingen · 1 soort deze maand'), findsOneWidget);
      await tester.ensureVisible(find.text('Bekijk volledig dagboek'));
      await tester.tap(find.text('Bekijk volledig dagboek'));
      await tester.pumpAndSettle();
      expect(find.text('Damhert · 2 dieren'), findsNWidgets(4));
      await tester.ensureVisible(find.byType(OutlinedButton));
      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();
      final tiles = find.byType(ListTile);
      await tester.tap(tiles.last);
      await tester.pumpAndSettle();
      expect(find.text('Vos'), findsOneWidget);
      expect(find.text('Damhert · 2 dieren'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Diary recovers from loading failure', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: WildlifeDiaryScreen(
          onTabSelected: (_) {},
          loadSightings: () async {
            if (calls++ == 0) throw Exception('offline');
            return [];
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Je dagboek kon niet worden geladen.'), findsOneWidget);
    await tester.tap(find.text('Opnieuw proberen'));
    await tester.pumpAndSettle();
    expect(find.text('Nog geen ontmoetingen in deze maand.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Guide retains all source content and handles enlarged text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        builder:
            (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!,
            ),
        home: SpeciesDetailScreen(species: guideFixture),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(guideFixture.behaviour!), findsOneWidget);
    await tester.ensureVisible(find.text('Over dit dier'));
    await tester.tap(find.text('Over dit dier'));
    await tester.pumpAndSettle();
    expect(find.text(guideFixture.description!), findsOneWidget);
    await tester.ensureVisible(find.text('Rol in de natuur'));
    await tester.tap(find.text('Rol in de natuur'));
    await tester.pumpAndSettle();
    expect(find.text(guideFixture.roleInNature!), findsOneWidget);
    await tester.ensureVisible(find.text(guideFixture.advice!));
    expect(find.text(guideFixture.advice!), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
