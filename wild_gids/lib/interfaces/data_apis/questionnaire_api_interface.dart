import 'package:wildrapport/models/api_models/questionaire.dart';

abstract class QuestionnaireApiInterface {
  Future<Questionnaire> getQuestionnaireByID(String id);
}
