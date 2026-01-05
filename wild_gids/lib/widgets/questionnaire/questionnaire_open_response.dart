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
  late TextEditingController _responseController;
  late final ResponseProvider responseProvider;
  String? _validationError;
  bool _canProceed = true;

  // Slider-related state
  bool _isNumericRange = false;
  int _minValue = 0;
  int _maxValue = 10;
  double _sliderValue = 1;

  @override
  void initState() {
    super.initState();
    responseProvider = context.read<ResponseProvider>();
    _checkIfNumericRange();
    _initializeController();
  }

  @override
  void didUpdateWidget(QuestionnaireOpenResponse oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the question changed, reinitialize the controller
    if (oldWidget.question.id != widget.question.id) {
      _checkIfNumericRange();
      _initializeController();
    }
  }

  void _checkIfNumericRange() {
    final format = widget.question.openResponseFormat;
    debugPrint(
      '[QuestionnaireOpenResponse] Checking numeric range for question: ${widget.question.text}',
    );
    debugPrint('[QuestionnaireOpenResponse] openResponseFormat: "$format"');
    debugPrint(
      '[QuestionnaireOpenResponse] allowOpenResponse: ${widget.question.allowOpenResponse}',
    );
    debugPrint(
      '[QuestionnaireOpenResponse] answers count: ${widget.question.answers?.length ?? 0}',
    );

    if (format == null || format.isEmpty) {
      debugPrint(
        '[QuestionnaireOpenResponse] No format specified, not a numeric range',
      );
      _isNumericRange = false;
      return;
    }

    // Check for numeric range patterns like [1-5], [0-10], etc.
    // Supports: [1-5], [0-10], [1-100], etc.
    final rangePattern = RegExp(r'^\[(\d+)-(\d+)\]$');
    final match = rangePattern.firstMatch(format.trim());

    if (match != null) {
      _isNumericRange = true;
      _minValue = int.parse(match.group(1)!);
      _maxValue = int.parse(match.group(2)!);

      debugPrint(
        '[QuestionnaireOpenResponse] ✅ Detected numeric range: $_minValue to $_maxValue',
      );

      // Ensure min is less than max
      if (_minValue > _maxValue) {
        final temp = _minValue;
        _minValue = _maxValue;
        _maxValue = temp;
      }

      _sliderValue = _minValue.toDouble();
    } else {
      debugPrint(
        '[QuestionnaireOpenResponse] ❌ Format "$format" does not match numeric range pattern',
      );
      _isNumericRange = false;
    }
  }

  void _initializeController() {
    responseProvider.setInteractionID(widget.interactionID);
    responseProvider.setQuestionID(widget.question.id);
    existingResponse = responseProvider.responses.firstWhereOrNull(
      (response) => response.questionID == widget.question.id,
    );

    final existingText = existingResponse?.text ?? '';

    // If numeric range, initialize slider value from existing response
    if (_isNumericRange && existingText.isNotEmpty) {
      final numValue = int.tryParse(existingText);
      if (numValue != null && numValue >= _minValue && numValue <= _maxValue) {
        _sliderValue = numValue.toDouble();
      }
    }

    _responseController = TextEditingController(text: existingText);

    // Validate existing response
    setState(() {
      _validationError = _validateText(existingText);
      _canProceed = _validationError == null || existingText.isEmpty;
    });
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  String? _validateText(String text) {
    final format = widget.question.openResponseFormat;

    // Skip validation for numeric ranges (handled by slider)
    // Sliders can return single digits like "1", "2", etc.
    if (_isNumericRange) {
      return null;
    }

    // Backend validation: minimum 2 characters required for text fields
    // (but only after checking if it's a numeric range)
    if (text.trim().length == 1) {
      return 'Antwoord moet minimaal 2 karakters bevatten';
    }

    // If no format specified, accept any input (including empty)
    if (format == null || format.isEmpty) {
      return null;
    }

    // When a format is specified, require non-empty input
    if (text.trim().isEmpty) {
      return 'Vul een antwoord in';
    }

    // Validate against the regex pattern
    try {
      final regex = RegExp(format);
      if (!regex.hasMatch(text)) {
        // Provide helpful error message with format hint
        String errorMsg = 'Antwoord voldoet niet aan het vereiste formaat';

        // Add helpful hints for common patterns
        if (format.contains(r'\d')) {
          errorMsg += ' (alleen cijfers)';
        } else if (format.contains('[a-zA-Z]')) {
          errorMsg += ' (alleen letters)';
        } else if (format.contains('@')) {
          errorMsg += ' (e-mailadres)';
        }

        return errorMsg;
      }
    } catch (e) {
      // If regex is invalid, log error but don't block user
      debugPrint(
        '[QuestionnaireOpenResponse] Invalid regex pattern: $format - $e',
      );
      return null;
    }

    return null;
  }

  Widget _buildSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.offWhite,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: AppColors.darkGreen, width: 2),
          ),
          child: Column(
            children: [
              Text(
                'Geselecteerde waarde: ${_sliderValue.toInt()}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                  color: AppColors.darkGreen,
                ),
              ),
              const SizedBox(height: 20),
              Slider(
                value: _sliderValue,
                min: _minValue.toDouble(),
                max: _maxValue.toDouble(),
                divisions: _maxValue - _minValue,
                label: _sliderValue.toInt().toString(),
                activeColor: AppColors.darkGreen,
                inactiveColor: AppColors.brown300,
                onChanged: (value) {
                  setState(() {
                    _sliderValue = value;
                    final stringValue = value.toInt().toString();
                    _responseController.text = stringValue;

                    if (existingResponse != null) {
                      responseProvider.setUpdatingResponse(true);
                      responseProvider.updateResponse(
                        existingResponse?.copyWith(text: stringValue),
                      );
                    } else {
                      responseProvider.addResponse(
                        Response(
                          interactionID: widget.interactionID,
                          questionID: widget.question.id,
                          text: stringValue,
                        ),
                      );
                    }
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$_minValue',
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'Roboto',
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    '$_maxValue',
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'Roboto',
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: const Key('questionnaire-description'),
          controller: _responseController,
          onChanged: (value) {
            setState(() {
              _validationError = _validateText(value);
              _canProceed = _validationError == null || value.isEmpty;

              if (existingResponse != null) {
                responseProvider.setUpdatingResponse(true);
                responseProvider.updateResponse(
                  existingResponse?.copyWith(text: value),
                );
              } else {
                responseProvider.addResponse(
                  Response(
                    interactionID: widget.interactionID,
                    questionID: widget.question.id,
                    text: value,
                  ),
                );
              }
            });
          },
          minLines: 1,
          maxLines: null,
          decoration: InputDecoration(
            hintText: 'Schrijf hier uw antwoord...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color:
                    _validationError != null ? Colors.red : AppColors.darkGreen,
                width: 2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color:
                    _validationError != null ? Colors.red : AppColors.darkGreen,
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(
                color: AppColors.darkGreen,
                width: 2,
              ),
            ),
            errorText: _validationError,
          ),
          style: const TextStyle(
            fontSize: 18,
            fontFamily: 'Roboto',
            color: Colors.black,
          ),
        ),
        if (_validationError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Antwoord voldoet niet aan het vereiste formaat',
              style: TextStyle(
                fontSize: 14,
                color: Colors.red[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SharedWhiteBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            vertical: 16.0,
          ), // optional padding
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
                    fontFamily: 'Roboto',
                    color: Colors.black,
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
                    fontFamily: 'Roboto',
                    color: Colors.black,
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
                    style: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'Roboto',
                      color: Colors.black,
                    ),
                  ),
                ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: _isNumericRange ? _buildSlider() : _buildTextField(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomAppBar(
        onNextPressed:
            _canProceed && _responseController.text.isNotEmpty
                ? widget.onNextPressed
                : null,
        onBackPressed: widget.onBackPressed,
        showBackButton: true,
      ),
    );
  }
}
