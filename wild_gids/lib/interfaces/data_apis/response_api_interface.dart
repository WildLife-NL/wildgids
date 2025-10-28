abstract class ResponseApiInterface {
  Future<bool> addReponse(
    String interactionID,
    String questionID,
    String? answerID,
    String? text,
  );
}
