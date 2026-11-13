import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildgids/models/api_models/my_interaction.dart';
import 'package:wildgids/models/enums/animal_count_mode.dart';
import 'package:wildgids/screens/shared/interaction_detail_screen.dart';

MyInteraction detailFixture({
  AnimalCountMode mode = AnimalCountMode.exact,
  int count = 2,
  int type = 1,
  String name = 'Bever',
}) => MyInteraction.fromJson({
  'ID': 'test',
  'type': {'ID': type},
  'moment': '2026-11-06T12:30:00Z',
  'timestamp': '2026-11-06T13:00:00Z',
  'notes': [
    'Bij het water',
    mode.note,
  ].where((value) => value.isNotEmpty).join('\n'),
  'place': {
    'latitude': 51.44,
    'longitude': 5.47,
    'streetName': 'Parklaan',
    'cityName': 'Eindhoven',
  },
  'location': {'latitude': 51.45, 'longitude': 5.48},
  'species': {
    'ID': 'beaver',
    'commonName': name,
    'name': 'Castor fiber',
    'category': 'Knaagdieren',
    'description': 'Omschrijving uit de bron',
    'behaviour': 'Gedrag uit de bron',
    'advice': 'Advies uit de bron',
    'roleInNature': 'Rol uit de bron',
  },
  'user': {'name': 'Testgebruiker'},
  if (type == 1)
    'reportOfSighting': {
      'involvedAnimals': [
        for (var i = 0; i < count; i++)
          {'sex': 'female', 'lifeStage': 'adult', 'condition': 'healthy'},
      ],
      'humanActivity': 'walking',
      'perceivedAnimalActivity': 'other...',
      'perceivedAnimalActivityOther': 'Zwom in het water',
    },
  if (type == 2)
    'reportOfDamage': {
      'belonging': 'Hek',
      'impactType': 'Gebroken',
      'impactValue': 2,
      'estimatedDamage': 120,
      'estimatedLoss': 30,
    },
  if (type == 3)
    'reportOfCollision': {
      'involvedAnimals': [
        {'sex': 'unknown', 'lifeStage': 'adult', 'condition': 'impaired'},
      ],
      'intensity': 'medium',
      'urgency': 'high',
      'estimatedDamage': 250,
    },
  'questionnaire': {
    'name': 'Ervaringen',
    'identifier': 'questionnaire-123',
    'experiment': {
      'name': 'Onderzoek in het park',
      'description': 'Onderzoeksomschrijving',
      'start': '2026-01-01T12:00:00Z',
      'end': '2027-01-01T12:00:00Z',
      'user': {'name': 'Onderzoeker'},
    },
  },
});

Widget detailHarness(MyInteraction item, {double scale = 1}) => MaterialApp(
  theme: ThemeData(fontFamily: 'Overpass'),
  builder:
      (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
  home: InteractionDetailScreen(interaction: item),
);

void main() {
  for (final mode in [AnimalCountMode.group, AnimalCountMode.unsure]) {
    testWidgets(
      '${mode.name} overrides placeholder animals without inventing a count',
      (tester) async {
        await tester.pumpWidget(
          detailHarness(detailFixture(mode: mode, count: 1)),
        );
        await tester.pumpAndSettle();
        expect(find.text(mode.summary(null)), findsOneWidget);
        expect(find.text('Aantal: 1'), findsNothing);
        expect(find.text('1 dier'), findsNothing);
        expect(find.text('Bij het water'), findsOneWidget);
        expect(find.text(mode.note), findsNothing);
      },
    );
  }

  testWidgets('An empty legacy animal list stays unknown', (tester) async {
    await tester.pumpWidget(detailHarness(detailFixture(count: 0)));
    await tester.pumpAndSettle();
    expect(find.text('Aantal onbekend'), findsOneWidget);
  });

  testWidgets(
    'Details retain report, species, activity and questionnaire information',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(detailHarness(detailFixture()));
      await tester.pumpAndSettle();
      expect(find.text('2 dieren'), findsOneWidget);
      expect(find.text('Castor fiber'), findsOneWidget);
      expect(find.text('Parklaan, Eindhoven'), findsOneWidget);
      expect(find.text('Bij het water'), findsOneWidget);
      await tester.ensureVisible(find.text('Activiteit'));
      expect(find.text('Lopen'), findsOneWidget);
      expect(find.text('Zwom in het water'), findsOneWidget);
      for (final title in [
        'Dierdetails',
        'Over dit dier',
        'Vragenlijst',
        'Meldingsgegevens',
      ]) {
        await tester.ensureVisible(find.text(title));
        await tester.tap(find.text(title));
        await tester.pumpAndSettle();
      }
      expect(find.text('Vrouwelijk · Volwassen · Gezond'), findsNWidgets(2));
      for (final text in [
        'Knaagdieren',
        'Omschrijving uit de bron',
        'Gedrag uit de bron',
        'Advies uit de bron',
        'Rol uit de bron',
        'Ervaringen',
        'questionnaire-123',
        'Onderzoek in het park',
        'Onderzoeksomschrijving',
        'Onderzoeker',
        'Testgebruiker',
      ]) {
        expect(find.text(text), findsWidgets);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Damage and collision records keep their existing fields', (
    tester,
  ) async {
    for (final type in [2, 3]) {
      await tester.pumpWidget(detailHarness(detailFixture(type: type)));
      await tester.pumpAndSettle();
      expect(find.text(type == 2 ? '€120' : '€250'), findsOneWidget);
      expect(find.text(type == 2 ? 'Hek' : 'high'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  for (final size in [const Size(320, 640), const Size(430, 932)]) {
    testWidgets(
      'Expanded details fit $size with enlarged text and a long name',
      (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          detailHarness(detailFixture(name: 'Schotse hooglander'), scale: 1.4),
        );
        await tester.pumpAndSettle();
        for (final title in [
          'Dierdetails',
          'Over dit dier',
          'Vragenlijst',
          'Meldingsgegevens',
        ]) {
          await tester.ensureVisible(find.text(title));
          await tester.tap(find.text(title));
          await tester.pumpAndSettle();
        }
        await tester.ensureVisible(find.text('Testgebruiker'));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
