import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/constants/app_colors.dart';
import 'package:wildgids/interfaces/state/navigation_state_interface.dart';
import 'package:wildgids/models/enums/nav_tab.dart';
import 'package:wildgids/widgets/shared_ui_widgets/app_bar.dart';
import 'package:wildgids/screens/location/kaart_overview_screen.dart';
import 'package:wildgids/screens/profile/profile_screen.dart';
//import 'package:wildgids/screens/shared/rapporteren.dart';
import 'package:wildgids/screens/shared/my_interaction_history_screen.dart';
import 'package:wildgids/screens/logbook/saved_questionnaires_screen.dart';
import 'package:wildgids/screens/logbook/my_responses_screen.dart';
import 'package:wildgids/screens/logbook/recent_sightings_screen.dart';
import 'package:wildgids/screens/species/species_list_screen.dart';
import 'package:wildgids/widgets/shared_ui_widgets/custom_nav_bar.dart';
import 'package:wildgids/screens/waarneming/waarneming_start_screen.dart';

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

  void _openRecentSightings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RecentSightingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    void onTabSelected(NavTab tab) {
      final navigationManager = context.read<NavigationStateInterface>();
      switch (tab) {
        case NavTab.soorten:
      case NavTab.zones:
        navigationManager.pushReplacementForward(context, const SpeciesListScreen());
        break;
        case NavTab.waarneming:
          navigationManager.pushReplacementForward(context, const WaarnemmingStartScreen());
          break;
        case NavTab.kaart:
          navigationManager.pushReplacementForward(context, const KaartOverviewScreen());
          break;
        case NavTab.logboek:
          return;
        case NavTab.instellingen:
case NavTab.profile:
  navigationManager.pushReplacementForward(context, const ProfileScreen());
  break;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.lightMintGreen,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CustomAppBar(
              leftIcon: null,
              centerText: 'Logboek',
              rightIcon: null,
              showUserIcon: true,
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
                          label: 'Recente waarnemingen',
                          onTap: () => _openRecentSightings(context),
                        ),
                        const SizedBox(height: 12),
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
      bottomNavigationBar: SafeArea(
        top: false,
        child: CustomNavBar(
          currentTab: NavTab.logboek,
          onTabSelected: onTabSelected,
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

