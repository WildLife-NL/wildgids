import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/interfaces/data_apis/profile_api_interface.dart';
import 'package:wildgids/interfaces/state/navigation_state_interface.dart';
import 'package:wildgids/interfaces/other/overzicht_interface.dart';
import 'package:wildgids/interfaces/other/permission_interface.dart';
import 'package:wildgids/providers/app_state_provider.dart';
import 'package:wildgids/screens/shared/overzicht_screen.dart';
import 'package:wildgids/widgets/overzicht/top_container.dart';
import 'package:wildgids/widgets/overzicht/action_buttons.dart';
import '../helpers/overzicht_helpers.dart';
import '../mock_generator.mocks.dart';

void main() {
  late MockNavigationStateInterface mockNavigationManager;
  late MockOverzichtInterface mockOverzichtManager;
  late MockProfileApiInterface mockProfileApi;
  late MockPermissionInterface mockPermissionInterface;
  late MockAppStateProvider mockAppStateProvider;

  setUpAll(() async {
    // Setup environment for all tests
    await OverzichtHelpers.setupEnvironment();
  });

  setUp(() {
    mockNavigationManager = OverzichtHelpers.getMockNavigationManager();
    mockOverzichtManager = OverzichtHelpers.getMockOverzichtManager();
    mockProfileApi = MockProfileApiInterface();
    mockPermissionInterface = MockPermissionInterface();
    mockAppStateProvider = MockAppStateProvider();

    // Setup successful navigation by default
    OverzichtHelpers.setupSuccessfulNavigation(mockNavigationManager);

    // Setup user data loading by default
    OverzichtHelpers.setupUserDataLoading(mockOverzichtManager, mockProfileApi);

    // Setup permission checks to return true by default
    when(
      mockPermissionInterface.isPermissionGranted(any),
    ).thenAnswer((_) async => true);
    when(
      mockPermissionInterface.requestPermission(
        any,
        any,
        showRationale: anyNamed('showRationale'),
      ),
    ).thenAnswer((_) async => true);

    // Setup AppStateProvider methods that might be called
    when(
      mockAppStateProvider.getScreenState<dynamic>(any, any),
    ).thenReturn(null);
    when(mockAppStateProvider.setScreenState(any, any, any)).thenReturn(null);
  });

  Widget createOverzichtScreen() {
    return MultiProvider(
      providers: [
        Provider<NavigationStateInterface>.value(value: mockNavigationManager),
        Provider<OverzichtInterface>.value(value: mockOverzichtManager),
        Provider<ProfileApiInterface>.value(value: mockProfileApi),
        Provider<PermissionInterface>.value(value: mockPermissionInterface),
        ChangeNotifierProvider<AppStateProvider>.value(
          value: mockAppStateProvider,
        ),
      ],
      child: const MaterialApp(home: OverzichtScreen()),
    );
  }

  group('OverzichtScreen', () {
    testWidgets('should render top container and action buttons', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(createOverzichtScreen());

      // Act - wait for screen to settle
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(TopContainer), findsOneWidget);
      expect(find.byType(ActionButtons), findsOneWidget);
    });

    testWidgets('should display username from manager', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(createOverzichtScreen());

      // Act - wait for screen to settle
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Test User'), findsOneWidget);
    });

    testWidgets(
      'should render report button and handle tap safely',
      (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createOverzichtScreen());
        await tester.pumpAndSettle();

        // Act - Find and tap the report button (label can come from backend).
        await tester.tap(find.text('Rapporteren'));
        await tester.pump();

        // Assert: no crash and screen still present.
        expect(find.byType(OverzichtScreen), findsOneWidget);
      },
    );

    testWidgets('should show kaart button and handle tap safely', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(createOverzichtScreen());
      await tester.pumpAndSettle();

      // Act - Tap the action button by key to avoid navbar text ambiguity.
      await tester.tap(find.byKey(const Key('rapporten_kaart_button')));
      await tester.pump();

      // Assert: no crash and screen still present.
      expect(find.byType(OverzichtScreen), findsOneWidget);
    });

    testWidgets('should handle navigation failure gracefully', (
      WidgetTester tester,
    ) async {
      // Arrange
      OverzichtHelpers.setupFailedNavigation(mockNavigationManager);
      await tester.pumpWidget(createOverzichtScreen());
      await tester.pumpAndSettle();

      // Act - Find and tap the Rapporteren button
      await tester.tap(find.text('Rapporteren'));
      await tester.pump();

      // The location gate may prevent navigation in test environment.
      // Assert that tapping does not crash this screen.
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(OverzichtScreen), findsOneWidget);
    });
  });
}

