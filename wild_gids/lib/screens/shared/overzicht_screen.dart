import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildrapport/interfaces/state/navigation_state_interface.dart';
import 'package:wildrapport/managers/permission/permission_checker.dart';
import 'package:wildrapport/utils/toast_notification_handler.dart';
import 'package:wildrapport/widgets/overzicht/top_container.dart';
import 'package:wildrapport/widgets/overzicht/action_buttons.dart';
import 'package:wildrapport/screens/shared/rapporteren.dart';
import 'package:wildrapport/providers/app_state_provider.dart';
import 'package:wildrapport/screens/location/kaart_overview_screen.dart';

class OverzichtScreen extends StatefulWidget {
  const OverzichtScreen({super.key});

  @override
  State<OverzichtScreen> createState() => _OverzichtScreenState();
}

class _OverzichtScreenState extends State<OverzichtScreen>
    with PermissionChecker<OverzichtScreen> {
  String userName = "Joe Doe";

  @override
  void initState() {
    super.initState();
    initiatePermissionCheck();
    _loadUserName();
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

    final double topContainerHeight = (screenSize.height * 0.4).clamp(
      180.0,
      300.0,
    );
    final double welcomeFontSize = (screenSize.width * 0.045).clamp(14.0, 24.0);
    final double usernameFontSize = (screenSize.width * 0.06).clamp(18.0, 28.0);
    final double buttonHeight = (screenSize.height * 0.18).clamp(100.0, 160.0);
    final double spacing = (screenSize.height * 0.02).clamp(8.0, 24.0);
    final double iconSize = (screenSize.width * 0.14).clamp(28.0, 56.0);
    final double buttonFontSize = (screenSize.width * 0.045).clamp(14.0, 22.0);

    return WillPopScope(
      onWillPop: () async {
        // Prevent back button from doing anything - user is on home screen
        return false;
      },
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
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
                        child: IntrinsicHeight(
                          child: Column(
                            children: [
                              SizedBox(height: spacing),
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
                                          .pushReplacementForward(
                                            context,
                                            const KaartOverviewScreen(),
                                          );
                                    },
                                  ),

                                  (
                                    text: 'Rapporteren',
                                    icon: Icons.edit_note,
                                    imagePath: null,
                                    key: Key('rapporteren_button'),
                                    onPressed: () {
                                      try {
                                        navigationManager
                                            .pushReplacementForward(
                                              context,
                                              const Rapporteren(),
                                            );
                                      } catch (e) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Er is een fout opgetreden bij het navigeren',
                                            ),
                                            duration: const Duration(
                                              seconds: 3,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  (
                                    text: 'Mijn Rapporten',
                                    icon: Icons.description,
                                    imagePath: null,
                                    key: Key('mijn_rapporten_button'),
                                    onPressed: () {
                                      ToastNotificationHandler.sendToastNotification(
                                        context,
                                        "Deze functie is nog niet toegevoegd",
                                        2,
                                      );
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
                                verticalPadding: spacing / 2,
                                horizontalPadding: spacing,
                                buttonSpacing: spacing / 2,
                                buttonHeight: buttonHeight,
                                buttonFontSize: buttonFontSize,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ), // Close WillPopScope
    );
  }
}
