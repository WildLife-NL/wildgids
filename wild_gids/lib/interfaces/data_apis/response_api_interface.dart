import 'package:wildrapport/models/api_models/my_response.dart';

class ResponseSubmissionResult {
  final bool success;
  final Conveyance? conveyance;

  ResponseSubmissionResult({required this.success, this.conveyance});
}

abstract class ResponseApiInterface {
  Future<ResponseSubmissionResult> addReponse(
    String interactionID,
    String questionID,
    String? answerID,
    String? text,
  );

  /// Fetch responses for the current authenticated user
  Future<List<dynamic>> getMyResponsesRaw();
}
