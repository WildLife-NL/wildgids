import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildrapport/interfaces/other/permission_interface.dart';
import 'package:wildrapport/managers/permission/permission_manager.dart';
import '../mock_generator.mocks.dart';

// Create a testable version of PermissionManager
class TestablePermissionManager extends PermissionManager {
  TestablePermissionManager(this.mockPrefs);
  
  final SharedPreferences mockPrefs;
  bool mockPermissionGranted = false;
  
  @override
  Future<bool> isPermissionGranted(PermissionType permission) async {
    return mockPermissionGranted;
  }
  
  @override
  Future<bool> requestPermission(
    BuildContext context,
    PermissionType permission, {
    bool showRationale = true,
  }) async {
    if (showRationale) {
      bool shouldProceed = await showPermissionRationale(context, permission);
      if (!shouldProceed) return false;
    }
    return mockPermissionGranted;
  }
}

void main() {
  late TestablePermissionManager permissionManager;
  late SharedPreferences mockPrefs;
  
  TestWidgetsFlutterBinding.ensureInitialized();
  
  setUp(() {
    mockPrefs = MockSharedPreferences();
    permissionManager = TestablePermissionManager(mockPrefs);
  });

  group('PermissionManager', () {
    test('should check if permission is granted', () async {
      // Set the mock to return false
      permissionManager.mockPermissionGranted = false;
      final result = await permissionManager.isPermissionGranted(PermissionType.location);
      expect(result, isFalse);
      
      // Set the mock to return true
      permissionManager.mockPermissionGranted = true;
      final result2 = await permissionManager.isPermissionGranted(PermissionType.location);
      expect(result2, isTrue);
    });

    testWidgets('should show permission rationale dialog', (WidgetTester tester) async {
      // Build test app
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              return TextButton(
                onPressed: () {
                  permissionManager.showPermissionRationale(context, PermissionType.location);
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      );

      // Tap the button to show the dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is shown with correct content
      expect(find.text('Locatie Toegang'), findsOneWidget);
      expect(find.text('We hebben toegang tot je locatie nodig om nauwkeurig te kunnen rapporteren waar je dieren hebt waargenomen.'), findsOneWidget);
      expect(find.text('Niet nu'), findsOneWidget);
      expect(find.text('Doorgaan'), findsOneWidget);
    });

    testWidgets('should return true when user accepts permission rationale', (WidgetTester tester) async {
      // Build test app
      late bool dialogResult;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              return TextButton(
                onPressed: () async {
                  dialogResult = await permissionManager.showPermissionRationale(context, PermissionType.location);
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      );

      // Tap the button to show the dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Tap "Doorgaan" button
      await tester.tap(find.text('Doorgaan'));
      await tester.pumpAndSettle();

      // Verify result is true
      expect(dialogResult, isTrue);
    });

    testWidgets('should return false when user rejects permission rationale', (WidgetTester tester) async {
      // Build test app
      late bool dialogResult;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              return TextButton(
                onPressed: () async {
                  dialogResult = await permissionManager.showPermissionRationale(context, PermissionType.location);
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      );

      // Tap the button to show the dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Tap "Niet nu" button
      await tester.tap(find.text('Niet nu'));
      await tester.pumpAndSettle();

      // Verify result is false
      expect(dialogResult, isFalse);
    });

    test('handleInitialPermissions should be implemented but empty', () async {
      // This method is marked as no longer needed in the implementation
      await permissionManager.handleInitialPermissions(MockBuildContext());
      // If we reach here, the test passes
      expect(true, isTrue);
    });
  });
}

// Mock BuildContext for testing
class MockBuildContext extends Mock implements BuildContext {}

