import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:wildrapport/interfaces/other/overzicht_interface.dart';
import 'package:wildrapport/widgets/overzicht/top_container.dart';

//This approach:
//Finds the TopContainer widget
//Looks for Container widgets that are descendants of TopContainer
//Gets the first Container and checks its constraints

// Generate mock class
import '../mock_generator.mocks.dart';
@GenerateMocks([OverzichtInterface])
void main() {
  late MockOverzichtInterface mockOverzichtManager;

  setUp(() {
    mockOverzichtManager = MockOverzichtInterface();
    
    // Setup default behavior
    when(mockOverzichtManager.userName).thenReturn('Test User');
    when(mockOverzichtManager.topContainerHeight).thenReturn(285.0);
    when(mockOverzichtManager.welcomeFontSize).thenReturn(20.0);
    when(mockOverzichtManager.usernameFontSize).thenReturn(24.0);
    when(mockOverzichtManager.logoWidth).thenReturn(180.0);
    when(mockOverzichtManager.logoHeight).thenReturn(180.0);
  });

  Widget createTopContainer() {
    return MultiProvider(
      providers: [
        Provider<OverzichtInterface>.value(value: mockOverzichtManager),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: TopContainer(
            userName: mockOverzichtManager.userName,
            height: mockOverzichtManager.topContainerHeight,
            welcomeFontSize: mockOverzichtManager.welcomeFontSize,
            usernameFontSize: mockOverzichtManager.usernameFontSize,
          ),
        ),
      ),
    );
  }

  group('TopContainer', () {
    testWidgets('should display welcome message and username', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTopContainer());
      
      // Assert
      expect(find.textContaining('Welkom'), findsOneWidget);
      expect(find.text('Test User'), findsOneWidget);
    });

    testWidgets('should display logo with correct dimensions', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTopContainer());
      
      // Assert - This will depend on how your logo is implemented
      // If it's an Image widget:
      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
      
      // Check container height
      final topContainer = find.byType(TopContainer);
      expect(topContainer, findsOneWidget);
      
      // Find the Container within TopContainer that has the height set
      final containerFinder = find.descendant(
        of: topContainer,
        matching: find.byType(Container),
      ).first;
      
      final containerWidget = tester.widget<Container>(containerFinder);
      
      // Check if height is set directly in the container
      expect(containerWidget.constraints?.maxHeight ?? containerWidget.constraints?.minHeight, 285.0);
    });
  });
}



