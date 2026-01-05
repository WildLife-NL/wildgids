import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:wildrapport/models/api_models/question.dart';
import 'package:wildrapport/models/api_models/questionaire.dart';
import 'package:wildrapport/models/beta_models/response_model.dart';
import 'package:wildrapport/providers/response_provider.dart';
import 'package:wildrapport/widgets/shared_ui_widgets/bottom_app_bar.dart';
import 'package:wildrapport/widgets/questionnaire/shared_white_background.dart';
import 'package:wildrapport/utils/responsive_utils.dart';

class QuestionnaireMultipleChoice extends StatefulWidget {
  final Question question;
  final Questionnaire questionnaire;
  final String interactionID;
  final VoidCallback onNextPressed;
  final VoidCallback onBackPressed;
  final int index;

  const QuestionnaireMultipleChoice({
    super.key,
    required this.question,
    required this.questionnaire,
    required this.interactionID,
    required this.onNextPressed,
    required this.onBackPressed,
    required this.index,
  });

  @override
  State<QuestionnaireMultipleChoice> createState() =>
      _QuestionnaireMultipleChoiceState();
}

class _QuestionnaireMultipleChoiceState
    extends State<QuestionnaireMultipleChoice> {
  late final ResponseProvider responseProvider;
  Response? existingResponse;
  String? selectedAnswerID;
  List<String> selectedAnswerIDs = [];
  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, String> _freeTextByAnswer = {};

  bool get _allowFreeText => widget.question.allowOpenResponse;

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

      _hydrateExistingText(existingResponse?.text);
      _initTextControllers();

      setState(() {
        selectedAnswerID = existingResponse?.answerID;
        selectedAnswerIDs = existingResponse?.answerID?.split(',') ?? [];
      });
    });
  }

  void _initTextControllers() {
    if (widget.question.answers == null) return;
    for (final answer in widget.question.answers!) {
      if (_textControllers.containsKey(answer.id)) continue;
      _textControllers[answer.id] = TextEditingController(
        text: _freeTextByAnswer[answer.id] ?? '',
      );
      _textControllers[answer.id]!.addListener(() {
        if (!_allowFreeText) return;
        _freeTextByAnswer[answer.id] = _textControllers[answer.id]!.text;
        _saveResponse();
      });
    }
  }

  void _hydrateExistingText(String? storedText) {
    if (storedText == null || storedText.isEmpty) return;
    try {
      final decoded = jsonDecode(storedText);
      if (decoded is Map) {
        decoded.forEach((key, value) {
          if (value != null) {
            _freeTextByAnswer[key.toString()] = value.toString();
          }
        });
      }
    } catch (_) {
      // If parsing fails, keep existing text empty; backend may have plain text.
    }
  }

  void _onSelectAnswer({required String answerId, required bool selected}) {
    if (widget.question.allowMultipleResponse) {
      if (selected) {
        selectedAnswerIDs.add(answerId);
      } else {
        selectedAnswerIDs.remove(answerId);
        _freeTextByAnswer.remove(answerId);
        _textControllers[answerId]?.clear();
      }
    } else {
      selectedAnswerID = selected ? answerId : null;
      // Clear other selections and texts for single-choice
      selectedAnswerIDs = selected ? [answerId] : [];
      _freeTextByAnswer.keys
          .where((key) => key != answerId)
          .toList()
          .forEach((key) {
        _freeTextByAnswer.remove(key);
        _textControllers[key]?.clear();
      });
    }

    _saveResponse();
  }

  void _saveResponse() {
    final answerIdValue = widget.question.allowMultipleResponse
        ? selectedAnswerIDs.join(',')
        : selectedAnswerID;

    Map<String, String> filteredText = {};
    if (_allowFreeText) {
      final activeIds = widget.question.allowMultipleResponse
          ? selectedAnswerIDs.toSet()
          : {if (selectedAnswerID != null) selectedAnswerID!};
      filteredText = Map.fromEntries(
        _freeTextByAnswer.entries.where((e) => activeIds.contains(e.key)),
      );
    }

    final textPayload = filteredText.isEmpty ? null : jsonEncode(filteredText);

    if (existingResponse != null) {
      responseProvider.setUpdatingResponse(true);
      responseProvider.updateResponse(
        existingResponse!.copyWith(
          answerID: answerIdValue,
          text: textPayload,
        ),
      );
    } else {
      final newResponse = Response(
        answerID: answerIdValue,
        interactionID: widget.interactionID,
        questionID: widget.question.id,
        text: textPayload,
      );
      responseProvider.addResponse(newResponse);
      existingResponse = newResponse;
    }
  }

  @override
  void dispose() {
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return Scaffold(
      body: SharedWhiteBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: responsive.spacing(16),
                left: responsive.spacing(12),
              ),
              child: Text(
                'Vraag ${widget.index + 1} van ${widget.questionnaire.questions?.length}',
                style: TextStyle(
                  fontSize: responsive.fontSize(16),
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(height: responsive.spacing(1)),
            Padding(
              padding: EdgeInsets.only(
                top: responsive.spacing(16),
                left: responsive.spacing(12),
              ),
              child: Text(
                widget.question.text,
                style: TextStyle(
                  fontSize: responsive.fontSize(20),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(height: responsive.spacing(1)),
            if (widget.question.description.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(left: responsive.spacing(12)),
                child: Text(
                  widget.question.description,
                  style: TextStyle(
                    fontSize: responsive.fontSize(18),
                    fontFamily: 'Roboto',
                    color: Colors.black,
                  ),
                ),
              ),
            SizedBox(height: responsive.spacing(24)),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (widget.question.answers != null)
                      ...widget.question.answers!.map((answer) {
                        final isSelected = widget.question.allowMultipleResponse
                            ? selectedAnswerIDs.contains(answer.id)
                            : selectedAnswerID == answer.id;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            widget.question.allowMultipleResponse
                                ? CheckboxListTile(
                                  value: isSelected,
                                  title: Text(
                                    answer.text,
                                    style: TextStyle(
                                      fontSize: responsive.fontSize(18),
                                      fontFamily: 'Roboto',
                                      color: Colors.black,
                                    ),
                                  ),
                                  onChanged: (checked) {
                                    setState(() {
                                      _onSelectAnswer(
                                        answerId: answer.id,
                                        selected: checked ?? false,
                                      );
                                    });
                                  },
                                )
                                : RadioListTile<String>(
                                  title: Text(
                                    answer.text,
                                    style: TextStyle(
                                      fontSize: responsive.fontSize(18),
                                      fontFamily: 'Roboto',
                                      color: Colors.black,
                                    ),
                                  ),
                                  value: answer.id,
                                  groupValue: selectedAnswerID,
                                  onChanged: (String? value) {
                                    setState(() {
                                      _onSelectAnswer(
                                        answerId: answer.id,
                                        selected: value == answer.id,
                                      );
                                    });
                                  },
                                ),
                            if (_allowFreeText && isSelected)
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: responsive.spacing(12),
                                  vertical: responsive.spacing(4),
                                ),
                                child: TextField(
                                  controller: _textControllers[answer.id],
                                  decoration: const InputDecoration(
                                    labelText: 'Toelichting',
                                    border: OutlineInputBorder(),
                                  ),
                                  maxLines: null,
                                ),
                              ),
                          ],
                        );
                      }),
                  ],
                ),
              ),
            ),
            CustomBottomAppBar(
              onNextPressed: widget.onNextPressed,
              onBackPressed: widget.onBackPressed,
              showBackButton: true,
            ),
          ],
        ),
      ),
    );
  }
}
