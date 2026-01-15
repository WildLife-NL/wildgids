import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildgids/interfaces/state/navigation_state_interface.dart';
import 'package:wildgids/constants/app_colors.dart';
import 'package:wildgids/widgets/overzicht/top_container.dart';
import 'package:wildgids/widgets/overzicht/action_buttons.dart';
import 'package:wildgids/screens/shared/rapporteren.dart';
import 'package:wildgids/screens/logbook/logbook_screen.dart';
import 'package:wildgids/providers/app_state_provider.dart';
import 'package:wildgids/screens/location/kaart_overview_screen.dart';
import 'package:wildgids/screens/game/animals_quiz_screen.dart';
import 'package:wildgids/screens/species/species_list_screen.dart';

class OverzichtScreen extends StatefulWidget {
  const OverzichtScreen({super.key});

  @override
  State<OverzichtScreen> createState() => _OverzichtScreenState();
}

class _OverzichtScreenState extends State<OverzichtScreen> {
  String userName = "Joe Doe";
  String reportButtonLabel = 'Rapporteren';

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadReportButtonLabel();
  }

  Future<void> _loadReportButtonLabel() async {
    try {
      final typesManager = Provider.of(context, listen: false) as dynamic;
      // Try to call ensureFetched() if it exists
      try {
        final types = await typesManager.ensureFetched();
        // prefer the manager helper if available
        String? name;
        try {
          name = typesManager.nameForTypeId(1);
        } catch (_) {}
        name ??= (types.isNotEmpty ? types.first.name : null);
        if (name != null && name.isNotEmpty) {
          setState(() {
            reportButtonLabel = name!;
          });
        }
      } catch (_) {
        // ignore fetch failures and keep default
      }
    } catch (_) {
      // Provider not available or unexpected type - keep default label
    }
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString("userName") ?? "Joe Doe";
    });
  }

  @override
  Widget build(BuildContext context) {
    final navigationManager = context.read<NavigationStateInterface>();
    final screenSize = MediaQuery.of(context).size;

    final double topContainerHeight = (screenSize.height * 0.36).clamp(
      170.0,
      280.0,
    );
    final double welcomeFontSize = (screenSize.width * 0.045).clamp(14.0, 24.0);
    final double usernameFontSize = (screenSize.width * 0.06).clamp(18.0, 28.0);
    final double buttonHeight = (screenSize.height * 0.07).clamp(44.0, 56.0);
    final double spacing = (screenSize.height * 0.018).clamp(6.0, 18.0);
    final double iconSize = (screenSize.width * 0.14).clamp(28.0, 56.0);
    final double buttonFontSize = (screenSize.width * 0.045).clamp(14.0, 22.0);

    return WillPopScope(
      onWillPop: () async {
        // Prevent back button from doing anything - user is on home screen
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.lightMintGreen,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final double estimatedContentHeight =
                (screenSize.height * 0.4).clamp(180.0, 300.0) + // TopContainer
                (screenSize.height * 0.02).clamp(8.0, 24.0) * 3.8 + // SizedBox
                (screenSize.height * 0.08).clamp(
                  48.0,
                  64.0,
                ) + // ActionButtons (approx)
                (screenSize.height * 0.02).clamp(8.0, 24.0) * 1.5 + // SizedBox
                48.0; // Padding and other elements

            final bool shouldScroll =
                estimatedContentHeight > constraints.maxHeight;

            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TopContainer(
                  userName: userName,
                  height: topContainerHeight,
                  welcomeFontSize: welcomeFontSize,
                  usernameFontSize: usernameFontSize,
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: spacing / 2,
                      horizontal: spacing,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Move buttons higher by reducing top spacer
                        SizedBox(height: spacing * 2.0),
                        ActionButtons(
                          buttons: [
                            (
                              text: 'Kaart',
                              icon: Icons.map,
                              imagePath: null,
                              key: Key('rapporten_kaart_button'),
                              onPressed: () {
                                context
                                    .read<NavigationStateInterface>()
                                    .pushForward(
                                      context,
                                      const KaartOverviewScreen(),
                                    );
                              },
                            ),
                            (
                              text: 'Dierenquiz',
                              icon: Icons.quiz,
                              imagePath: null,
                              key: Key('dierenquiz_button'),
                              onPressed: () {
                                context
                                    .read<NavigationStateInterface>()
                                    .pushForward(
                                      context,
                                      const AnimalsQuizScreen(),
                                    );
                              },
                            ),
                            (
                              text: 'Diersoorten',
                              icon: Icons.pets,
                              imagePath: null,
                              key: Key('diersoorten_button'),
                              onPressed: () {
                                context
                                    .read<NavigationStateInterface>()
                                    .pushReplacementForward(
                                      context,
                                      const SpeciesListScreen(),
                                    );
                              },
                            ),
                            (
                              text: reportButtonLabel,
                              icon: Icons.edit_note,
                              imagePath: null,
                              key: Key('rapporteren_button'),
                              onPressed: () {
                                try {
                                  navigationManager.pushForward(
                                    context,
                                    const Rapporteren(),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Er is een fout opgetreden bij het navigeren',
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                            (
                              text: 'Logboek',
                              icon: Icons.description,
                              imagePath: null,
                              key: Key('logboek_button'),
                              onPressed: () {
                                try {
                                  navigationManager.pushForward(
                                    context,
                                    const LogbookScreen(),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Er is een fout opgetreden bij het navigeren',
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                            (
                              text: 'Uitloggen',
                              icon: Icons.logout,
                              imagePath: null,
                              key: Key('uitloggen_button'),
                              onPressed: () {
                                context.read<AppStateProvider>().logout();
                              },
                            ),
                          ],
                          iconSize: iconSize,
                          verticalPadding: spacing / 3,
                          horizontalPadding: spacing * 0.8,
                          // slightly more spacing between buttons
                          buttonSpacing: spacing * 2,
                          buttonHeight: buttonHeight,
                          buttonFontSize: buttonFontSize,
                        ),
                        SizedBox(height: spacing),
                      ],
                    ),
                  ),
                ),
              ],
            );

            return SingleChildScrollView(
              physics:
                  shouldScroll
                      ? const AlwaysScrollableScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: content,
              ),
            );
          },
        ),
      ),
    );
  }
}

