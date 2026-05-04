import '../../models/beta_models/response_model.dart';

abstract class ResponseInterface {
  Future<void> storeResponse(
    Response response,
    String questionaireID,
    String questionID,
  );
  Future<void> submitResponses();
  Future<void> updateResponse(
    Response response,
    String questionaireID,
    String questionID,
  );
}
