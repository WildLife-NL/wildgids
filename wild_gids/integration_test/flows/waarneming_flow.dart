import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildrapport/screens/shared/overzicht_screen.dart';
import '../tests/questionnaire_flow.dart' as questionnaire_flow;
import 'package:wildrapport/main.dart' as app;

void runTests() {
  group('End-to-end tests for Gewasschade reporting flow', () {
    testWidgets('User can navigate and complete the Gewasschade reporting flow', (WidgetTester tester) async {
      // Ensure environment is loaded
      await dotenv.load(fileName: '.env');

      // Verify bearer token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('bearer_token');
      expect(token, isNotNull, reason: 'Bearer token must be set for API authentication');
      
      app.main();

      // Wait for the app to settle (main.dart has run)
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Debug widget tree
      debugPrint(tester.allWidgets.map((w) => w.toString()).toList().join('\n'));
      
      // Verify OverzichtScreen is displayed
      expect(find.byType(OverzichtScreen), findsOneWidget, reason: 'OverzichtScreen should be displayed after login or app start');

      // Step 1: Verify and tap 'Rapporteren'
      expect(find.byKey(const Key('rapporteren_button')), findsOneWidget, reason: 'Rapporteren button should be visible');
      await tester.tap(find.byKey(const Key('rapporteren_button')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Step 2: Verify Gewasschade screen and tap 'Gewasschade'
      expect(find.text('Waarnemingen'), findsOneWidget);
      await tester.tap(find.text('Waarnemingen'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text('Evenhoevigen'), findsOneWidget);
      await tester.tap(find.text('Evenhoevigen'));
      debugPrint("[WaarnemingFlowTest]: Tapped Evenhoevigen");
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text('Wisent'), findsOneWidget);
      await tester.tap(find.text('Wisent'));
      debugPrint("[WaarnemingFlowTest]: Tapped Wisent");
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text('Volwassen'), findsOneWidget);
      expect(find.text('Mannelijk'), findsOneWidget);
      expect(find.text('+'), findsOneWidget);
      expect(find.text('Voeg toe aan de lijst'), findsOneWidget);

      await tester.tap(find.text('Volwassen'));
      debugPrint("[WaarnemingFlowTest]: Tapped Volwassen");
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.text('Mannelijk'));
      debugPrint("[WaarnemingFlowTest]: Tapped Mannelijk");
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.text('+'));
      debugPrint("[WaarnemingFlowTest]: Tapped +");
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.text('Voeg toe aan de lijst'));
      debugPrint("[WaarnemingFlowTest]: Added animal to list");
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text('Volgende'), findsOneWidget);
      await tester.tap(find.text('Volgende'));
      debugPrint("[WaarnemingFlowTest]: Pressed Next");
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Volgende'), findsOneWidget);
      await tester.tap(find.text('Volgende'));
      debugPrint("[WaarnemingFlowTest]: Pressed Next");
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Step 12: Verify Huidige locatie is displayed and tap on it
      expect(find.text('Huidige locatie'), findsOneWidget);
      await tester.tap(find.text('Huidige locatie'));
      debugPrint("[WaarnemingFlowTest]: Tapped Huidige locatie");
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Step 13: Verify Zuid-Kennemerland is displayed and tap on it
      expect(find.text('Zuid-Kennemerland'), findsOneWidget);
      await tester.tap(find.text('Zuid-Kennemerland'));
      debugPrint("[WaarnemingFlowTest]: Tapped Zuid-Kennemerland");
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Step 14: tap on center of the screen to select location
      final screenSize = tester.view.physicalSize / tester.view.devicePixelRatio;
      final center = Offset(screenSize.width / 2, screenSize.height / 2);
      await tester.tapAt(center);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Step 15: Verify Bevestig is displayed and tap on it
      expect(find.text('Bevestig'), findsOneWidget);
      await tester.tap(find.text('Bevestig'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      
      // Step 16: Verify Volgende is displayed and tap on it
      expect(find.text('Volgende'), findsOneWidget);
      await tester.tap(find.text('Volgende'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Step 17: Test questionnaire flow
      await questionnaire_flow.runQuestionnaireSteps(tester);
      
      // Step 18: Test completed
      expect(true, isTrue, reason: 'Test completed successfully despite overflow');
    });
  });
}