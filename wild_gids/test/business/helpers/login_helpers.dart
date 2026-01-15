import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mockito/mockito.dart';
import 'package:wildgids/interfaces/other/login_interface.dart';
import 'package:wildgids/managers/other/login_manager.dart';
import 'package:wildgids/models/api_models/user.dart';
import '../mock_generator.mocks.dart';

class TestHelpers {
  // Initialize environment variables for tests
  static Future<void> setupEnvironment() async {
    await dotenv.load(fileName: ".env");
  }

  // Create mocked instances
  static MockAuthApiInterface getMockAuthApi() {
    final mockAuthApi = MockAuthApiInterface();
    return mockAuthApi;
  }

  static MockProfileApiInterface getMockProfileApi() {
    final mockProfileApi = MockProfileApiInterface();
    return mockProfileApi;
  }

  // Create a login manager with mocked dependencies
  static LoginInterface getLoginManager({
    MockAuthApiInterface? authApi,
    MockProfileApiInterface? profileApi,
  }) {
    return LoginManager(
      authApi ?? getMockAuthApi(),
      profileApi ?? getMockProfileApi(),
    );
  }

  // Setup successful authentication
  static void setupSuccessfulAuthentication(MockAuthApiInterface mockAuthApi) {
    when(
      mockAuthApi.authenticate(any, any),
    ).thenAnswer((_) => Future.value(<String, dynamic>{}));
  }

  // Setup failed authentication
  static void setupFailedAuthentication(MockAuthApiInterface mockAuthApi) {
    when(
      mockAuthApi.authenticate(any, any),
    ).thenThrow(Exception('Failed to login'));
  }

  // Setup successful authorization
  static void setupSuccessfulAuthorization(
    MockAuthApiInterface mockAuthApi,
    MockProfileApiInterface mockProfileApi, {
    User? user,
  }) {
    final mockUser =
        user ?? User(id: '123', email: 'test@example.com', name: 'Test User');
    when(
      mockAuthApi.authorize(any, any),
    ).thenAnswer((_) => Future.value(mockUser));
    when(
      mockProfileApi.setProfileDataInDeviceStorage(),
    ).thenAnswer((_) => Future.value());
  }

  // Setup failed authorization
  static void setupFailedAuthorization(MockAuthApiInterface mockAuthApi) {
    when(mockAuthApi.authorize(any, any)).thenThrow(Exception('Unauthorized'));
  }
}

