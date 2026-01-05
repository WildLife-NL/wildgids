import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildrapport/constants/app_colors.dart';
import 'package:wildrapport/constants/app_text_theme.dart';
import 'package:wildrapport/screens/shared/overzicht_screen.dart';
import 'package:wildrapport/utils/responsive_utils.dart';
import 'package:wildrapport/models/api_models/questionaire.dart';

class QuestionnaireHome extends StatelessWidget {
  final VoidCallback nextScreen;
  final int amountOfQuestions;
  final String questionnaireName;
  final String questionnaireDescription;
  final String interactionID;
  final Questionnaire questionnaire;

  const QuestionnaireHome({
    super.key,
    required this.nextScreen,
    required this.amountOfQuestions,
    required this.questionnaireName,
    required this.questionnaireDescription,
    required this.interactionID,
    required this.questionnaire,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Stack(
      children: [
        // Main content
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: responsive.wp(8),
            vertical: responsive.hp(5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Questionnaire name
              Text(
                questionnaireName,
                textAlign: TextAlign.center,
                style: AppTextTheme.textTheme.titleLarge?.copyWith(
                  fontSize: responsive.fontSize(24),
                  color: Colors.black,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: responsive.spacing(16)),
              // Questionnaire description
              Text(
                questionnaireDescription,
                textAlign: TextAlign.center,
                style: AppTextTheme.textTheme.bodyLarge?.copyWith(
                  fontSize: responsive.fontSize(16),
                  color: Colors.black87,
                  fontFamily: 'Roboto',
                ),
              ),
              SizedBox(height: responsive.spacing(24)),
              // Question count
              Column(
                children: [
                  Text(
                    "Totaal aantal vragen",
                    style: TextStyle(
                      color: Colors.black54,
                      fontFamily: 'Roboto',
                      fontSize: responsive.fontSize(14),
                    ),
                  ),
                  Text(
                    "$amountOfQuestions",
                    style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.bold,
                      fontSize: responsive.fontSize(20),
                    ),
                  ),
                ],
              ),
              SizedBox(height: responsive.spacing(32)),
              // Large "Start" button
              SizedBox(
                width: responsive.wp(75),
                height: responsive.hp(8),
                child: ElevatedButton(
                  onPressed: nextScreen,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lightMintGreen100,
                    foregroundColor: Colors.black,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(responsive.sp(1.5)),
                      side: BorderSide(
                        color: AppColors.lightGreen,
                        width: responsive.sp(0.25),
                      ),
                    ),
                  ),
                  child: Text(
                    "Start",
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: responsive.fontSize(20),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: responsive.spacing(16)),
              // "Save for Later" button - smaller and rounded
              SizedBox(
                width: responsive.wp(60),
                height: responsive.hp(6),
                child: ElevatedButton(
                  onPressed: () async {
                    // Save draft locally for later resume
                    await DraftsStore.saveDraft(
                      DraftQuestionnaire(
                        interactionID: interactionID,
                        savedAt: DateTime.now(),
                        questionnaireJson: questionnaire.toJson(),
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vragenlijst opgeslagen voor later')),
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OverzichtScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(responsive.sp(2)),
                      side: BorderSide(
                        color: AppColors.darkGreen,
                        width: responsive.sp(0.2),
                      ),
                    ),
                  ),
                  child: Text(
                    "Voor later opslaan",
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: responsive.fontSize(14),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Small close button in top-right corner
        Positioned(
          top: responsive.hp(2),
          right: responsive.wp(1.2),
          child: IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OverzichtScreen(),
                ),
              );
            },
            icon: Icon(
              Icons.close,
              color: Colors.black38,
              size: responsive.sp(3),
            ),
            tooltip: 'Overslaan',
          ),
        ),
      ],
    );
  }
}

// Local drafts storage
class DraftQuestionnaire {
  final String interactionID;
  final DateTime savedAt;
  final Map<String, dynamic> questionnaireJson;
  DraftQuestionnaire({
    required this.interactionID,
    required this.savedAt,
    required this.questionnaireJson,
  });

  Map<String, dynamic> toJson() => {
        'interactionID': interactionID,
        'savedAt': savedAt.toIso8601String(),
        'questionnaire': questionnaireJson,
      };

  static DraftQuestionnaire fromJson(Map<String, dynamic> json) => DraftQuestionnaire(
        interactionID: json['interactionID'] as String,
        savedAt: DateTime.parse(json['savedAt'] as String),
        questionnaireJson: json['questionnaire'] as Map<String, dynamic>,
      );

  Questionnaire toQuestionnaire() => Questionnaire.fromJson(questionnaireJson);
}

class DraftsStore {
  static const _key = 'questionnaire_drafts';

  static Future<void> saveDraft(DraftQuestionnaire draft) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_key) ?? <String>[];
    // replace any existing draft for same interactionID
    final filtered = existing.where((s) {
      try {
        final m = Map<String, dynamic>.from(jsonDecode(s) as Map);
        return m['interactionID'] != draft.interactionID;
      } catch (_) {
        return true;
      }
    }).toList();
    filtered.add(jsonEncode(draft.toJson()));
    await prefs.setStringList(_key, filtered);
  }

  static Future<List<DraftQuestionnaire>> getDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? <String>[];
    return list.map((s) {
      final m = Map<String, dynamic>.from(jsonDecode(s));
      return DraftQuestionnaire.fromJson(m);
    }).toList();
  }

  static Future<void> removeDraft(String interactionID) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_key) ?? <String>[];
    final filtered = existing.where((s) {
      try {
        final m = Map<String, dynamic>.from(jsonDecode(s) as Map);
        return m['interactionID'] != interactionID;
      } catch (_) {
        return true;
      }
    }).toList();
    await prefs.setStringList(_key, filtered);
  }
}
