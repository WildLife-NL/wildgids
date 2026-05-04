import 'package:flutter/material.dart';
import 'package:wildgids/models/api_models/questionaire.dart';

abstract class QuestionnaireInterface {
  Future<Questionnaire> getQuestionnaire();
  Future<List<dynamic>> buildQuestionnaireLayout(
    Questionnaire questionnaire,
    String interactionID,
    VoidCallback nextScreen,
    VoidCallback lastNextScreen,
    VoidCallback previousScreen,
  );
}

