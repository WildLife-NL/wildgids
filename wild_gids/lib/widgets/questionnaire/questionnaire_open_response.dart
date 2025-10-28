import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildrapport/constants/app_colors.dart';
import 'package:wildrapport/models/api_models/questionaire.dart';
import 'package:wildrapport/models/beta_models/response_model.dart';
import 'package:wildrapport/providers/response_provider.dart';
import 'package:wildrapport/widgets/shared_ui_widgets/bottom_app_bar.dart';
import 'package:wildrapport/models/api_models/question.dart';
import 'package:wildrapport/widgets/questionnaire/shared_white_background.dart';

class QuestionnaireOpenResponse extends StatefulWidget {
  final Question question;
  final Questionnaire questionnaire;
  final String interactionID;
  final VoidCallback onNextPressed;
  final VoidCallback onBackPressed;
  final int index;

  final redLog = '\x1B[31m';

  const QuestionnaireOpenResponse({
    super.key,
    required this.question,
    required this.questionnaire,
    required this.interactionID,
    required this.onNextPressed,
    required this.onBackPressed,
    required this.index,
  });

  @override
  State<QuestionnaireOpenResponse> createState() =>
      _QuestionnaireOpenResponseState();
}

class _QuestionnaireOpenResponseState extends State<QuestionnaireOpenResponse> {
  Response? existingResponse;  
  TextEditingController _responseController = TextEditingController();
  late final ResponseProvider responseProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      responseProvider = context.read<ResponseProvider>();
      responseProvider.setInteractionID(widget.interactionID);
      responseProvider.setQuestionID(widget.question.id);
      existingResponse = responseProvider.responses.firstWhereOrNull(
      (response) => response.questionID == widget.question.id,
      );
      _responseController = TextEditingController(
        text: existingResponse?.text ?? '',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SharedWhiteBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16.0), // optional padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: Text(
                  'Vraag ${widget.index + 1} van ${widget.questionnaire.questions?.length}',
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brown,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16.0, left: 12.0),
                child: Text(
                  widget.question.text,
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brown,
                  ),
                ),
              ),
              const SizedBox(height: 1),
              if (widget.question.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    widget.question.description,
                    textAlign: TextAlign.left,
                    style: const TextStyle(fontSize: 18, color: AppColors.brown),
                  ),
                ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: TextField(
                  key: Key('questionnaire-description'),
                  controller: _responseController,
                  onChanged: (value) {
                    setState(() {
                      if (existingResponse != null) {
                        responseProvider.setUpdatingResponse(true);
                        responseProvider.updateResponse(
                          existingResponse?.copyWith(text: value),
                        );
                      } else {
                        responseProvider.addResponse(
                          Response(interactionID: widget.interactionID, questionID: widget.question.id, text: value),
                        );
                      }
                    });
                  },
                  maxLines: 10,
                  decoration: InputDecoration(
                    hintText: 'Schrijf hier uw antwoord...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  style: const TextStyle(fontSize: 18, color: AppColors.brown),
                ),
              ),
              // Remove Expanded(child: Container()) — no longer needed
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomAppBar(
        onNextPressed: widget.onNextPressed,
        onBackPressed: widget.onBackPressed,
      ),
    );
  }
}