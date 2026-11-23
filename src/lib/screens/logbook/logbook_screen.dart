import 'package:flutter/material.dart';
import 'package:wildgids/widgets/guide/animal_artwork.dart';
import 'package:wildgids/utils/species_image_resolver.dart';
import 'package:wildgids/screens/logbook/wildlife_diary_screen.dart';
import 'package:wildgids/widgets/guide/guide_style.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/interfaces/state/navigation_state_interface.dart';
import 'package:wildgids/models/enums/nav_tab.dart';
import 'package:wildgids/screens/game/challenge_screen.dart';
import 'package:wildgids/screens/location/kaart_overview_screen.dart';
import 'package:wildgids/screens/profile/profile_screen.dart';
import 'package:wildgids/screens/logbook/saved_questionnaires_screen.dart';
import 'package:wildgids/screens/logbook/my_responses_screen.dart';
import 'package:wildgids/screens/logbook/my_contacts_screen.dart';
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => WildlifeDiaryScreen(
              showReportFilters: true,
              onTabSelected: (tab) {
                Navigator.of(context).pop();
                if (tab != NavTab.logboek) {
                  _onTabSelected(tab);
                }
              },
            ),
      ),
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
        navigationManager.pushReplacementForward(
          context,
          const ChallengeScreen(),
        );
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
        navigationManager.pushReplacementForward(
          context,
          const ProfileScreen(),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.openRecentSightings && !_hasNavigated) {
      _hasNavigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _openRecentSightings(context);
        }
      });
    }

    return Scaffold(
      backgroundColor: ChallengeScreen.pageBackground,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const GuideBrand(),
                  const SizedBox(height: 28),
                  const Text(
                    'Logboek',
                    style: TextStyle(
                      fontSize: 36,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      color: ChallengeScreen.deepGreen,
                    ),
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final largeText =
                          constraints.maxWidth < 340 &&
                          MediaQuery.textScalerOf(context).scale(1) > 1.3;
                      final tileWidth =
                          largeText
                              ? constraints.maxWidth
                              : (constraints.maxWidth - 14) / 2;
                      return Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: [
                          _LogbookTile(
                            width: tileWidth,
                            label: 'Recente meldingen',
                            icon: Icons.auto_stories_outlined,
                            animalImage: true,
                            onTap: () => _openRecentSightings(context),
                          ),
                          _LogbookTile(
                            width: tileWidth,
                            label: 'Contacten',
                            icon: Icons.bluetooth_connected,
                            onTap: () => _openContactMoments(context),
                          ),
                          _LogbookTile(
                            width: tileWidth,
                            label: 'Mijn antwoorden',
                            icon: Icons.assignment_turned_in_outlined,
                            onTap: () => _openMyResponses(context),
                          ),
                          _LogbookTile(
                            width: tileWidth,
                            label: 'Opgeslagen',
                            icon: Icons.bookmark_border,
                            onTap: () => _openSavedQuestionnaires(context),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar:
          widget.showBottomNav
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

class _LogbookTile extends StatelessWidget {
  const _LogbookTile({
    required this.width,
    required this.label,
    required this.icon,
    required this.onTap,
    this.animalImage = false,
  });
  final double width;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool animalImage;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Material(
      color: animalImage ? GuideStyle.background : const Color(0xFFF0F5E9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFD8E3CE)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 110,
                width: double.infinity,
                child:
                    animalImage
                        ? AnimalArtwork(
                          imagePath: SpeciesImageResolver.drawingForCommonName(
                            'damhert',
                          ),
                        )
                        : Center(
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE1EDD7),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: GuideStyle.ink, size: 38),
                          ),
                        ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: 43 * MediaQuery.textScalerOf(context).scale(1),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: GuideStyle.ink,
                    fontSize: 17,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
