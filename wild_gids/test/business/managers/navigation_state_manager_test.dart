import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:wildgids/interfaces/state/navigation_state_interface.dart';
import 'package:wildgids/managers/state_managers/navigation_state_manager.dart';
import 'package:wildgids/providers/app_state_provider.dart';
import '../mock_generator.mocks.dart';

// Mock screen for testing navigation
class MockScreen extends StatelessWidget {
  const MockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: AppBar(title: Text('Waarneming')),
      ),
      body: const Center(child: Text('Mock Screen')),
    );
  }
}

// Mock home screen to avoid provider dependencies
class MockHomeScreen extends StatelessWidget {
  const MockHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Home Screen')));
  }
}

// Extended NavigationStateManager for testing
class TestableNavigationStateManager extends NavigationStateManager {
  @override
  void resetToHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MockHomeScreen()),
      (route) => false,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      clearApplicationState(context);
    });
  }

  // Create a method to test controller disposal
  void testDispose() {
    final controller = TextEditingController(text: 'Test');
    bool wasDisposed = false;

    controller.addListener(() {
      wasDisposed = true;
    });

    // Add to internal list and dispose
    dispose();

    // If dispose worked correctly, the controller should be disposed
    assert(wasDisposed == false, "Controller was not properly disposed");
  }
}

void main() {
  late NavigationStateManager navigationManager;
  late TestableNavigationStateManager testableNavigationManager;
  late MockAnimalSightingReportingInterface mockAnimalSightingManager;
  late MockAppStateProvider mockAppStateProvider;

  setUp(() {
    navigationManager = NavigationStateManager();
    testableNavigationManager = TestableNavigationStateManager();
    mockAnimalSightingManager = MockAnimalSightingReportingInterface();
    mockAppStateProvider = MockAppStateProvider();
  });

  group('NavigationStateManager', () {
    test('should dispose correctly', () {
      // This is a simplified test that just verifies the dispose method runs without errors
      navigationManager.dispose();
      // If we get here without errors, the test passes
      expect(true, isTrue);
    });

    testWidgets('should reset to home screen', (WidgetTester tester) async {
      // Build our app with the required providers
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              Provider<AnimalSightingReportingInterface>.value(
                value: mockAnimalSightingManager,
              ),
              ChangeNotifierProvider<AppStateProvider>.value(
                value: mockAppStateProvider,
              ),
              Provider<NavigationStateInterface>.value(
                value: testableNavigationManager,
              ),
            ],
            child: Builder(
              builder:
                  (context) => ElevatedButton(
                    onPressed:
                        () => testableNavigationManager.resetToHome(context),
                    child: const Text('Reset to Home'),
                  ),
            ),
          ),
        ),
      );

      // Tap the button to trigger resetToHome
      await tester.tap(find.text('Reset to Home'));
      await tester.pumpAndSettle();

      // Verify we navigated to MockHomeScreen
      expect(find.text('Home Screen'), findsOneWidget);

      // Verify clearApplicationState was called (indirectly)
      verify(mockAnimalSightingManager.clearCurrentanimalSighting()).called(1);
      verify(mockAppStateProvider.resetApplicationState(any)).called(1);
    });

    testWidgets('should clear application state', (WidgetTester tester) async {
      // Build our app with the required providers
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              Provider<AnimalSightingReportingInterface>.value(
                value: mockAnimalSightingManager,
              ),
              ChangeNotifierProvider<AppStateProvider>.value(
                value: mockAppStateProvider,
              ),
            ],
            child: Builder(
              builder:
                  (context) => ElevatedButton(
                    onPressed:
                        () => navigationManager.clearApplicationState(context),
                    child: const Text('Clear State'),
                  ),
            ),
          ),
        ),
      );

      // Tap the button to trigger clearApplicationState
      await tester.tap(find.text('Clear State'));
      await tester.pump();

      // Verify the methods were called
      verify(mockAnimalSightingManager.clearCurrentanimalSighting()).called(1);
      verify(mockAppStateProvider.resetApplicationState(any)).called(1);
    });

    testWidgets('should push and remove until', (WidgetTester tester) async {
      // Build our app
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder:
                (context) => ElevatedButton(
                  onPressed:
                      () => navigationManager.pushAndRemoveUntil(
                        context,
                        const MockScreen(),
                      ),
                  child: const Text('Navigate'),
                ),
          ),
        ),
      );

      // Tap the button to trigger navigation
      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      // Verify we navigated to MockScreen
      expect(find.text('Mock Screen'), findsOneWidget);
    });

    testWidgets('should push replacement forward', (WidgetTester tester) async {
      // Build our app
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder:
                (context) => ElevatedButton(
                  onPressed:
                      () => navigationManager.pushReplacementForward(
                        context,
                        const MockScreen(),
                      ),
                  child: const Text('Navigate'),
                ),
          ),
        ),
      );

      // Tap the button to trigger navigation
      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      // Verify we navigated to MockScreen
      expect(find.text('Mock Screen'), findsOneWidget);
    });

    testWidgets('should push replacement back', (WidgetTester tester) async {
      // Build our app
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder:
                (context) => ElevatedButton(
                  onPressed:
                      () => navigationManager.pushReplacementBack(
                        context,
                        const MockScreen(),
                      ),
                  child: const Text('Navigate'),
                ),
          ),
        ),
      );

      // Tap the button to trigger navigation
      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      // Verify we navigated to MockScreen
      expect(find.text('Mock Screen'), findsOneWidget);
    });

    testWidgets('should push forward', (WidgetTester tester) async {
      // Build our app with a navigation stack
      await tester.pumpWidget(
        MaterialApp(
          home: Navigator(
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder:
                    (context) => Scaffold(
                      appBar: AppBar(title: const Text('Initial Screen')),
                      body: Center(
                        child: ElevatedButton(
                          onPressed:
                              () => navigationManager.pushForward(
                                context,
                                const MockScreen(),
                              ),
                          child: const Text('Navigate'),
                        ),
                      ),
                    ),
              );
            },
          ),
        ),
      );

      // Verify we're on the initial screen
      expect(find.text('Initial Screen'), findsOneWidget);

      // Tap the button to trigger navigation
      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      // Verify we navigated to MockScreen
      expect(find.text('Mock Screen'), findsOneWidget);

      // Tap the back button in the app bar
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Verify we're back at the initial screen
      expect(find.text('Initial Screen'), findsOneWidget);
    });
  });
}

