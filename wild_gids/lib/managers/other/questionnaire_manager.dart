import 'package:flutter/material.dart';
import 'package:wildrapport/interfaces/data_apis/questionnaire_api_interface.dart';
import 'package:wildrapport/interfaces/reporting/questionnaire_interface.dart';
import 'package:wildrapport/models/api_models/questionaire.dart';
import 'package:wildrapport/widgets/questionnaire/questionnaire_home.dart';
import 'package:wildrapport/widgets/questionnaire/questionnaire_multiple_choice.dart';
import 'package:wildrapport/widgets/questionnaire/questionnaire_open_response.dart';

class QuestionnaireManager implements QuestionnaireInterface {
  final QuestionnaireApiInterface questionnaireAPI;
  QuestionnaireManager(this.questionnaireAPI);

  @override
  Future<Questionnaire> getQuestionnaire() async {
    // Deprecated: questionnaires are provided by backend when creating an interaction.
    // This method should not be used without a backend-provided ID.
    throw StateError(
      'Questionnaires must be supplied by the backend interaction response. getQuestionnaire() is unsupported.',
    );
  }

  @override
  Future<List<dynamic>> buildQuestionnaireLayout(
    Questionnaire questionnaire,
    String interactionID,
    VoidCallback nextScreen,
    VoidCallback lastNextScreen,
    VoidCallback previousScreen,
  ) async {
    final List<Widget> questionnaireWidgets = [];
    questionnaireWidgets.add(
      QuestionnaireHome(
        nextScreen: nextScreen,
        amountOfQuestions: questionnaire.questions!.length,
        questionnaireName: questionnaire.name,
        questionnaireDescription: questionnaire.interactionType.description,
        interactionID: interactionID,
        questionnaire: questionnaire,
      ),
    );

    final int length = questionnaire.questions!.length;

    // Debug: Log the raw questionnaire data from backend
    debugPrint("════════════════════════════════════════════════════════════════");
    debugPrint("[QuestionnaireManager] 📋 QUESTIONNAIRE DETAILS FROM BACKEND");
    debugPrint("────────────────────────────────────────────────────────────────");
    debugPrint("Questionnaire ID: ${questionnaire.id}");
    debugPrint("Questionnaire Name: ${questionnaire.name}");
    debugPrint("Interaction Type: ${questionnaire.interactionType.name}");
    debugPrint("Total Questions: ${questionnaire.questions?.length ?? 0}");
    debugPrint("════════════════════════════════════════════════════════════════");

    if (questionnaire.questions != null) {
      for (final (index, question) in questionnaire.questions!.indexed) {
        debugPrint("═══════════════════════════════════════════════");
        debugPrint("Question ${index + 1}: ${question.text}");
        debugPrint("Question ID: ${question.id}");
        debugPrint("Description: ${question.description}");
        debugPrint("Allow Open Response: ${question.allowOpenResponse}");
        debugPrint(
          "Allow Multiple Response: ${question.allowMultipleResponse}",
        );
        debugPrint("Has Answers: ${question.answers?.isNotEmpty ?? false}");
        if (question.answers != null && question.answers!.isNotEmpty) {
          debugPrint("Answers count: ${question.answers!.length}");
          for (var ans in question.answers!) {
            debugPrint("  - Answer ID: ${ans.id}");
            debugPrint("    Answer Text: ${ans.text}");
          }
        } else {
          debugPrint("❌ Answers: NULL or EMPTY - Backend did not provide answer choices");
        }
        debugPrint("Open Response Format: '${question.openResponseFormat}'");
        debugPrint("index: $index");
        debugPrint("length: $length");

        if (index == length - 1) {
          nextScreen = lastNextScreen;
        }

        // Decision logic:
        // 1. If question has predefined answers → Multiple Choice (radio/checkbox)
        // 2. If allowOpenResponse is true → Open Response (text field or slider based on format)
        // 3. Otherwise → Multiple Choice

        final bool hasAnswers =
            question.answers != null && question.answers!.isNotEmpty;
        final bool needsOpenResponse =
            question.allowOpenResponse && !hasAnswers;

        debugPrint(
          "🔍 Decision: hasAnswers=$hasAnswers, needsOpenResponse=$needsOpenResponse",
        );

        // Warning: Question claims to allow multiple responses but has no answers
        if (question.allowMultipleResponse && !hasAnswers) {
          debugPrint(
            "⚠️  WARNING: allowMultipleResponse=true but no answers provided by backend. "
            "Question will render as open response instead.",
          );
        }

        if (needsOpenResponse) {
          debugPrint("✅ Using QuestionnaireOpenResponse widget");
          // Open response: could be text field or slider depending on openResponseFormat
          questionnaireWidgets.add(
            QuestionnaireOpenResponse(
              question: question,
              questionnaire: questionnaire,
              onNextPressed: nextScreen,
              onBackPressed: previousScreen,
              interactionID: interactionID,
              index: index,
            ),
          );
        } else {
          debugPrint("✅ Using QuestionnaireMultipleChoice widget");
          // Multiple choice: radio buttons or checkboxes
          questionnaireWidgets.add(
            QuestionnaireMultipleChoice(
              question: question,
              questionnaire: questionnaire,
              onNextPressed: nextScreen,
              onBackPressed: previousScreen,
              interactionID: interactionID,
              index: index,
            ),
          );
        }
        debugPrint("═══════════════════════════════════════════════");
      }
    }
    return questionnaireWidgets;
  }
}
