import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildrapport/interfaces/data_apis/response_api_interface.dart';
import 'package:wildrapport/managers/api_managers/response_manager.dart';
import 'package:wildrapport/models/beta_models/response_model.dart';
import 'package:wildrapport/providers/response_provider.dart';
import '../mock_generator.mocks.dart';

class ResponseHelpers {
  static Future<void> setupEnvironment() async {
    // Setup mock SharedPreferences with default values
    SharedPreferences.setMockInitialValues({});
  }

  static MockResponseApiInterface getMockResponseApi() {
    final mock = MockResponseApiInterface();
    return mock;
  }

  static MockConnectivity getMockConnectivity() {
    final mock = MockConnectivity();

    // Setup default behavior
    when(
      mock.checkConnectivity(),
    ).thenAnswer((_) async => [ConnectivityResult.wifi]);
    when(
      mock.onConnectivityChanged,
    ).thenAnswer((_) => Stream.value([ConnectivityResult.wifi]));

    return mock;
  }

  static ResponseProvider getResponseProvider() {
    return ResponseProvider();
  }

  static ResponseManager getResponseManager({
    required ResponseApiInterface responseApi,
    required ResponseProvider responseProvider,
    required Connectivity connectivity,
  }) {
    return ResponseManager(
      responseAPI: responseApi,
      responseProvider: responseProvider,
      connectivity: connectivity,
    );
  }

  static Response createMockResponse({
    String interactionID = 'interaction123',
    String questionID = 'question123',
    String answerID = 'answer123',
    String text = 'Test response',
  }) {
    return Response(
      interactionID: interactionID,
      questionID: questionID,
      answerID: answerID,
      text: text,
    );
  }

  static void setupSuccessfulResponseSubmission(
    MockResponseApiInterface mockApi,
  ) {
    when(mockApi.addReponse(any, any, any, any)).thenAnswer(
      (_) async => ResponseSubmissionResult(success: true),
    );
  }

  static void setupFailedResponseSubmission(MockResponseApiInterface mockApi) {
    when(mockApi.addReponse(any, any, any, any)).thenAnswer(
      (_) async => ResponseSubmissionResult(success: false),
    );
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
}
