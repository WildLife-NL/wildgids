import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildrapport/interfaces/state/navigation_state_interface.dart';
import 'package:wildrapport/interfaces/reporting/questionnaire_interface.dart';
import 'package:wildrapport/interfaces/reporting/response_interface.dart';
import 'package:wildrapport/models/api_models/questionaire.dart';
import 'package:wildrapport/providers/response_provider.dart';
import 'package:wildrapport/screens/questionnaire/questionnaire_completion_screen.dart';
import 'package:wildrapport/utils/toast_notification_handler.dart';
import 'package:wildrapport/widgets/shared_ui_widgets/app_bar.dart';

class QuestionnaireScreen extends StatefulWidget {
  final Questionnaire questionnaire;
  final String interactionID;
  const QuestionnaireScreen({
    super.key,
    required this.questionnaire,
    required this.interactionID,
  });

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  late final QuestionnaireInterface _questionnaireManager;
  final ResponseProvider responseProvider = ResponseProvider();
  late final ResponseInterface _responseManager;
  late List<dynamic> questionnaireScreensList = [];
  int currentQuestionnaireIndex = 0;
  bool _shouldNavigate = false;

  @override
  void initState() {
    super.initState();
    _questionnaireManager = context.read<QuestionnaireInterface>();
    _responseManager = context.read<ResponseInterface>();
    _loadQuestionnaire();
  }

  void nextScreen() {
    debugPrint("${responseProvider.answerID}");
    debugPrint("[QuestionnaireScreen] Total responses in provider: ${responseProvider.responses.length}");
    
    if (responseProvider.interactionID != null &&
        responseProvider.questionID != null) {
      // Find the response for the current question instead of using .last
      final currentResponse = responseProvider.responses.firstWhere(
        (r) => r.questionID == responseProvider.questionID,
        orElse: () => responseProvider.responses.last,
      );
      
      debugPrint("[QuestionnaireScreen] Storing response for question: ${responseProvider.questionID}");
      debugPrint("[QuestionnaireScreen] Answer: ${currentResponse.answerID}, Text: ${currentResponse.text}");
      
      _responseManager.storeResponse(
        currentResponse,
        widget.questionnaire.id,
        responseProvider.questionID!,
      );
    }
    debugPrint("Next Screen");
    debugPrint("Current Index: $currentQuestionnaireIndex");
    if (currentQuestionnaireIndex < questionnaireScreensList.length - 1) {
      setState(() {
        currentQuestionnaireIndex++;
      });
    }
  }

  void lastNextScreen() async {
    debugPrint("[QuestionnaireScreen] Final submit - Total responses: ${responseProvider.responses.length}");
    
    if (responseProvider.interactionID != null &&
        responseProvider.questionID != null) {
      // Find the response for the last question
      final lastResponse = responseProvider.responses.firstWhere(
        (r) => r.questionID == responseProvider.questionID,
        orElse: () => responseProvider.responses.last,
      );
      
      debugPrint("[QuestionnaireScreen] Storing last response for question: ${responseProvider.questionID}");
      
      await _responseManager.storeResponse(
        lastResponse,
        widget.questionnaire.id,
        responseProvider.questionID!,
      );
    }
    
    debugPrint("[QuestionnaireScreen] Submitting all responses to backend...");
    await _responseManager.submitResponses();
    _sendToastNotification("Uw antwoorden zijn verstuurd");

    setState(() {
      _shouldNavigate = true;
    });
  }

  void _sendToastNotification(String toastMessage) {
    ToastNotificationHandler.sendToastNotification(context, toastMessage, 2);
  }

  void previousScreen() {
    debugPrint("Previous Screen");
    debugPrint("Current Index: $currentQuestionnaireIndex");
    if (currentQuestionnaireIndex > 0) {
      setState(() {
        currentQuestionnaireIndex--;
      });
    }
  }

  Future<void> _loadQuestionnaire() async {
    final questionnaireScreens = await _questionnaireManager.buildQuestionnaireLayout(
      widget.questionnaire,
      widget.interactionID,
      nextScreen,
      lastNextScreen,
      previousScreen,
    );

    if (mounted) {
      setState(() {
        questionnaireScreensList = questionnaireScreens;
      });
      debugPrint(
        'Loaded questionnaireScreensList: ${questionnaireScreensList.length}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Handle navigation in build when _shouldNavigate is true
    if (_shouldNavigate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<NavigationStateInterface>().pushAndRemoveUntil(
            context,
            const QuestionnaireCompletionScreen(),
          );
        }
      });
      // Reset _shouldNavigate to prevent repeated navigation
      _shouldNavigate = false;
    }

    if (questionnaireScreensList.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return ChangeNotifierProvider<ResponseProvider>.value(
      value: responseProvider,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              CustomAppBar(
                leftIcon: null,
                centerText: "Vragenlijst",
                rightIcon: null,
                showUserIcon: true,
                useFixedText: true,
                iconColor: Colors.black,
                textColor: Colors.black,
                fontScale: 1.15,
                iconScale: 1.15,
                userIconScale: 1.15,
              ),
              Expanded(
                child: questionnaireScreensList[currentQuestionnaireIndex],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
