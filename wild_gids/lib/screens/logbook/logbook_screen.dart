import 'package:flutter/material.dart';
import 'package:wildrapport/constants/app_colors.dart';
import 'package:wildrapport/widgets/shared_ui_widgets/app_bar.dart';
import 'package:wildrapport/screens/shared/overzicht_screen.dart';
import 'package:wildrapport/screens/shared/my_interaction_history_screen.dart';
import 'package:wildrapport/screens/logbook/saved_questionnaires_screen.dart';
import 'package:wildrapport/screens/logbook/my_responses_screen.dart';

class LogbookScreen extends StatelessWidget {
  const LogbookScreen({super.key});

  void _openAllInteractions(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MyInteractionHistoryScreen()),
    );
  }

  void _openMyResponses(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MyResponsesScreen()),
    );
  }

  void _openSavedQuestionnaires(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SavedQuestionnairesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightMintGreen,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CustomAppBar(
              leftIcon: Icons.arrow_back_ios,
              centerText: 'Logboek',
              rightIcon: null,
              showUserIcon: true,
              onLeftIconPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const OverzichtScreen()),
                );
              },
              iconColor: Colors.black,
              textColor: Colors.black,
              fontScale: 1.15,
              iconScale: 1.15,
              userIconScale: 1.15,
              useFixedText: true,
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        
                        _ReportButton(
                          label: 'Mijn interacties',
                          onTap: () => _openAllInteractions(context),
                        ),
                        const SizedBox(height: 12),
                        _ReportButton(
                          label: 'Mijn antwoorden',
                          onTap: () => _openMyResponses(context),
                        ),
                        const SizedBox(height: 12),
                        _ReportButton(
                          label: 'Vragenlijsten opgeslagen voor later',
                          onTap: () => _openSavedQuestionnaires(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ReportButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkGreen,
          foregroundColor: Colors.white,
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
