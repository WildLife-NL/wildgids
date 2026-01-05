import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildrapport/interfaces/other/overzicht_interface.dart';
import 'package:wildrapport/managers/other/overzicht_manager.dart';
import '../mock_generator.mocks.dart';

class OverzichtHelpers {
  // Initialize environment and shared preferences for tests
  static Future<void> setupEnvironment() async {
    // Setup mock SharedPreferences
    SharedPreferences.setMockInitialValues({
      'userName': 'Test User',
      'userId': '123',
      'userEmail': 'test@example.com',
    });
  }

  // Create mocked instances
  static MockNavigationStateInterface getMockNavigationManager() {
    final mockNavigationManager = MockNavigationStateInterface();
    return mockNavigationManager;
  }

  static MockOverzichtInterface getMockOverzichtManager() {
    final mockOverzichtManager = MockOverzichtInterface();

    // Setup default behavior
    when(mockOverzichtManager.userName).thenReturn('Test User');
    when(mockOverzichtManager.topContainerHeight).thenReturn(285.0);
    when(mockOverzichtManager.welcomeFontSize).thenReturn(20.0);
    when(mockOverzichtManager.usernameFontSize).thenReturn(24.0);
    when(mockOverzichtManager.logoWidth).thenReturn(180.0);
    when(mockOverzichtManager.logoHeight).thenReturn(180.0);

    return mockOverzichtManager;
  }

  // Create a real overzicht manager for unit tests
  static OverzichtInterface getRealOverzichtManager() {
    return OverzichtManager();
  }

  // Setup successful navigation
  static void setupSuccessfulNavigation(
    MockNavigationStateInterface mockNavigationManager,
  ) {
    when(
      mockNavigationManager.pushReplacementForward(any, any),
    ).thenAnswer((_) => Future.value());
  }

  // Setup failed navigation
  static void setupFailedNavigation(
    MockNavigationStateInterface mockNavigationManager,
  ) {
    when(
      mockNavigationManager.pushReplacementForward(any, any),
    ).thenThrow(Exception('Navigation failed'));
  }

  // Setup user data loading
  static void setupUserDataLoading(
    MockOverzichtInterface mockOverzichtManager,
    MockProfileApiInterface mockProfileApi, {
    String userName = 'Test User',
    String userId = '123',
    String userEmail = 'test@example.com',
  }) {
    when(mockOverzichtManager.userName).thenReturn(userName);
    when(
      mockProfileApi.setProfileDataInDeviceStorage(),
    ).thenAnswer((_) => Future.value());
  }

  // Setup failed user data loading
  static void setupFailedUserDataLoading(
    MockProfileApiInterface mockProfileApi,
  ) {
    when(
      mockProfileApi.setProfileDataInDeviceStorage(),
    ).thenThrow(Exception("Failed to load user data"));
  }
}
