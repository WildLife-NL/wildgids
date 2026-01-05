abstract class ResponseApiInterface {
  Future<bool> addReponse(
    String interactionID,
    String questionID,
    String? answerID,
    String? text,
  );

  /// Fetch responses for the current authenticated user (raw JSON list)
  Future<List<dynamic>> getMyResponsesRaw();
}
