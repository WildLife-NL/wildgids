import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wildrapport/constants/app_colors.dart';
import 'package:wildrapport/widgets/shared_ui_widgets/app_bar.dart';
import 'package:wildrapport/widgets/questionnaire/questionnaire_home.dart';
import 'package:wildrapport/screens/questionnaire/questionnaire_screen.dart';

class SavedQuestionnairesScreen extends StatelessWidget {
  const SavedQuestionnairesScreen({super.key});

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
              centerText: 'Vragenlijsten opgeslagen voor later',
              rightIcon: null,
              showUserIcon: true,
              onLeftIconPressed: () => Navigator.of(context).pop(),
              iconColor: Colors.black,
              textColor: Colors.black,
              fontScale: 1.15,
              iconScale: 1.15,
              userIconScale: 1.15,
              useFixedText: true,
            ),
            Expanded(
              child: FutureBuilder(
                future: DraftsStore.getDrafts(),
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final drafts = (snap.data ?? const <DraftQuestionnaire>[]) as List<DraftQuestionnaire>;
                  if (drafts.isEmpty) {
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.black45),
                            SizedBox(height: 12),
                            Text(
                              'Nog geen opgeslagen vragenlijsten',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: drafts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final d = drafts[i];
                      final q = d.toQuestionnaire();
                      final saved = DateFormat('dd-MM-yyyy HH:mm').format(d.savedAt.toLocal());
                      return Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          title: Text(q.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('Opgeslagen: $saved'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  await DraftsStore.removeDraft(d.interactionID);
                                  // refresh by replacing route
                                  if (!context.mounted) return;
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => const SavedQuestionnairesScreen(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 6),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => QuestionnaireScreen(
                                        questionnaire: q,
                                        interactionID: d.interactionID,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.darkGreen,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Hervat'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
