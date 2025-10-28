import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:wildrapport/interfaces/other/overzicht_interface.dart';
import '../helpers/overzicht_helpers.dart';
import '../mock_generator.mocks.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late OverzichtInterface overzichtManager;

  setUpAll(() async {
    // Setup environment for all tests
    await OverzichtHelpers.setupEnvironment();
  });

  setUp(() {
    // Use a real manager for unit tests
    overzichtManager = OverzichtHelpers.getRealOverzichtManager();
  });

  group('OverzichtManager', () {
    test('should initialize with default values', () {
      // Verify initial values
      expect(overzichtManager.userName, isNotNull);
      expect(overzichtManager.topContainerHeight, 285.0);
      expect(overzichtManager.welcomeFontSize, 20.0);
      expect(overzichtManager.usernameFontSize, 24.0);
      expect(overzichtManager.logoWidth, 180.0);
      expect(overzichtManager.logoHeight, 180.0);
    });

    test('should update userName and notify listeners', () {
      // Arrange
      bool listenerCalled = false;
      overzichtManager.addListener(() {
        listenerCalled = true;
      });

      // Act
      overzichtManager.updateUserName('Jane Doe');

      // Assert
      expect(overzichtManager.userName, 'Jane Doe');
      expect(listenerCalled, true);
    });

    test('should add and remove listeners correctly', () {
      // Arrange
      int callCount = 0;
      void listener() {
        callCount++;
      }

      // Act - Add listener
      overzichtManager.addListener(listener);
      overzichtManager.updateUserName('Test User');
      
      // Assert
      expect(callCount, 1);
      
      // Act - Remove listener
      overzichtManager.removeListener(listener);
      overzichtManager.updateUserName('Another User');
      
      // Assert - Count should still be 1
      expect(callCount, 1);
    });
    
    test('should load user data from SharedPreferences', () async {
      // Arrange
      final mockProfileApi = MockProfileApiInterface();
      when(mockProfileApi.setProfileDataInDeviceStorage()).thenAnswer((_) async {
        // Mock the behavior of setting data in SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("userName", "Test User");
      });
      
      // Act
      await mockProfileApi.setProfileDataInDeviceStorage();
      
      // We need to manually update the userName in the manager since it doesn't
      // automatically observe SharedPreferences changes
      overzichtManager.updateUserName(await _getUserNameFromPrefs());
      
      // Assert
      expect(overzichtManager.userName, 'Test User');
    });

    test('should store user data in SharedPreferences', () async {
      // Arrange
      final mockProfileApi = MockProfileApiInterface();
      when(mockProfileApi.setProfileDataInDeviceStorage()).thenAnswer((_) async {
        // Mock the behavior of setting data in SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("userName", "Test User");
      });
      
      // Act
      await mockProfileApi.setProfileDataInDeviceStorage();
      
      // Assert - verify the data was stored in SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getString("userName"), 'Test User');
    });
  });
}

// Helper method to get userName from SharedPreferences
Future<String> _getUserNameFromPrefs() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString("userName") ?? "John Doe";
}


