import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/constants/app_colors.dart';
import 'package:wildgids/interfaces/state/navigation_state_interface.dart';
import 'package:wildgids/models/enums/nav_tab.dart';
import 'package:wildgids/screens/game/challenge_screen.dart';
import 'package:wildgids/screens/location/kaart_overview_screen.dart';
import 'package:wildgids/screens/profile/profile_screen.dart';
import 'package:wildgids/screens/shared/my_interaction_history_screen.dart';
import 'package:wildgids/screens/logbook/saved_questionnaires_screen.dart';
import 'package:wildgids/screens/logbook/my_responses_screen.dart';
import 'package:wildgids/screens/logbook/my_contacts_screen.dart';
import 'package:wildgids/screens/logbook/recent_sightings_screen.dart';
import 'package:wildgids/widgets/shared_ui_widgets/app_bar.dart';
import 'package:wildgids/widgets/shared_ui_widgets/custom_nav_bar.dart';
import 'package:wildgids/screens/waarneming/waarneming_start_screen.dart';

class LogbookScreen extends StatefulWidget {
  const LogbookScreen({
    super.key,
    this.onBackPressed,
    this.openRecentSightings = false,
    this.showBottomNav = true,
  });

  final VoidCallback? onBackPressed;
  final bool openRecentSightings;
  final bool showBottomNav;

  @override
  State<LogbookScreen> createState() => _LogbookScreenState();
}

class _LogbookScreenState extends State<LogbookScreen> {
  bool _hasNavigated = false;

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

  void _openContactMoments(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MyContactsScreen()),
    );
  }

  void _onTabSelected(NavTab tab) {
    final navigationManager = context.read<NavigationStateInterface>();
    switch (tab) {
      case NavTab.ontdekken:
      case NavTab.zones:
        navigationManager.pushReplacementForward(context, const ChallengeScreen());
        break;
      case NavTab.waarneming:
        navigationManager.pushReplacementForward(
          context,
          const WaarnemmingStartScreen(),
        );
        break;
      case NavTab.kaart:
        navigationManager.pushReplacementForward(
          context,
          const KaartOverviewScreen(),
        );
        break;
      case NavTab.logboek:
        return;
      case NavTab.instellingen:
      case NavTab.profile:
        navigationManager.pushReplacementForward(context, const ProfileScreen());
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.openRecentSightings && !_hasNavigated) {
      _hasNavigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const RecentSightingsScreen()),
          );
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CustomAppBar(
              centerText: 'Logboek',
              rightIcon: null,
              showUserIcon: false,
              onLeftIconPressed: () {
                if (widget.onBackPressed != null) {
                  widget.onBackPressed!();
                  return;
                }
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
              iconColor: AppColors.textPrimary,
              textColor: AppColors.textPrimary,
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
                          label: 'Recente meldingen',
                          subtitle:
                              'Waarnemingen, schademeldingen en dieraanrijdingen',
                          icon: Icons.visibility_outlined,
                          onTap: () => _openRecentSightings(context),
                        ),
                        const SizedBox(height: 12),
                        _ReportButton(
                          label: 'Contactmomenten',
                          subtitle:
                              'Bluetooth-contacten met collars (Smart Parks)',
                          icon: Icons.bluetooth_connected,
                          onTap: () => _openContactMoments(context),
                        ),
                        const SizedBox(height: 12),
                        _ReportButton(
                          label: 'Mijn interacties',
                          subtitle:
                              'Bekijk al je schademeldingen en waarnemingen',
                          icon: Icons.history_toggle_off,
                          onTap: () => _openAllInteractions(context),
                        ),
                        const SizedBox(height: 12),
                        _ReportButton(
                          label: 'Mijn antwoorden',
                          subtitle: 'Ingevulde vragenlijsten en formulieren',
                          icon: Icons.assignment_turned_in_outlined,
                          onTap: () => _openMyResponses(context),
                        ),
                        const SizedBox(height: 12),
                        _ReportButton(
                          label: 'Vragenlijsten opgeslagen voor later',
                          subtitle:
                              'Ga verder met half ingevulde vragenlijsten',
                          icon: Icons.bookmark_border,
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
      bottomNavigationBar: widget.showBottomNav
          ? SafeArea(
              top: false,
              child: CustomNavBar(
                currentTab: NavTab.logboek,
                onTabSelected: _onTabSelected,
              ),
            )
          : null,
    );
  }
}

class _ReportButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final String? subtitle;
  final IconData icon;

  const _ReportButton({
    required this.label,
    required this.onTap,
    this.subtitle,
    this.icon = Icons.description_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shadowColor: Colors.transparent,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: AppColors.primaryGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
