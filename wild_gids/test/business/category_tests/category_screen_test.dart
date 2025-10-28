import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:wildrapport/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:wildrapport/interfaces/state/navigation_state_interface.dart';
import 'package:wildrapport/models/animal_waarneming_models/animal_sighting_model.dart';
import 'package:wildrapport/models/enums/animal_category.dart';
import 'package:wildrapport/models/enums/report_type.dart';
import 'package:wildrapport/providers/app_state_provider.dart';
import 'package:wildrapport/screens/shared/category_screen.dart';
import 'package:wildrapport/widgets/shared_ui_widgets/app_bar.dart';

import '../mock_generator.mocks.dart';

@GenerateMocks([
  AnimalSightingReportingInterface,
  NavigationStateInterface,
  AppStateProvider,
])
void main() {
  late MockAnimalSightingReportingInterface mockSightingInterface;
  late MockNavigationStateInterface mockNavigationInterface;
  late MockAppStateProvider mockAppStateProvider;

  setUp(() {
    mockSightingInterface = MockAnimalSightingReportingInterface();
    mockNavigationInterface = MockNavigationStateInterface();
    mockAppStateProvider = MockAppStateProvider();

    // Stub required getters and methods
    when(mockAppStateProvider.currentReportType)
        .thenReturn(ReportType.waarneming);
    when(mockSightingInterface.getCurrentanimalSighting()).thenReturn(null);

    // Stub the methods used in the widget logic
    when(mockSightingInterface.convertStringToCategory(any))
        .thenReturn(AnimalCategory.evenhoevigen);
    when(mockSightingInterface.updateCategory(any))
        .thenReturn(AnimalSightingModel());

    when(mockSightingInterface.clearCurrentanimalSighting())
        .thenReturn(null);
    when(mockAppStateProvider.resetApplicationState(any)).thenReturn(null);
    when(mockNavigationInterface.clearApplicationState(any)).thenReturn(null);
    when(mockNavigationInterface.pushAndRemoveUntil(any, any))
        .thenReturn(null);
    when(mockNavigationInterface.pushReplacementForward(any, any))
        .thenReturn(null);
  });

  Widget createTestWidget() {
    return MultiProvider(
      providers: [
        Provider<AnimalSightingReportingInterface>.value(
          value: mockSightingInterface,
        ),
        Provider<NavigationStateInterface>.value(
          value: mockNavigationInterface,
        ),
        ChangeNotifierProvider<AppStateProvider>.value(
          value: mockAppStateProvider,
        ),
      ],
      child: const MaterialApp(
        home: CategoryScreen(),
      ),
    );
  }

  testWidgets('CategoryScreen renders and category buttons are clickable',
      (WidgetTester tester) async {
    // Fix layout overflow by increasing test screen size
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Selecteer Categorie'), findsOneWidget);

    final evenhoevigen = find.text('Evenhoevigen');
    expect(evenhoevigen, findsOneWidget);

    await tester.tap(evenhoevigen);
    await tester.pumpAndSettle();

    verify(mockSightingInterface.convertStringToCategory('Evenhoevigen'))
        .called(1);
    verify(mockSightingInterface.updateCategory(AnimalCategory.evenhoevigen))
        .called(1);
    verify(mockNavigationInterface.pushReplacementForward(any, any)).called(1);
  });

  testWidgets('Back button clears state and navigates to Rapporteren',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Find the back button in the CustomAppBar
    // Use a more specific finder to get the correct back button
    final backButton = find.byType(CustomAppBar).evaluate().first;
    final customAppBar = backButton.widget as CustomAppBar;
    
    // Call the onLeftIconPressed callback directly
    customAppBar.onLeftIconPressed?.call();
    await tester.pumpAndSettle();

    // Verify the expected method calls
    verify(mockSightingInterface.clearCurrentanimalSighting()).called(1);
    verify(mockAppStateProvider.resetApplicationState(any)).called(1);
    verify(mockNavigationInterface.clearApplicationState(any)).called(1);
    
    // Verify navigation to Rapporteren screen
    verify(mockNavigationInterface.pushAndRemoveUntil(any, any)).called(1);
  });
}








