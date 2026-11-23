import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildgids/widgets/shared_ui_widgets/category_picker.dart';

void main() {
  testWidgets(
    'Categories stay hidden, dismissing preserves selection, and All resets it',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var selected = 'Alle';
      var changes = 0;
      await tester.pumpWidget(
        MaterialApp(
          builder:
              (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.4)),
                child: child!,
              ),
          home: Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: StatefulBuilder(
                  builder:
                      (context, setState) => CategoryPicker(
                        categories: const [
                          'Alle',
                          'Grote grazers',
                          'Hert- en varkensachtigen',
                          'Knaagdieren en insecteneters',
                          'Roofdieren',
                        ],
                        selected: selected,
                        onChanged:
                            (value) => setState(() {
                              selected = value;
                              changes++;
                            }),
                      ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Categorie'), findsOneWidget);
      expect(find.text('Hert- en varkensachtigen'), findsNothing);
      await tester.tap(find.text('Categorie'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Sluiten'));
      await tester.pumpAndSettle();
      expect(changes, 0);
      await tester.tap(find.text('Categorie'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Knaagdieren en insecteneters'),
        100,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(
        find.widgetWithText(ListTile, 'Knaagdieren en insecteneters'),
      );
      await tester.pumpAndSettle();
      expect(selected, 'Knaagdieren en insecteneters');
      expect(find.byType(ListTile), findsNothing);
      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Alle dieren'));
      await tester.pumpAndSettle();
      expect(selected, 'Alle');
      expect(changes, 2);
      expect(find.text('Categorie'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
