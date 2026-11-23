import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:wildgids/constants/sighting_report_activities.dart';
import 'package:wildgids/data_managers/api_client.dart';
import 'package:wildgids/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:wildgids/managers/waarneming_flow/animal_sighting_reporting_manager.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_model.dart';
import 'package:wildgids/models/beta_models/location_model.dart';
import 'package:wildgids/models/enums/location_source.dart';
import 'package:wildgids/models/enums/animal_count_mode.dart';
import 'package:wildgids/screens/waarneming/location_selection_screen.dart';
import 'package:wildgids/screens/waarneming/location_datetime_screen.dart';
import 'package:wildgids/screens/waarneming/animal_aantal_screen.dart';
import 'package:wildgids/screens/waarneming/animal_activity_screen.dart';
import 'package:wildgids/screens/waarneming/animal_waarneming_details_screen.dart';
import 'package:wildgids/screens/waarneming/animal_waarneming_summary_screen.dart';

AnimalSightingReportingManager reportFixture() {
  final manager = AnimalSightingReportingManager();
  manager.createanimalSighting();
  manager.updateSelectedAnimal(
    AnimalModel(
      animalId: 'deer',
      animalName: 'Damhert',
      animalImagePath: 'assets/images/color-animals/damhert.png',
      genderViewCounts: [],
    ),
  );
  manager.updateLocation(
    LocationModel(
      latitude: 51.44,
      longitude: 5.47,
      source: LocationSource.manual,
    ),
  );
  manager.updateDateTime(DateTime(2026, 11, 6, 12, 30));
  return manager;
}

Widget reportHarness(
  Widget screen,
  AnimalSightingReportingManager manager, {
  double scale = 1,
}) => Provider<AnimalSightingReportingInterface>.value(
  value: manager,
  child: MaterialApp(
    theme: ThemeData(fontFamily: 'Overpass'),
    builder:
        (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
    home: screen,
  ),
);

Future<void> selectActivity(
  WidgetTester tester,
  int index,
  String label,
) async {
  final field = find.byType(DropdownButtonFormField<String>).at(index);
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(of: field, matching: find.byType(DropdownButton<String>)),
  );
  await tester.pumpAndSettle();
  final menu = find.byType(ListView).last;
  final option = find.descendant(of: menu, matching: find.text(label));
  final scrollable =
      find.descendant(of: menu, matching: find.byType(Scrollable)).first;
  await tester.scrollUntilVisible(option, 80, scrollable: scrollable);
  await tester.pumpAndSettle();
  await tester.tap(option);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(
    () async => SightingReportActivityCatalog.load(
      ApiClient('https://example.invalid'),
    ),
  );

  for (final width in [320.0, 390.0]) {
    testWidgets('Count choices fill the card evenly at width $width', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        reportHarness(const AnimalAantalScreen(), reportFixture()),
      );
      await tester.pumpAndSettle();
      final choices = [
        for (final mode in AnimalCountMode.values)
          find.byKey(ValueKey('count-mode-${mode.name}')),
      ];
      await tester.ensureVisible(choices.last);
      await tester.pumpAndSettle();
      final bounds = choices.map(tester.getRect).toList();
      for (var i = 0; i < bounds.length; i++) {
        expect(bounds[i].width, closeTo(bounds.first.width, 1));
        expect(bounds[i].center.dy, closeTo(bounds.first.center.dy, 1));
        expect(bounds[i].height, greaterThanOrEqualTo(48));
        final text = find.descendant(
          of: choices[i],
          matching: find.text(AnimalCountMode.values[i].label),
        );
        expect(tester.getCenter(text).dx, closeTo(bounds[i].center.dx, 1));
      }
      expect(
        tester.getCenter(find.byType(TextField)).dx,
        closeTo(width / 2, 1),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Count and activity are saved before review without changing submission',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final manager = reportFixture();
      await tester.pumpWidget(
        reportHarness(const AnimalAantalScreen(), manager),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Meer dieren'));
      await tester.tap(find.text('Verder'));
      await tester.pumpAndSettle();
      expect(manager.getCurrentanimalSighting()!.animalCount, 2);
      expect(find.byType(AnimalActivityScreen), findsOneWidget);
      await selectActivity(tester, 1, 'Lopen');
      await selectActivity(tester, 0, 'Rusten');
      await tester.tap(find.text('Verder'));
      await tester.pumpAndSettle();
      expect(find.byType(AnimalWaarnemingSummaryScreen), findsOneWidget);
      expect(manager.getCurrentanimalSighting()!.humanActivity, 'walking');
      expect(
        manager.getCurrentanimalSighting()!.perceivedAnimalActivity,
        'resting',
      );
      expect(find.text('Verstuur waarneming'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final mode in [AnimalCountMode.group, AnimalCountMode.unsure]) {
    testWidgets(
      '${mode.name} stays uncounted through review and back navigation',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final manager = reportFixture();
        await tester.pumpWidget(
          reportHarness(const AnimalAantalScreen(), manager),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.widgetWithText(ChoiceChip, mode.label));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ChoiceChip, mode.label));
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsNothing);
        expect(find.text('Details per dier toevoegen'), findsNothing);
        await tester.tap(find.text('Verder'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Verder'));
        await tester.pumpAndSettle();
        expect(find.byType(AnimalWaarnemingSummaryScreen), findsOneWidget);
        expect(find.text(mode.summary(0)), findsOneWidget);
        expect(find.text('0 dieren'), findsNothing);
        expect(manager.getCurrentanimalSighting()!.countMode, mode);
        expect(manager.getCurrentanimalSighting()!.animals, isEmpty);
        await tester.pageBack();
        await tester.pumpAndSettle();
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, mode.label))
              .selected,
          isTrue,
        );
      },
    );
  }

  testWidgets(
    'Exact count can be entered directly; changing it clears stale details',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final manager = reportFixture();
      final current = manager.getCurrentanimalSighting()!;
      manager.updateCurrentanimalSighting(
        current.copyWith(animalCount: 1, animals: [current.animalSelected!]),
      );
      await tester.pumpWidget(
        reportHarness(const AnimalAantalScreen(), manager),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '12');
      await tester.tap(find.text('Verder'));
      await tester.pumpAndSettle();
      expect(manager.getCurrentanimalSighting()!.animalCount, 12);
      expect(
        manager.getCurrentanimalSighting()!.countMode,
        AnimalCountMode.exact,
      );
      expect(manager.getCurrentanimalSighting()!.animals, isEmpty);
      expect(
        tester
            .widget<AnimalActivityScreen>(find.byType(AnimalActivityScreen))
            .totalCount,
        12,
      );
    },
  );

  testWidgets(
    'Other activity requires a description and preserves both answers',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final manager = reportFixture();
      await tester.pumpWidget(
        reportHarness(const AnimalActivityScreen(totalCount: 1), manager),
      );
      await tester.pumpAndSettle();
      await selectActivity(tester, 0, 'Anders, namelijk ...');
      await selectActivity(tester, 1, 'Anders, namelijk ...');
      await tester.tap(find.text('Verder'));
      await tester.pumpAndSettle();
      expect(find.byType(AnimalActivityScreen), findsOneWidget);
      expect(find.text('Vul een toelichting in.'), findsNWidgets(2));
      await tester.enterText(
        find.byType(TextFormField).first,
        'Zwom in het water',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'Zat op een bank',
      );
      await tester.tap(find.text('Verder'));
      await tester.pumpAndSettle();
      final saved = manager.getCurrentanimalSighting()!;
      expect(saved.perceivedAnimalActivityOther, 'Zwom in het water');
      expect(saved.humanActivityOther, 'Zat op een bank');
      expect(find.byType(AnimalWaarnemingSummaryScreen), findsOneWidget);
    },
  );

  testWidgets('Optional per-animal details retain age, sex and condition', (
    tester,
  ) async {
    final manager = reportFixture();
    await tester.pumpWidget(
      reportHarness(
        const AnimalWaarnemingDetailsScreen(animalIndex: 0, totalCount: 1),
        manager,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Volwassen'));
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Vrouwelijk'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Vrouwelijk'));
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Gezond'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Gezond'));
    await tester.tap(find.text('Controleer waarneming'));
    await tester.pumpAndSettle();
    final animal = manager.getCurrentanimalSighting()!.animals!.single;
    expect(animal.viewCount!.volwassenAmount, 1);
    expect(animal.gender.toString(), contains('vrouwelijk'));
    expect(animal.condition.toString(), contains('gezond'));
    expect(find.byType(AnimalWaarnemingSummaryScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(320, 640), const Size(430, 932)]) {
    testWidgets('Every form fits $size with enlarged text', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final pages = <Widget>[
        const LocationSelectionScreen(
          initialLocation: LatLng(51.44, 5.47),
          freezeInitialLocation: true,
        ),
        const LocationDateTimeScreen(selectedLocation: LatLng(51.44, 5.47)),
        const AnimalAantalScreen(),
        const AnimalActivityScreen(totalCount: 1),
        const AnimalWaarnemingDetailsScreen(animalIndex: 0, totalCount: 1),
        const AnimalWaarnemingSummaryScreen(totalCount: 1),
      ];
      for (final page in pages) {
        await tester.pumpWidget(
          reportHarness(page, reportFixture(), scale: 1.4),
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull, reason: '${page.runtimeType}');
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
  }
}
