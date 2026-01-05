import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildrapport/interfaces/data_apis/interaction_api_interface.dart';
import 'package:wildrapport/interfaces/reporting/interaction_interface.dart';
import 'package:wildrapport/managers/api_managers/interaction_manager.dart';
import 'package:wildrapport/models/api_models/experiment.dart';
import 'package:wildrapport/models/api_models/interaction_type.dart';
import 'package:wildrapport/models/api_models/questionaire.dart';
import 'package:wildrapport/models/api_models/user.dart';
import 'package:wildrapport/models/beta_models/interaction_response_model.dart';
import '../mock_generator.mocks.dart';

class InteractionHelpers {
  static Future<void> setupEnvironment() async {
    // Setup mock SharedPreferences with default values
    SharedPreferences.setMockInitialValues({"userID": "test-user-123"});
  }

  static MockInteractionApiInterface getMockInteractionApi() {
    final mock = MockInteractionApiInterface();
    return mock;
  }

  static MockReportable getMockReportable() {
    final mock = MockReportable();
    when(mock.toJson()).thenReturn({"test": "data"});
    return mock;
  }

  static InteractionInterface getInteractionManager({
    required InteractionApiInterface interactionApi,
    Connectivity? connectivity,
  }) {
    return InteractionManager(
      interactionAPI: interactionApi,
      connectivity: connectivity ?? MockConnectivity(),
    );
  }

  static void setupSuccessfulInteractionResponse(
    MockInteractionApiInterface mockApi,
  ) {
    final response = InteractionResponse(
      questionnaire: Questionnaire(
        id: 'q-123',
        name: 'Test Questionnaire',
        experiment: Experiment(
          id: 'exp-123',
          description: 'Test Experiment',
          name: 'Test Experiment',
          start: DateTime.now(),
          user: User(
            id: 'user-123',
            email: 'test@example.com',
            name: 'Test User',
          ),
        ),
        interactionType: InteractionType(
          id: 1,
          name: 'Test Interaction',
          description: 'Test Interaction Description',
        ),
        questions: [],
      ),
      interactionID: 'int-123',
    );

    when(mockApi.sendInteraction(any)).thenAnswer((_) async => response);
  }

  static void setupFailedInteractionResponse(
    MockInteractionApiInterface mockApi,
  ) {
    when(mockApi.sendInteraction(any)).thenThrow(Exception('API Error'));
  }

  static void setupOfflineConnectivity(MockConnectivity mockConnectivity) {
    when(
      mockConnectivity.checkConnectivity(),
    ).thenAnswer((_) async => [ConnectivityResult.none]);
  }

  static void setupOnlineConnectivity(MockConnectivity mockConnectivity) {
    when(
      mockConnectivity.checkConnectivity(),
    ).thenAnswer((_) async => [ConnectivityResult.wifi]);
  }

  static InteractionResponse createMockInteractionResponse() {
    return InteractionResponse(
      questionnaire: Questionnaire(
        id: 'q-123',
        name: 'Test Questionnaire',
        experiment: Experiment(
          id: 'exp-123',
          description: 'Test Experiment',
          name: 'Test Experiment',
          start: DateTime.now(),
          user: User(
            id: 'user-123',
            email: 'test@example.com',
            name: 'Test User',
          ),
        ),
        interactionType: InteractionType(
          id: 1,
          name: 'Test Interaction',
          description: 'Test Interaction Description',
        ),
        questions: [],
      ),
      interactionID: 'int-123',
    );
  }
}
